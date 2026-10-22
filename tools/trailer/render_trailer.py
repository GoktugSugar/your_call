"""Record the trailer's shots with Godot's Movie Maker, then cut, mix and encode them with ffmpeg.

    python tools/trailer/render_trailer.py                 record what is missing or changed, then cut it
    python tools/trailer/render_trailer.py --dry-run       show the plan: the pieces, their times, what would be recorded
    python tools/trailer/render_trailer.py --shots lever,gun   record these shots again, whatever the cache says
    python tools/trailer/render_trailer.py --fresh         record every shot again (after a change to the game's code)
    python tools/trailer/render_trailer.py --cut-only      cut, mix and encode from the recordings there are
    python tools/trailer/render_trailer.py --draft         a quick small encode for a first look, and nothing else

The cut is trailer/trailer_cut.json: the shots (what each recording plays, see trailer/trailer.gd), the
pieces of them that make the trailer in order, and the music and sounds laid over it. Each shot is one run
of res://trailer/trailer.tscn recorded as PNG frames and a WAV, as long as the cut needs, in
trailer_renders/shots/<shot>/ (git ignores trailer_renders/, and Godot does too). A shot is recorded again
when its settings, its length, the trailer's lines or the voice clips change. Shots are recorded a few at
a time, each in its own window; nothing plays out loud.

The encodes go to trailer_renders/: your_call_trailer_steam.mp4 (1920x1080, H.264 High at a high bit rate
with AAC stereo at 48 kHz, as Steam asks), your_call_trailer.mp4 (a smaller one to share) and
your_call_trailer_draft.mp4 (960x540, for a quick look), with a contact sheet of the cut beside them.
The project's window size for the recording is set by an override.cfg that exists only while recording.
"""

import argparse
import concurrent.futures
import hashlib
import json
import os
import pathlib
import shutil
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
CUT = ROOT / "trailer" / "trailer_cut.json"
LINES = ROOT / "trailer" / "trailer_lines.json"
MANIFEST = ROOT / "assets" / "voice" / "manifest.json"
RENDERS = ROOT / "trailer_renders"
SHOTS = RENDERS / "shots"
OVERRIDE = ROOT / "override.cfg"
GODOT = os.environ.get("GODOT", r"C:\Program Files\Godot\Godot_Console.exe")
SCENE = "res://trailer/trailer.tscn"
FRAME_NAME = "f"
# Seconds recorded past the last moment the cut takes from a shot, so a piece never runs short.
TAIL = 0.2

STEAM = {"name": "your_call_trailer_steam.mp4", "crf": 10, "maxrate": "24M", "bufsize": "48M", "audio": "192k", "scale": None}
SHARE = {"name": "your_call_trailer.mp4", "crf": 20, "maxrate": "10M", "bufsize": "20M", "audio": "160k", "scale": None}
DRAFT = {"name": "your_call_trailer_draft.mp4", "crf": 24, "maxrate": "3M", "bufsize": "6M", "audio": "128k", "scale": (960, 540)}


def ffmpeg_tool(name: str) -> str:
    """The path to ffmpeg or ffprobe: from the environment, the PATH, or where winget puts it."""
    found = os.environ.get(name.upper()) or shutil.which(name)
    if found:
        return found
    packages = pathlib.Path(os.environ.get("LOCALAPPDATA", "")) / "Microsoft" / "WinGet" / "Packages"
    for candidate in sorted(packages.glob(f"Gyan.FFmpeg*/*/bin/{name}.exe"), reverse=True):
        return str(candidate)
    sys.exit(f"{name} is not installed. Install it with: winget install --id Gyan.FFmpeg -e")


def load_cut() -> dict:
    return json.loads(CUT.read_text(encoding="utf-8"))


def pieces(cut: dict) -> list[dict]:
    """The cut's pieces in order, each with where it starts in the trailer and its frames."""
    fps = cut["fps"]
    placed = []
    start = 0
    uses: dict[str, int] = {}
    for raw in cut["cut"]:
        piece = dict(raw)
        if piece["shot"] not in cut["shots"]:
            sys.exit(f"The cut takes from a shot called {piece['shot']}, which trailer_cut.json does not have.")
        piece["use"] = uses.get(piece["shot"], 0)
        uses[piece["shot"]] = piece["use"] + 1
        piece["first_frame"] = round(piece["in"] * fps)
        piece["frames"] = round(piece["length"] * fps)
        piece["start_frame"] = start
        piece["start"] = start / fps
        start += piece["frames"]
        placed.append(piece)
    return placed


