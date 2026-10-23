"""Takes of the game's music from Eleven Music, to choose them by ear, and the loop cut from the one chosen.

    python tools/music/music_takes.py --all --dry-run        # what it would ask for, and what it costs
    python tools/music/music_takes.py main show campaign     # a batch of takes of each, in music_auditions/<track>/
    python tools/music/music_takes.py main --save 2 --dry-run  # where take 2's loop would be cut, writing nothing
    python tools/music/music_takes.py main --save 2          # take 2, cut to a loop, becomes the game's main theme

What each track asks for (its style, length, tempo and how many takes) is in tracks.json beside this
script. A take is longer than its loop: saving one finds the tempo, then the stretch of whole bars whose
end flows back into its start best, by measuring the take itself, and writes that stretch alone as an Ogg
Vorbis file that loops from its first sample to its last, with a short crossfade baked in at the seam.
Beside the take it leaves a preview of the seam (the loop's end running into its start) to listen to.
Takes are scratch audio, kept out of git; a new batch is numbered on from the last. The key comes from
the ELEVENLABS_API_KEY environment variable or .env at the project root, and is never printed. Needs
ffmpeg on the path.
"""

import argparse
import array
import json
import math
import pathlib
import re
import subprocess
import sys
import urllib.error
import urllib.request

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1] / "voice"))
from elevenlabs import API, ROOT, TIMEOUT_SECONDS, ApiError, api_key  # noqa: E402

TRACKS = pathlib.Path(__file__).with_name("tracks.json")
AUDITIONS = ROOT / "music_auditions"
MODEL = "music_v2_5"
# Tried in order: the best a plan allows. Creator plans may not download the higher quality.
FORMATS = ["mp3_48000_192", "mp3_44100_128"]
# What music costs on the shared credit pool, by ElevenLabs' pricing page.
CREDITS_PER_MINUTE = 900

# Loop finding. The take is measured at a low rate first, then the seam is matched at full rate.
ANALYSIS_RATE = 11025
FRAME = 256
# The loop starts after this many seconds of the take, clear of any intro.
INTRO_SECONDS = 3.0
# And ends this many seconds before the take does, clear of any ending.
OUTRO_SECONDS = 4.0
# Loops are a whole number of these many bars of four beats.
BAR_STEP = 4
# A loop at least this many bars long.
LEAST_BARS = 8
# How far either side of where the bars say the end falls, in beats, the end is searched for.
END_SLACK_BEATS = 0.5
# Bars of music compared either side of the seam.
COMPARE_BARS = 2
# A seam this good (of 1.5) or better is good enough: the longest loop with one wins.
GOOD_SEAM = 1.1
# With no seam that good, the longest loop within this of the best seam wins.
LONGER_IF_WITHIN = 0.06
# Seconds of the crossfade baked in at the seam.
CROSSFADE_SECONDS = 0.06
# Vorbis quality, 0 to 10.
OGG_QUALITY = 6
# Seconds either side of the seam in its preview.
PREVIEW_SECONDS = 8.0
# Every loop is brought to this loudness, in LUFS, so the game's music level suits every track; the
# placeholder the music replaced sat here.
TARGET_LUFS = -16.0
# No loop is made so loud that it peaks over this, in decibels.
PEAK_CEILING_DB = -1.0


def generate(track: dict, key: str) -> tuple[bytes, dict, str]:
    body = {"prompt": track["prompt"], "music_length_ms": int(track["seconds"] * 1000), "model_id": MODEL,
            "force_instrumental": True}
    last_error: ApiError | None = None
    for output_format in FORMATS:
        req = urllib.request.Request(
            f"{API}/music?output_format={output_format}",
            data=json.dumps(body).encode("utf-8"),
            method="POST",
            headers={"xi-api-key": key, "Content-Type": "application/json", "Accept": "audio/mpeg"},
        )
        try:
            with urllib.request.urlopen(req, timeout=TIMEOUT_SECONDS) as response:
                return response.read(), dict(response.headers), output_format
        except urllib.error.HTTPError as error:
            last_error = ApiError(error.code, error.read().decode("utf-8", "replace"))
            if error.code >= 500:
                raise last_error from None
            print(f"    {output_format} refused ({error.code}), trying the next format", flush=True)
    raise last_error


def take_path(name: str, number: int) -> pathlib.Path:
    return AUDITIONS / name / f"{name}_{number}.mp3"


# Measuring --------------------------------------------------------------------------------------------

