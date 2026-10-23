"""Takes of sound effects from ElevenLabs, to choose them by ear.

    python tools/sfx/sound_takes.py gunshot --dry-run    # what it would ask for, and roughly what it costs
    python tools/sfx/sound_takes.py gunshot gavel        # a batch of takes of each, in sfx_auditions/<sound>/
    python tools/sfx/sound_takes.py --all --dry-run      # every sound in sounds.json
    python tools/sfx/sound_takes.py gunshot --save 2     # take 2 becomes the game's gunshot
    python tools/sfx/sound_takes.py button_press --save 1,3,4   # three takes kept, played in turn at random

What each sound asks for (its description, length, how many takes and where the chosen one goes) is in
sounds.json beside this script. Takes are scratch audio, kept out of git; a new batch is numbered on
from the last. Several takes kept for one sound go beside its file, numbered (button_press_1.wav and on).
A sound kept as a .wav is decoded and trimmed of the silence at either end, so it plays the moment it is
asked for; one marked "loop" is made to run seamlessly back into its own start, its loop written into
the file for Godot to read. The key comes from the ELEVENLABS_API_KEY environment variable or .env at
the project root, and is never printed. Saving a .wav needs ffmpeg on the path.
"""

import argparse
import array
import json
import math
import pathlib
import shutil
import struct
import subprocess
import sys
import urllib.error
import urllib.request
import wave

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1] / "voice"))
from elevenlabs import API, ROOT, TIMEOUT_SECONDS, ApiError, api_key  # noqa: E402

SOUNDS = pathlib.Path(__file__).with_name("sounds.json")
AUDITIONS = ROOT / "sfx_auditions"
OUTPUT_FORMAT = "mp3_44100_128"
# What a take costs, by ElevenLabs' help page: a set length is charged by the second. Another of their
# pages gives a higher rate, so the dry run shows both.
CREDITS_PER_SECOND = 11
CREDITS_PER_SECOND_HIGH = 40
# Silence quieter than this, in decibels, is trimmed from either end of a saved sound.
TRIM_DB = -50
# Every saved sound peaks here, in decibels, so swapping one take for another keeps the mix; how loud each
# plays in the game is its cue's.
PEAK_DB = -1.0
# Seconds of fade at the end of a saved sound, so a trimmed tail never clicks.
TAIL_FADE = 0.015
# Seconds of crossfade that join a looping sound's end to its start.
LOOP_CROSSFADE = 0.25


def generate(sound: dict, key: str) -> bytes:
    body = {
        "text": sound["prompt"],
        "duration_seconds": sound["seconds"],
        "prompt_influence": sound["influence"],
    }
    req = urllib.request.Request(
        f"{API}/sound-generation?output_format={OUTPUT_FORMAT}",
        data=json.dumps(body).encode("utf-8"),
        method="POST",
        headers={"xi-api-key": key, "Content-Type": "application/json", "Accept": "audio/mpeg"},
    )
    try:
        with urllib.request.urlopen(req, timeout=TIMEOUT_SECONDS) as response:
            return response.read()
    except urllib.error.HTTPError as error:
        raise ApiError(error.code, error.read().decode("utf-8", "replace")) from None


def take_path(name: str, number: int) -> pathlib.Path:
    return AUDITIONS / name / f"{name}_{number}.mp3"


def kept_path(file: pathlib.Path, number: int) -> pathlib.Path:
    return file.with_name(f"{file.stem}_{number}{file.suffix}")