def total_seconds(cut: dict) -> float:
    return sum(piece["frames"] for piece in pieces(cut)) / cut["fps"]


def when(cut: dict, mark) -> float:
    """Seconds into the trailer of a mark: a number of seconds, or a time into a piece of the cut,
    {"shot": name, "time": seconds}, with "use" picking among several pieces of the same shot."""
    if isinstance(mark, (int, float)):
        return float(mark)
    for piece in pieces(cut):
        if piece["shot"] == mark["shot"] and piece["use"] == mark.get("use", 0):
            return piece["start"] + float(mark.get("time", 0.0))
    sys.exit(f"No piece of the cut is shot {mark['shot']} (use {mark.get('use', 0)}).")


def frames_needed(cut: dict) -> dict[str, int]:
    """How many frames each shot must be recorded for: as far as the cut takes from it, and a little more."""
    fps = cut["fps"]
    needed: dict[str, int] = {}
    for piece in pieces(cut):
        end = piece["first_frame"] + piece["frames"] + round(TAIL * fps)
        needed[piece["shot"]] = max(needed.get(piece["shot"], 0), end)
    return needed


def recipe(cut: dict, shot: str) -> str:
    """Changes whenever what a shot's recording would show changes, as far as the data knows. How long
    it runs is left out: a recording long enough for the cut stays good when the cut takes less."""
    parts = {
        "shot": cut["shots"][shot], "fps": cut["fps"], "size": cut["size"],
        "lines": hashlib.sha1(LINES.read_bytes()).hexdigest(),
        "voices": hashlib.sha1(MANIFEST.read_bytes()).hexdigest() if MANIFEST.exists() else "",
    }
    return hashlib.sha1(json.dumps(parts, sort_keys=True).encode("utf-8")).hexdigest()


def is_current(shot: str, signature: str, frames: int) -> bool:
    folder = SHOTS / shot
    stamp = folder / "recipe.txt"
    last = folder / f"{FRAME_NAME}{frames - 1:08d}.png"
    return stamp.exists() and stamp.read_text(encoding="utf-8").strip() == signature and last.exists()


def record(shot: str, frames: int, fps: int, signature: str) -> tuple[str, bool, str]:
    folder = SHOTS / shot
    if folder.exists():
        shutil.rmtree(folder)
    folder.mkdir(parents=True)
    command = [GODOT, "--path", str(ROOT), "--write-movie", str(folder / f"{FRAME_NAME}.png"),
               "--fixed-fps", str(fps), SCENE, "--quit-after", str(frames), "--", f"--shot={shot}", "--log"]
    result = subprocess.run(command, capture_output=True, text=True, encoding="utf-8", errors="replace")
    (folder / "log.txt").write_text(result.stdout + result.stderr, encoding="utf-8")
    ok = result.returncode == 0 and (folder / f"{FRAME_NAME}{frames - 1:08d}.png").exists()
    if ok:
        (folder / "recipe.txt").write_text(signature, encoding="utf-8")
    problems = [line for line in (result.stdout + result.stderr).splitlines() if "ERROR" in line or "SCRIPT ERROR" in line]
    return shot, ok, "\n".join(problems[:6])


def record_all(cut: dict, wanted: list[str], jobs: int) -> None:
    size = cut["size"]
    OVERRIDE.write_text(
        "; Written by tools/trailer/render_trailer.py while it records the trailer, and removed after.\n"
        f"[display]\n\nwindow/size/window_width_override={size[0]}\nwindow/size/window_height_override={size[1]}\n"
        "window/size/mode=0\n", encoding="utf-8")
    try:
        needed = frames_needed(cut)
        with concurrent.futures.ThreadPoolExecutor(max_workers=jobs) as pool:
            futures = [pool.submit(record, shot, needed[shot], cut["fps"], recipe(cut, shot)) for shot in wanted]
            for future in concurrent.futures.as_completed(futures):
                shot, ok, problems = future.result()
                print(f"  recorded {shot}" if ok else f"  FAILED to record {shot} (see {SHOTS / shot / 'log.txt'})")
                if problems:
                    print("    " + problems.replace("\n", "\n    "))
    finally:
        OVERRIDE.unlink(missing_ok=True)


def resource_path(resource: str) -> pathlib.Path:
    return ROOT / resource.removeprefix("res://")