def decode(path: pathlib.Path, rate: int, channels: int) -> array.array:
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", str(path), "-ac", str(channels), "-ar", str(rate),
                          "-f", "s16le", "-"], capture_output=True, check=True).stdout
    samples = array.array("h")
    samples.frombytes(raw)
    return samples


def native_rate(path: pathlib.Path) -> int:
    out = subprocess.run(["ffprobe", "-v", "error", "-select_streams", "a:0", "-show_entries", "stream=sample_rate",
                          "-of", "default=nw=1:nk=1", str(path)], capture_output=True, check=True, text=True).stdout
    return int(out.strip())


def onsets(mono: array.array) -> list[float]:
    """How sharply the loudness rises in each frame: where notes and hits start."""
    energies = []
    for start in range(0, len(mono) - FRAME, FRAME):
        chunk = mono[start:start + FRAME]
        energies.append(math.log(1e-6 + sum(v * v for v in chunk) / FRAME))
    return [0.0] + [max(0.0, energies[i] - energies[i - 1]) for i in range(1, len(energies))]


def at(values: list[float], position: float) -> float:
    low = int(position)
    if low + 1 >= len(values):
        return values[-1]
    weight = position - low
    return values[low] * (1.0 - weight) + values[low + 1] * weight


def beat_frames(onset: list[float], bpm_hint: float) -> float:
    """The beat's length in frames: the tempo near the one asked for that the onsets repeat at best."""
    frames_per_second = ANALYSIS_RATE / FRAME
    best = (-1.0, 0.0)
    bpm = bpm_hint * 0.85
    while bpm <= bpm_hint * 1.15:
        lag = 60.0 * frames_per_second / bpm
        score = sum(onset[i] * at(onset, i + lag) for i in range(len(onset) - int(lag) - 2))
        best = max(best, (score, lag))
        bpm += 0.1
    return best[1]


def beat_phase(onset: list[float], beat: float) -> float:
    """Where in the beat the hits fall, in frames."""
    best = (-1.0, 0.0)
    steps = int(beat * 4)
    for step in range(steps):
        phase = step * beat / steps
        score = sum(at(onset, phase + k * beat) for k in range(int((len(onset) - phase) / beat) - 1))
        best = max(best, (score, phase))
    return best[1]


def correlation(a: list[float], b: list[float]) -> float:
    n = min(len(a), len(b))
    if n < 2:
        return 0.0
    mean_a = sum(a[:n]) / n
    mean_b = sum(b[:n]) / n
    top = sum((a[i] - mean_a) * (b[i] - mean_b) for i in range(n))
    spread = math.sqrt(sum((a[i] - mean_a) ** 2 for i in range(n)) * sum((b[i] - mean_b) ** 2 for i in range(n)))
    return top / spread if spread > 0.0 else 0.0


def envelope(mono: array.array) -> list[float]:
    """Loudness per frame, for comparing stretches of the take."""
    return [math.sqrt(sum(v * v for v in mono[s:s + FRAME]) / FRAME) for s in range(0, len(mono) - FRAME, FRAME)]


def best_lag(a: array.array, a_start: int, b: array.array, b_start: int, length: int, reach: int) -> int:
    """The shift of b, within reach either way, that lines its waveform up best with a's."""
    best = (-math.inf, 0)
    window = a[a_start:a_start + length]
    for lag in range(-reach, reach + 1):
        start = b_start + lag
        if start < 0 or start + length > len(b):
            continue
        other = b[start:start + length]
        best = max(best, (sum(x * y for x, y in zip(window, other)), lag))
    return best[1]