def write_wav(take: pathlib.Path, destination: pathlib.Path, loop: bool) -> None:
    """Decodes [take] to 16 bit PCM, trims the silence at either end, fades its tail, and for a looping
    sound overlaps its end onto its start so it runs back into itself, writing the loop into the file."""
    probe = subprocess.run(["ffprobe", "-v", "error", "-select_streams", "a:0", "-show_entries",
                            "stream=sample_rate,channels", "-of", "csv=p=0", str(take)],
                           capture_output=True, check=True, text=True).stdout.strip().split(",")
    rate, channels = int(probe[0]), int(probe[1])
    trim = f"silenceremove=start_periods=1:start_threshold={TRIM_DB}dB"
    filters = f"{trim},areverse,{trim},afade=t=in:d={TAIL_FADE},areverse"
    if loop:
        filters = f"{trim},areverse,{trim},areverse"
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", str(take), "-af", filters, "-f", "s16le", "-"],
                         capture_output=True, check=True).stdout
    samples = array.array("h")
    samples.frombytes(raw)
    if not samples:
        sys.exit(f"{take.relative_to(ROOT).as_posix()} is silent below {TRIM_DB} dB: nothing to keep.")
    gain = 32767.0 * 10.0 ** (PEAK_DB / 20.0) / max(1, max(abs(v) for v in samples))
    samples = array.array("h", [max(-32768, min(32767, int(round(v * gain)))) for v in samples])
    if loop:
        samples = seamless(samples, channels, int(LOOP_CROSSFADE * rate))
    with wave.open(str(destination), "wb") as out:
        out.setnchannels(channels)
        out.setsampwidth(2)
        out.setframerate(rate)
        out.writeframes(samples.tobytes())
    if loop:
        add_loop(destination, len(samples) // channels)


def seamless(samples: array.array, channels: int, overlap: int) -> array.array:
    """The sound with its last [overlap] frames crossfaded into its first ones and dropped, so its end
    runs straight back into its start."""
    frames = len(samples) // channels
    overlap = min(overlap, frames // 3)
    joined = array.array("h", samples[:(frames - overlap) * channels])
    for i in range(overlap):
        weight = (i + 0.5) / overlap
        lead = math.sin(weight * math.pi / 2.0)
        tail = math.cos(weight * math.pi / 2.0)
        for channel in range(channels):
            mixed = samples[i * channels + channel] * lead + samples[(frames - overlap + i) * channels + channel] * tail
            joined[i * channels + channel] = max(-32768, min(32767, int(round(mixed))))
    return joined


def add_loop(path: pathlib.Path, frames: int) -> None:
    """Writes a sampler chunk into the WAV at [path] saying it loops forward over all its frames, which
    Godot's importer reads as the sound's loop."""
    data = bytearray(path.read_bytes())
    chunk = struct.pack("<4sI9I", b"smpl", 36 + 24, 0, 0, 0, 60, 0, 0, 0, 1, 0)
    chunk += struct.pack("<6I", 0, 0, 0, frames - 1, 0, 0)
    data += chunk
    struct.pack_into("<I", data, 4, len(data) - 8)
    path.write_bytes(bytes(data))


def save(name: str, sound: dict, takes: list[int]) -> None:
    """Makes the chosen takes the game's sound: one take is its file, several go beside it, numbered."""
    for number in takes:
        if not take_path(name, number).exists():
            sys.exit(f"No take {take_path(name, number).relative_to(ROOT)}")
    target = ROOT / sound["file"]
    target.parent.mkdir(parents=True, exist_ok=True)
    # Clear whatever was kept before, so the game never mixes an old pick in with the new ones.
    for old in [target, *target.parent.glob(f"{target.stem}_*{target.suffix}")]:
        if old.exists():
            old.unlink()
    for index, number in enumerate(takes, start=1):
        destination = target if len(takes) == 1 else kept_path(target, index)
        if destination.suffix == ".wav":
            write_wav(take_path(name, number), destination, bool(sound.get("loop", False)))
        else:
            shutil.copyfile(take_path(name, number), destination)
        print(f"{take_path(name, number).relative_to(ROOT).as_posix()} is now {destination.relative_to(ROOT).as_posix()}")
    print("Import the project (or click into the editor) so the game can load them.")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("sounds", nargs="*", help="the sounds' names in sounds.json")
    parser.add_argument("--all", action="store_true", help="every sound in sounds.json")
    parser.add_argument("--save", metavar="TAKES", help="make these takes the game's sound: 2, or 1,3,4")
    parser.add_argument("--dry-run", action="store_true", help="show what would be asked for and stop")
    args = parser.parse_args()

    sounds = {name: sound for name, sound in json.loads(SOUNDS.read_text(encoding="utf-8")).items()
              if isinstance(sound, dict)}
    names = list(sounds) if args.all else args.sounds
    if not names:
        sys.exit(f"Name a sound, or --all. There are: {', '.join(sorted(sounds))}")
    for name in names:
        if name not in sounds:
            sys.exit(f"No sound called {name} in {SOUNDS.name}. There are: {', '.join(sorted(sounds))}")

    if args.save is not None:
        if len(names) != 1:
            sys.exit("Save one sound at a time.")
        save(names[0], sounds[names[0]], [int(take) for take in args.save.split(",") if take.strip()])
        return

    seconds = 0.0
    for name in names:
        sound = sounds[name]
        seconds += sound["seconds"] * sound["takes"]
        print(f"{name}: {sound['takes']} takes of {sound['seconds']} s, influence {sound['influence']}")
        print(f"  {sound['prompt']}")
    takes = sum(sounds[name]["takes"] for name in names)
    print(f"{takes} takes, {seconds:g} seconds of sound: about {round(seconds * CREDITS_PER_SECOND):,} credits "
          f"(at most {round(seconds * CREDITS_PER_SECOND_HIGH):,})")
    if args.dry_run:
        return
    key = api_key()
    for name in names:
        sound = sounds[name]
        folder = AUDITIONS / name
        folder.mkdir(parents=True, exist_ok=True)
        first = 1 + len(list(folder.glob(f"{name}_*.mp3")))
        for number in range(first, first + sound["takes"]):
            path = take_path(name, number)
            path.write_bytes(generate(sound, key))
            print(f"  {path.relative_to(ROOT).as_posix()}", flush=True)


if __name__ == "__main__":
    main()