def decibels(gain_db: float) -> str:
    return f"{gain_db:.2f}dB"


def audio_graph(cut: dict) -> tuple[list[str], str]:
    """The ffmpeg inputs and filter graph for the trailer's sound: the shots' own sound cut together, the
    music laid under it and ducking while someone talks, and the sound effects."""
    fps = cut["fps"]
    inputs: list[str] = []
    chains: list[str] = []
    placed = pieces(cut)
    for i, piece in enumerate(placed):
        inputs += ["-i", str(SHOTS / piece["shot"] / f"{FRAME_NAME}.wav")]
        start, end = piece["in"], piece["in"] + piece["frames"] / fps
        chains.append(f"[{i}:a]atrim=start={start:.4f}:end={end:.4f},asetpts=PTS-STARTPTS,"
                      f"aformat=sample_fmts=fltp:sample_rates=48000:channel_layouts=stereo[a{i}]")
    count = len(placed)
    joined = "".join(f"[a{i}]" for i in range(count))
    chains.append(f"{joined}concat=n={count}:v=0:a=1[cuta]")
    length = total_seconds(cut)
    sound = cut.get("sound", {})
    # The shots' own sound (the voice, the gunshot) leads; the music ducks under it.
    chains.append(f"[cuta]volume={decibels(float(sound.get('voice_gain_db', 0.0)))},asplit=2[voice][key]")
    mixed = ["[voice]"]
    next_input = count
    music_labels = []
    for m, music in enumerate(sound.get("music", [])):
        inputs += ["-i", str(resource_path(music["file"]))]
        at = when(cut, music["at"])
        source_from = float(music.get("from", 0.0))
        until = when(cut, music["until"]) if "until" in music else length
        run = max(until - at, 0.0)
        fade_in = float(music.get("fade_in", 0.0))
        fade_out = float(music.get("fade_out", 0.0))
        chain = (f"[{next_input}:a]aformat=sample_fmts=fltp:sample_rates=48000:channel_layouts=stereo,"
                 f"atrim=start={source_from:.4f}:end={source_from + run:.4f},asetpts=PTS-STARTPTS,"
                 f"volume={decibels(float(music.get('gain_db', 0.0)))}")
        if fade_in > 0.0:
            chain += f",afade=t=in:st=0:d={fade_in:.3f}"
        if fade_out > 0.0:
            chain += f",afade=t=out:st={max(run - fade_out, 0.0):.3f}:d={fade_out:.3f}"
        chain += f",adelay={int(round(at * 1000))}:all=1,apad=whole_dur={length:.4f}[music{m}]"
        chains.append(chain)
        music_labels.append(f"[music{m}]")
        next_input += 1
    if music_labels:
        duck = sound.get("duck", {})
        chains.append(f"{''.join(music_labels)}amix=inputs={len(music_labels)}:normalize=0[music]")
        chains.append(f"[music][key]sidechaincompress=threshold={duck.get('threshold', 0.03)}:ratio={duck.get('ratio', 4)}"
                      f":attack={duck.get('attack', 25)}:release={duck.get('release', 400)}:makeup=1[ducked]")
        mixed.append("[ducked]")
    else:
        chains.append("[key]anullsink")
    for s, effect in enumerate(sound.get("sounds", [])):
        inputs += ["-i", str(resource_path(effect["file"]))]
        at = when(cut, effect["at"])
        chain = (f"[{next_input}:a]aformat=sample_fmts=fltp:sample_rates=48000:channel_layouts=stereo,"
                 f"volume={decibels(float(effect.get('gain_db', 0.0)))}")
        if "until" in effect:
            # Cut off where the picture cuts away, with a breath of a fade so it does not click.
            run = max(when(cut, effect["until"]) - at, 0.0)
            fade_out = min(float(effect.get("fade_out", 0.05)), run)
            chain += f",atrim=end={run:.4f},afade=t=out:st={run - fade_out:.3f}:d={fade_out:.3f}"
        chain += f",adelay={int(round(at * 1000))}:all=1,apad=whole_dur={length:.4f}[sound{s}]"
        chains.append(chain)
        mixed.append(f"[sound{s}]")
        next_input += 1
    chains.append(f"{''.join(mixed)}amix=inputs={len(mixed)}:normalize=0,atrim=end={length:.4f}[outa]")
    return inputs, ";\n".join(chains)