def find_loop(path: pathlib.Path, bpm_hint: float, least_seconds: float, force_bars: int = 0) -> dict:
    """Where to cut the loop: its start and end in seconds, and how well its end runs into its start.
    The longest loop at least [param least_seconds] long with a good seam, or one [param force_bars]
    long."""
    mono = decode(path, ANALYSIS_RATE, 1)
    onset = onsets(mono)
    loud = envelope(mono)
    frames_per_second = ANALYSIS_RATE / FRAME
    beat = beat_frames(onset, bpm_hint)
    phase = beat_phase(onset, beat)
    bar = beat * 4
    first = INTRO_SECONDS * frames_per_second
    last = len(onset) - OUTRO_SECONDS * frames_per_second
    window = int(COMPARE_BARS * bar)
    slack = int(END_SLACK_BEATS * beat)
    starts = []
    position = phase
    while position < first + 2 * bar:
        if position >= first:
            starts.append(position)
        position += beat
    candidates = []
    for start in starts:
        bars = int((last - window - start) / bar) // BAR_STEP * BAR_STEP
        while bars >= LEAST_BARS:
            planned = start + bars * bar
            best = (-2.0, planned)
            for shift in range(-slack, slack + 1):
                end = planned + shift
                if end + window >= len(loud) or start - window < 0:
                    continue
                s, e = int(start), int(end)
                after = correlation(loud[s:s + window], loud[e:e + window])
                before = correlation(loud[s - window:s], loud[e - window:e])
                best = max(best, (after + 0.5 * before, end))
            candidates.append((best[0], bars, start, best[1]))
            bars -= BAR_STEP
    if not candidates:
        sys.exit("The take is too short for a loop of the least bars.")
    lengths = {}
    for each in candidates:
        lengths[each[1]] = max(lengths.get(each[1], -2.0), each[0])
    if force_bars:
        candidates = [c for c in candidates if c[1] == force_bars]
        if not candidates:
            sys.exit(f"No loop of {force_bars} bars fits the take.")
    else:
        long_enough = [c for c in candidates if (c[3] - c[2]) / frames_per_second >= least_seconds]
        candidates = long_enough or candidates
    top = max(candidates)[0]
    good = [c for c in candidates if c[0] >= min(GOOD_SEAM, top - LONGER_IF_WITHIN)]
    score, bars, start, end = max(good, key=lambda c: (c[1], c[0]))
    # Line the end up with the start, sample by sample, at the low rate.
    start_sample = int(start * FRAME)
    end_sample = int(end * FRAME)
    length = ANALYSIS_RATE // 3
    end_sample += best_lag(mono, start_sample, mono, end_sample, length, FRAME)
    return {"start": start_sample / ANALYSIS_RATE, "end": end_sample / ANALYSIS_RATE, "bars": bars,
            "bpm": 60.0 * frames_per_second / beat, "score": score, "lengths": lengths}


def write_loop(path: pathlib.Path, cut: dict, target: pathlib.Path | None, preview: pathlib.Path) -> None:
    """Writes the loop at full rate: the stretch from the start to the end, its last moments crossfaded
    into what led up to the start, so its end runs into its own beginning. With no target, only the
    preview of its seam."""
    rate = native_rate(path)
    stereo = decode(path, rate, 2)
    start = int(cut["start"] * rate)
    end = int(cut["end"] * rate)
    # Fine tune the end to the sample, on the mix of both channels.
    mono = array.array("h", [(stereo[i] + stereo[i + 1]) // 2 for i in range(0, len(stereo) - 1, 2)])
    end += best_lag(mono, start, mono, end, 2048, int(rate / ANALYSIS_RATE) * 2)
    fade = int(CROSSFADE_SECONDS * rate)
    loop = stereo[start * 2:end * 2]
    for i in range(fade):
        weight = (i + 0.5) / fade
        keep = math.cos(weight * math.pi / 2.0)
        lead = math.sin(weight * math.pi / 2.0)
        for channel in range(2):
            index = (end - start - fade + i) * 2 + channel
            before_start = (start - fade + i) * 2 + channel
            mixed = loop[index] * keep + stereo[before_start] * lead
            loop[index] = max(-32768, min(32767, int(round(mixed))))
    level = leveling(loop, rate)
    if target is not None:
        target.parent.mkdir(parents=True, exist_ok=True)
        encode(loop, rate, target, ["-af", f"volume={level:.2f}dB", "-c:a", "libvorbis", "-q:a", str(OGG_QUALITY)])
    seam = int(PREVIEW_SECONDS * rate) * 2
    encode(loop[-seam:] + loop[:seam], rate, preview, ["-af", f"volume={level:.2f}dB", "-c:a", "libmp3lame", "-q:a", "2"])


def leveling(samples: array.array, rate: int) -> float:
    """The gain, in decibels, that brings [samples] to TARGET_LUFS without peaking over PEAK_CEILING_DB."""
    report = subprocess.run(["ffmpeg", "-hide_banner", "-nostats", "-f", "s16le", "-ar", str(rate), "-ac", "2", "-i", "-",
                             "-af", "ebur128=peak=sample,volumedetect", "-f", "null", "-"],
                            input=samples.tobytes(), capture_output=True, check=True).stderr.decode("utf-8", "replace")
    loudness = float(re.findall(r"I:\s+(-?[\d.]+) LUFS", report)[-1])
    peak = float(re.findall(r"max_volume: (-?[\d.]+) dB", report)[-1])
    return min(TARGET_LUFS - loudness, PEAK_CEILING_DB - peak)


def encode(samples: array.array, rate: int, target: pathlib.Path, codec: list[str]) -> None:
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "s16le", "-ar", str(rate), "-ac", "2", "-i", "-",
                    *codec, str(target)], input=samples.tobytes(), check=True)