def video_graph(cut: dict, encode: dict) -> tuple[list[str], str]:
    """The ffmpeg inputs and filter graph that cut the shots' frames together, fade the ends and size it."""
    fps = cut["fps"]
    inputs: list[str] = []
    chains: list[str] = []
    placed = pieces(cut)
    for i, piece in enumerate(placed):
        inputs += ["-framerate", str(fps), "-start_number", str(piece["first_frame"]),
                   "-i", str(SHOTS / piece["shot"] / f"{FRAME_NAME}%08d.png")]
        chains.append(f"[{i}:v]trim=end_frame={piece['frames']},setpts=PTS-STARTPTS,format=rgb24[v{i}]")
    count = len(placed)
    length = total_seconds(cut)
    steps = [f"concat=n={count}:v=1:a=0"]
    fade = cut.get("fade", {})
    if float(fade.get("in", 0.0)) > 0.0:
        steps.append(f"fade=t=in:st=0:d={float(fade['in']):.3f}")
    if float(fade.get("out", 0.0)) > 0.0:
        steps.append(f"fade=t=out:st={length - float(fade['out']):.3f}:d={float(fade['out']):.3f}")
    if encode["scale"]:
        steps.append(f"scale={encode['scale'][0]}:{encode['scale'][1]}:flags=lanczos")
    steps.append("format=yuv420p")
    joined = "".join(f"[v{i}]" for i in range(count))
    chains.append(f"{joined}{','.join(steps)}[outv]")
    return inputs, ";\n".join(chains)


def run_ffmpeg(arguments: list[str], what: str) -> subprocess.CompletedProcess:
    result = subprocess.run([ffmpeg_tool("ffmpeg"), "-hide_banner", "-y", *arguments],
                            capture_output=True, text=True, encoding="utf-8", errors="replace")
    if result.returncode != 0:
        sys.exit(f"ffmpeg could not {what}:\n{result.stderr[-3000:]}")
    return result


def master_sound(cut: dict) -> pathlib.Path:
    """Mixes the trailer's sound, then brings it to the loudness the cut asks for in two passes, so it
    is turned up or down as a whole rather than squeezed, and fades its end."""
    inputs, graph = audio_graph(cut)
    graph_file = RENDERS / "sound_graph.txt"
    graph_file.write_text(graph, encoding="utf-8")
    mix = RENDERS / "sound_mix.wav"
    run_ffmpeg(["-loglevel", "error", *inputs, "-/filter_complex", str(graph_file), "-map", "[outa]",
                "-c:a", "pcm_f32le", str(mix)], "mix the sound")
    sound = cut.get("sound", {})
    target = f"I={float(sound.get('loudness', -16.0))}:TP={float(sound.get('peak', -1.5))}:LRA=11"
    measured = run_ffmpeg(["-loglevel", "info", "-i", str(mix), "-af", f"loudnorm={target}:print_format=json",
                           "-f", "null", "-"], "measure the sound")
    report = measured.stderr[measured.stderr.rindex("{"):measured.stderr.rindex("}") + 1]
    m = json.loads(report)
    length = total_seconds(cut)
    fade_out = float(cut.get("fade", {}).get("out", 0.0))
    chain = (f"loudnorm={target}:measured_I={m['input_i']}:measured_TP={m['input_tp']}:measured_LRA={m['input_lra']}"
             f":measured_thresh={m['input_thresh']}:offset={m['target_offset']}:linear=true,aresample=48000")
    if fade_out > 0.0:
        chain += f",afade=t=out:st={length - fade_out:.3f}:d={fade_out:.3f}"
    master = RENDERS / "sound_master.wav"
    run_ffmpeg(["-loglevel", "error", "-i", str(mix), "-af", chain, "-c:a", "pcm_s24le", str(master)], "master the sound")
    return master


def encode_one(cut: dict, encode: dict, sound: pathlib.Path) -> pathlib.Path:
    out = RENDERS / encode["name"]
    inputs, graph = video_graph(cut, encode)
    graph_file = RENDERS / (out.stem + "_graph.txt")
    graph_file.write_text(graph, encoding="utf-8")
    audio_index = len(placed_inputs(inputs))
    run_ffmpeg(["-loglevel", "error", *inputs, "-i", str(sound), "-/filter_complex", str(graph_file),
                "-map", "[outv]", "-map", f"{audio_index}:a",
                "-c:v", "libx264", "-preset", "slow", "-tune", "grain", "-profile:v", "high", "-level", "4.2",
                "-crf", str(encode["crf"]), "-maxrate", encode["maxrate"], "-bufsize", encode["bufsize"],
                "-r", str(cut["fps"]), "-g", str(cut["fps"] * 2), "-pix_fmt", "yuv420p",
                "-c:a", "aac", "-b:a", encode["audio"], "-ar", "48000", "-ac", "2",
                "-movflags", "+faststart", "-shortest", str(out)], f"encode {out.name}")
    return out


def placed_inputs(arguments: list[str]) -> list[str]:
    """The inputs named in a list of ffmpeg arguments."""
    return [arguments[i + 1] for i, argument in enumerate(arguments) if argument == "-i"]


def contact_sheet(video: pathlib.Path, every: float = 1.0) -> pathlib.Path:
    """A sheet of frames from [video], one every [every] seconds, eight to a row."""
    sheet = video.with_name(video.stem + "_sheet.png")
    subprocess.run([ffmpeg_tool("ffmpeg"), "-hide_banner", "-loglevel", "error", "-y", "-i", str(video),
                    "-vf", f"fps=1/{every},scale=320:-1,tile=8x8:padding=4:color=0x333333", "-frames:v", "1", str(sheet)],
                   check=True)
    return sheet


def describe(video: pathlib.Path) -> str:
    probe = subprocess.run([ffmpeg_tool("ffprobe"), "-v", "error", "-show_entries",
                            "format=duration,bit_rate,size:stream=codec_name,width,height,r_frame_rate,sample_rate,channels",
                            "-of", "json", str(video)], capture_output=True, text=True, check=True)
    info = json.loads(probe.stdout)
    streams = ", ".join(
        f"{s['codec_name']} {s.get('width', '')}x{s.get('height', '')} {s.get('r_frame_rate', '')}" if "width" in s
        else f"{s['codec_name']} {s.get('sample_rate', '')} Hz x{s.get('channels', '')}"
        for s in info["streams"])
    fmt = info["format"]
    return (f"{video.name}: {float(fmt['duration']):.2f} s, {int(fmt['bit_rate']) / 1e6:.1f} Mbit/s, "
            f"{int(fmt['size']) / 1e6:.1f} MB ({streams})")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--shots", help="record these shots again, comma separated")
    parser.add_argument("--fresh", action="store_true", help="record every shot again")
    parser.add_argument("--cut-only", action="store_true", help="only cut, mix and encode")
    parser.add_argument("--record-only", action="store_true", help="only record")
    parser.add_argument("--draft", action="store_true", help="encode only the small draft")
    parser.add_argument("--jobs", type=int, default=4, help="shots recorded at once")
    parser.add_argument("--dry-run", action="store_true", help="show the plan and stop")
    args = parser.parse_args()

    cut = load_cut()
    RENDERS.mkdir(exist_ok=True)
    (RENDERS / ".gdignore").touch()
    needed = frames_needed(cut)
    forced = set(args.shots.split(",")) if args.shots else set()
    unknown = forced - set(cut["shots"])
    if unknown:
        sys.exit(f"No shot called {', '.join(sorted(unknown))} in trailer_cut.json")
    stale = [shot for shot in needed if args.fresh or shot in forced
             or not is_current(shot, recipe(cut, shot), needed[shot])]

    print(f"The cut: {len(cut['cut'])} pieces, {total_seconds(cut):.2f} s at {cut['fps']} fps")
    for piece in pieces(cut):
        print(f"  {piece['start']:6.2f} s  {piece['shot']:<12} from {piece['in']:5.2f} s for {piece['frames'] / cut['fps']:5.2f} s")
    print(f"To record: {', '.join(stale) if stale else 'nothing'}")
    if args.dry_run:
        return
    if stale and not args.cut_only:
        record_all(cut, stale, max(1, args.jobs))
    if args.record_only:
        return
    missing = [shot for shot in needed if not (SHOTS / shot / f"{FRAME_NAME}{needed[shot] - 1:08d}.png").exists()]
    if missing:
        sys.exit(f"These shots have no recording long enough to cut: {', '.join(missing)}")
    sound = master_sound(cut)
    for encode in [DRAFT] if args.draft else [STEAM, SHARE, DRAFT]:
        out = encode_one(cut, encode, sound)
        print("  " + describe(out))
        if encode is DRAFT:
            print(f"  contact sheet: {contact_sheet(out)}")


if __name__ == "__main__":
    main()