# Main ----------------------------------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("tracks", nargs="*", help="the tracks' names in tracks.json")
    parser.add_argument("--all", action="store_true", help="every track in tracks.json")
    parser.add_argument("--save", type=int, metavar="TAKE", help="cut this take to a loop and make it the game's")
    parser.add_argument("--preview", action="store_true", help="with --save: write only the seam's preview")
    parser.add_argument("--bars", type=int, default=0, help="with --save: a loop this many bars long")
    parser.add_argument("--dry-run", action="store_true", help="show what would be asked for, or cut, and stop")
    args = parser.parse_args()

    tracks = {name: track for name, track in json.loads(TRACKS.read_text(encoding="utf-8")).items()
              if isinstance(track, dict)}
    names = list(tracks) if args.all else args.tracks
    if not names:
        sys.exit(f"Name a track, or --all. There are: {', '.join(sorted(tracks))}")
    for name in names:
        if name not in tracks:
            sys.exit(f"No track called {name} in {TRACKS.name}. There are: {', '.join(sorted(tracks))}")

    if args.save is not None:
        if len(names) != 1:
            sys.exit("Save one track at a time.")
        name = names[0]
        take = take_path(name, args.save)
        if not take.exists():
            sys.exit(f"No take {take.relative_to(ROOT).as_posix()}")
        cut = find_loop(take, float(tracks[name]["bpm"]), float(tracks[name]["least"]), args.bars)
        print(f"{take.relative_to(ROOT).as_posix()}: about {cut['bpm']:.1f} bpm, a loop of {cut['bars']} bars "
              f"from {cut['start']:.2f} s to {cut['end']:.2f} s ({cut['end'] - cut['start']:.1f} s), "
              f"seam match {cut['score']:.2f} of 1.5")
        print("  other lengths: " + ", ".join(f"{bars} bars {score:.2f}" for bars, score in sorted(cut["lengths"].items())))
        if args.dry_run:
            return
        preview = take.with_name(f"{take.stem}_seam.mp3")
        target = None if args.preview else ROOT / tracks[name]["file"]
        write_loop(take, cut, target, preview)
        if target is not None:
            print(f"  the loop is now {tracks[name]['file']}")
        print(f"  hear its seam in {preview.relative_to(ROOT).as_posix()}")
        if target is not None:
            print("Import the project (or click into the editor) so the game can load it.")
        return

    seconds = 0.0
    for name in names:
        track = tracks[name]
        seconds += track["seconds"] * track["takes"]
        print(f"{name}: {track['takes']} takes of {track['seconds']} s at about {track['bpm']} bpm, {MODEL}")
        print(f"  {track['prompt']}")
    takes = sum(tracks[name]["takes"] for name in names)
    print(f"{takes} takes, {seconds / 60.0:g} minutes of music: {round(seconds / 60.0 * CREDITS_PER_MINUTE):,} credits")
    if args.dry_run:
        return
    key = api_key()
    AUDITIONS.mkdir(parents=True, exist_ok=True)
    # Takes are scratch audio: Godot leaves the folder alone, so it never imports them or ships them.
    (AUDITIONS / ".gdignore").touch()
    for name in names:
        track = tracks[name]
        folder = AUDITIONS / name
        folder.mkdir(parents=True, exist_ok=True)
        first = 1 + len([p for p in folder.glob(f"{name}_*.mp3") if not p.stem.endswith("_seam")])
        for number in range(first, first + track["takes"]):
            path = take_path(name, number)
            audio, headers, output_format = generate(track, key)
            path.write_bytes(audio)
            path.with_suffix(".json").write_bytes((json.dumps(
                {"prompt": track["prompt"], "seconds": track["seconds"], "model": MODEL, "format": output_format,
                 "headers": {k: v for k, v in headers.items() if k.lower().startswith(("song", "x-", "content"))}},
                indent=2) + "\n").encode("utf-8"))
            print(f"  {path.relative_to(ROOT).as_posix()} ({output_format})", flush=True)


if __name__ == "__main__":
    main()
