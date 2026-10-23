"""Record the trailers' shots with Godot's Movie Maker, then cut, mix and encode both trailers with ffmpeg.

    python tools/trailer/render_trailer.py                  record what is missing or changed, then cut both
    python tools/trailer/render_trailer.py --format tall    only the tall one (9:16, for phones), or wide (16:9)
    python tools/trailer/render_trailer.py --dry-run        show the plan: the shots, the pieces and their times
    python tools/trailer/render_trailer.py --shots open,title   record these shots again, whatever the cache says
    python tools/trailer/render_trailer.py --fresh          record every shot again (after a change to the game's code)
    python tools/trailer/render_trailer.py --cut-only       cut, mix and encode from the recordings there are
    python tools/trailer/render_trailer.py --draft          a quick small encode for a first look, and nothing else

The cut is dev/trailer/trailer_cut.json: its formats, the shots (what each recording plays, see
dev/trailer/trailer.gd), the pieces of them that make the trailers in order, and the music and sounds
laid over them. Each shot is one run of res://dev/trailer/trailer.tscn, recorded as an MJPEG AVI at full
quality with its sound (the voices and the game's sound effects), as long as the shot's "seconds" say, in
trailer_renders/shots/<format>/<shot>/ beside the log of its moments. A shot is recorded again when its
settings, its format, the trailers' lines or the voice clips change. The shots of a format are recorded a
few at a time, each in its own small window; nothing plays out loud. The project's window and stretch
settings for the recording come from an override.cfg that exists only while a format records.

A piece runs from and to a time in its shot: seconds, or a moment the shot's log names, page:<line> (a
line of the trailers' starts), said:<line> (it has been said), mark:<name> or phase:<phase>, with plus
seconds after it. A piece can run backwards (reverse) and faster (speed), its sound with it, the way a
tape rewinds. The music and sounds are placed at a time in the cut: seconds, or {"piece": <its name>,
"plus": seconds}.

The encodes go to trailer_renders/: your_call_trailer_<format>.mp4 (H.264 High at a high bit rate with AAC
stereo at 48 kHz, to upload: the wide one to a video site the itch.io page embeds, the tall one to TikTok,
Reels or Shorts) and your_call_trailer_<format>_draft.mp4 (half size, for a quick look), with a contact
sheet of each cut beside them.
"""

import argparse
import concurrent.futures
import hashlib
import json
import os
import pathlib
import re
import shutil
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
CUT = ROOT / "dev" / "trailer" / "trailer_cut.json"
LINES = ROOT / "dev" / "trailer" / "trailer_lines.json"
MANIFEST = ROOT / "assets" / "voice" / "manifest.json"
RENDERS = ROOT / "trailer_renders"
SHOTS = RENDERS / "shots"
OVERRIDE = ROOT / "override.cfg"
GODOT = os.environ.get("GODOT", r"C:\Program Files\Godot\Godot_Console.exe")
SCENE = "res://dev/trailer/trailer.tscn"
FORMATS = ("wide", "tall")
# Seconds a shot records when it does not say.
DEFAULT_SECONDS = 14.0
# How much smaller than the picture the recording window is: Movie Maker records the viewport whole.
WINDOW_SHARE = 0.5
SAMPLE_RATE = 48000

FINAL = {"suffix": "", "crf": 14, "maxrate": "20M", "bufsize": "40M", "audio": "192k", "half": False}
DRAFT = {"suffix": "_draft", "crf": 24, "maxrate": "3M", "bufsize": "6M", "audio": "128k", "half": True}


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


def by_format(value, fmt: str):
    """A setting as this format has it: the value under the format's name when it differs by format."""
    if isinstance(value, dict) and any(name in value for name in FORMATS):
        return value.get(fmt)
    return value


def pieces_for(cut: dict, fmt: str) -> list[dict]:
    """The cut's pieces for a format, in order: each piece with its format's overrides applied."""
    placed = []
    for raw in cut["cut"]:
        if raw.get("only") not in (None, fmt):
            continue
        piece = {key: value for key, value in raw.items() if key not in FORMATS}
        piece.update(raw.get(fmt, {}))
        if piece["shot"] not in cut["shots"]:
            sys.exit(f"The cut takes from a shot called {piece['shot']}, which trailer_cut.json does not have.")
        placed.append(piece)
    return placed


def shot_folder(fmt: str, shot: str) -> pathlib.Path:
    return SHOTS / fmt / shot


def recipe(cut: dict, fmt: str, shot: str) -> str:
    """Changes whenever what a shot's recording would show or say changes, as far as the data knows."""
    parts = {
        "shot": cut["shots"][shot], "fps": cut["fps"], "format": cut["formats"][fmt],
        "lines": hashlib.sha1(LINES.read_bytes()).hexdigest(),
        "voices": hashlib.sha1(MANIFEST.read_bytes()).hexdigest() if MANIFEST.exists() else "",
    }
    return hashlib.sha1(json.dumps(parts, sort_keys=True).encode("utf-8")).hexdigest()


def is_current(cut: dict, fmt: str, shot: str) -> bool:
    folder = shot_folder(fmt, shot)
    stamp = folder / "recipe.txt"
    return (stamp.exists() and stamp.read_text(encoding="utf-8").strip() == recipe(cut, fmt, shot)
            and (folder / "shot.avi").exists())


def frames_of(cut: dict, shot: str) -> int:
    return round(float(cut["shots"][shot].get("seconds", DEFAULT_SECONDS)) * cut["fps"])


def record(cut: dict, fmt: str, shot: str) -> tuple[str, bool, str]:
    folder = shot_folder(fmt, shot)
    if folder.exists():
        shutil.rmtree(folder)
    folder.mkdir(parents=True)
    command = [GODOT, "--path", str(ROOT), "--audio-driver", "Dummy", "--write-movie", str(folder / "shot.avi"),
               "--fixed-fps", str(cut["fps"]), SCENE, "--quit-after", str(frames_of(cut, shot)),
               "--", f"--shot={shot}", f"--format={fmt}", "--log"]
    result = subprocess.run(command, capture_output=True, text=True, encoding="utf-8", errors="replace")
    (folder / "log.txt").write_text(result.stdout + result.stderr, encoding="utf-8", newline="\n")
    ok = result.returncode == 0 and (folder / "shot.avi").exists()
    if ok:
        (folder / "recipe.txt").write_text(recipe(cut, fmt, shot), encoding="utf-8", newline="\n")
    problems = [line for line in (result.stdout + result.stderr).splitlines()
                if "SCRIPT ERROR" in line or ("ERROR" in line and "resources still in use" not in line)]
    return shot, ok, "\n".join(problems[:6])


def record_format(cut: dict, fmt: str, wanted: list[str], jobs: int) -> None:
    width, height = cut["formats"][fmt]["size"]
    OVERRIDE.write_bytes((
        "; Written by tools/trailer/render_trailer.py while it records the trailers, and removed after.\n"
        "[display]\n\n"
        f"window/size/viewport_width={width}\nwindow/size/viewport_height={height}\n"
        f"window/size/mode=0\nwindow/size/window_width_override={round(width * WINDOW_SHARE)}\n"
        f"window/size/window_height_override={round(height * WINDOW_SHARE)}\n"
        'window/stretch/mode="viewport"\n\n'
        "[editor]\n\nmovie_writer/mjpeg_quality=1.0\n").encode("utf-8"))
    try:
        with concurrent.futures.ThreadPoolExecutor(max_workers=jobs) as pool:
            futures = [pool.submit(record, cut, fmt, shot) for shot in wanted]
            for future in concurrent.futures.as_completed(futures):
                shot, ok, problems = future.result()
                print(f"  recorded {fmt} {shot}" if ok else f"  FAILED to record {fmt} {shot} (see {shot_folder(fmt, shot) / 'log.txt'})")
                if problems:
                    print("    " + problems.replace("\n", "\n    "))
    finally:
        OVERRIDE.unlink(missing_ok=True)


MOMENT = re.compile(r"^\s*(-?\d+\.\d+)\s+(.*)$")


def moments(fmt: str, shot: str) -> list[tuple[float, str]]:
    """Every moment the shot's log names, in order: its time and what happened."""
    log = shot_folder(fmt, shot) / "log.txt"
    found = []
    for line in log.read_text(encoding="utf-8", errors="replace").splitlines() if log.exists() else []:
        match = MOMENT.match(line)
        if match:
            found.append((float(match.group(1)), match.group(2)))
    return found


def moment_time(fmt: str, shot: str, name: str) -> float:
    """When the moment called [name] came in the shot: page:<line>, said:<line>, mark:<name> or phase:<phase>.
    A line is one of the trailers' by name, or any line by its whole id, such as ch7.recliner.ask.3."""
    kind, _, what = name.partition(":")
    line_id = re.escape(what if "." in what else f"trailer.{what}.lines.1")
    patterns = {
        "page": rf"page 1 of \d+ of {line_id}$",
        "said": rf"said {line_id}$",
        "mark": rf"^mark {re.escape(what)}$",
        "phase": rf"^phase {re.escape(what)}$",
    }
    if kind not in patterns:
        sys.exit(f"A piece names a moment {name!r}; moments are page:, said:, mark: or phase:.")
    for time, text in moments(fmt, shot):
        if re.search(patterns[kind], text):
            return time
    sys.exit(f"The {fmt} recording of {shot} never logged {name!r} (see {shot_folder(fmt, shot) / 'log.txt'}).")


def shot_time(fmt: str, shot: str, value) -> float:
    if isinstance(value, (int, float)):
        return float(value)
    return moment_time(fmt, shot, value["at"]) + float(value.get("plus", 0.0))


def timeline(cut: dict, fmt: str) -> list[dict]:
    """The pieces with their times resolved: where each starts and ends in its shot, and in the trailer."""
    fps = cut["fps"]
    placed = []
    start_frame = 0
    for piece in pieces_for(cut, fmt):
        begin = shot_time(fmt, piece["shot"], piece["from"])
        end = shot_time(fmt, piece["shot"], piece["to"])
        if end <= begin:
            sys.exit(f"A piece of {piece['shot']} ({fmt}) ends at {end:.2f} s, no later than it starts ({begin:.2f} s).")
        speed = float(piece.get("speed", 1.0))
        frames = max(round((end - begin) / speed * fps), 1)
        recorded = frames_of(cut, piece["shot"]) / fps
        if end > recorded:
            sys.exit(f"A piece of {piece['shot']} ({fmt}) runs to {end:.2f} s, past the {recorded:.1f} s it records: give the shot more seconds.")
        placed.append({**piece, "begin": begin, "end": end, "speed": speed, "frames": frames,
                       "start_frame": start_frame, "start": start_frame / fps})
        start_frame += frames
    return placed


def total_seconds(placed: list[dict], fps: int) -> float:
    return sum(piece["frames"] for piece in placed) / fps


def cut_time(placed: list[dict], mark) -> float:
    """Seconds into the trailer of a mark: seconds, or {"piece": name, "plus": seconds}."""
    if isinstance(mark, (int, float)):
        return float(mark)
    for piece in placed:
        if piece.get("name") == mark["piece"]:
            return piece["start"] + float(mark.get("plus", 0.0))
    sys.exit(f"No piece of the cut is called {mark['piece']!r}.")


def resource_path(resource: str) -> pathlib.Path:
    return ROOT / resource.removeprefix("res://")


def decibels(gain_db: float) -> str:
    return f"{gain_db:.2f}dB"


def graph(cut: dict, fmt: str, placed: list[dict], encode: dict) -> tuple[list[str], str]:
    """The ffmpeg inputs and filter graph: the pieces cut together, picture and sound, the music laid under
    them and dipping while anyone talks, the sounds over them, the whole brought to its loudness."""
    fps = cut["fps"]
    width, height = cut["formats"][fmt]["size"]
    if encode["half"]:
        width, height = width // 2, height // 2
    inputs: list[str] = []
    chains: list[str] = []
    for i, piece in enumerate(placed):
        inputs += ["-i", str(shot_folder(fmt, piece["shot"]) / "shot.avi")]
        begin, end, speed = piece["begin"], piece["end"], piece["speed"]
        video = f"[{i}:v]trim=start={begin:.4f}:end={end:.4f},setpts=(PTS-STARTPTS)/{speed:.4f},fps={fps}"
        audio = (f"[{i}:a]atrim=start={begin:.4f}:end={end:.4f},asetpts=PTS-STARTPTS,"
                 f"aformat=sample_fmts=fltp:sample_rates={SAMPLE_RATE}:channel_layouts=stereo")
        if piece.get("reverse"):
            video += ",reverse"
            audio += ",areverse"
        if speed != 1.0:
            # Faster and higher, the way a tape runs when it is wound on.
            audio += f",asetrate={round(SAMPLE_RATE * speed)},aresample={SAMPLE_RATE}"
        audio += f",volume={decibels(float(piece.get('gain_db', 0.0)))}"
        frames = piece["frames"]
        video += (f",trim=end_frame={frames},scale={width}:{height}:in_range=full:out_range=limited:flags=lanczos,"
                  f"setsar=1,format=yuv420p[v{i}]")
        audio += f",apad=whole_dur={frames / fps:.4f},atrim=end={frames / fps:.4f}[a{i}]"
        chains += [video, audio]
    count = len(placed)
    length = total_seconds(placed, fps)
    fade = cut.get("fade", {})
    steps = [f"concat=n={count}:v=1:a=0"]
    if float(fade.get("in", 0.0)) > 0.0:
        steps.append(f"fade=t=in:st=0:d={float(fade['in']):.3f}")
    if float(fade.get("out", 0.0)) > 0.0:
        steps.append(f"fade=t=out:st={length - float(fade['out']):.3f}:d={float(fade['out']):.3f}")
    chains.append("".join(f"[v{i}]" for i in range(count)) + ",".join(steps) + "[outv]")
    chains.append("".join(f"[a{i}]" for i in range(count)) + f"concat=n={count}:v=0:a=1[cuta]")

    sound = cut.get("sound", {})
    chains.append(f"[cuta]volume={decibels(float(sound.get('voice_gain_db', 0.0)))},asplit=2[voice][key]")
    mixed = ["[voice]"]
    next_input = count
    music_labels = []
    for m, music in enumerate(sound.get("music", [])):
        inputs += ["-stream_loop", "-1", "-i", str(resource_path(music["file"]))]
        at = cut_time(placed, music["at"])
        until = cut_time(placed, music["until"]) if "until" in music else length
        source_from = float(music.get("from", 0.0))
        run = max(until - at, 0.0)
        chain = (f"[{next_input}:a]aformat=sample_fmts=fltp:sample_rates={SAMPLE_RATE}:channel_layouts=stereo,"
                 f"atrim=start={source_from:.4f}:end={source_from + run:.4f},asetpts=PTS-STARTPTS,"
                 f"volume={decibels(float(music.get('gain_db', 0.0)))}")
        if float(music.get("fade_in", 0.0)) > 0.0:
            chain += f",afade=t=in:st=0:d={float(music['fade_in']):.3f}"
        if float(music.get("fade_out", 0.0)) > 0.0:
            fade_out = min(float(music["fade_out"]), run)
            chain += f",afade=t=out:st={run - fade_out:.3f}:d={fade_out:.3f}"
        chain += f",adelay={round(at * 1000)}:all=1,apad=whole_dur={length:.4f}[music{m}]"
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
        at = cut_time(placed, effect["at"])
        chain = (f"[{next_input}:a]aformat=sample_fmts=fltp:sample_rates={SAMPLE_RATE}:channel_layouts=stereo,"
                 f"volume={decibels(float(effect.get('gain_db', 0.0)))}")
        chain += f",adelay={round(at * 1000)}:all=1,apad=whole_dur={length:.4f}[sound{s}]"
        chains.append(chain)
        mixed.append(f"[sound{s}]")
        next_input += 1
    loudness = float(sound.get("loudness", -14.0))
    chains.append(f"{''.join(mixed)}amix=inputs={len(mixed)}:normalize=0,atrim=end={length:.4f},"
                  f"loudnorm=I={loudness:.1f}:TP=-1.5:LRA=11,aresample={SAMPLE_RATE}[outa]")
    return inputs, ";\n".join(chains)


def encode(cut: dict, fmt: str, placed: list[dict], settings: dict) -> pathlib.Path:
    out = RENDERS / f"your_call_trailer_{fmt}{settings['suffix']}.mp4"
    inputs, filters = graph(cut, fmt, placed, settings)
    script = RENDERS / f"graph_{fmt}{settings['suffix']}.txt"
    script.write_text(filters, encoding="utf-8", newline="\n")
    command = [ffmpeg_tool("ffmpeg"), "-v", "error", "-y", *inputs, "-/filter_complex", str(script),
               "-map", "[outv]", "-map", "[outa]",
               "-c:v", "libx264", "-preset", "slow", "-profile:v", "high", "-crf", str(settings["crf"]),
               "-maxrate", settings["maxrate"], "-bufsize", settings["bufsize"], "-pix_fmt", "yuv420p",
               "-color_range", "tv", "-colorspace", "bt709", "-color_primaries", "bt709", "-color_trc", "bt709",
               "-r", str(cut["fps"]), "-g", str(cut["fps"] * 2),
               "-c:a", "aac", "-b:a", settings["audio"], "-ar", str(SAMPLE_RATE), "-ac", "2",
               "-movflags", "+faststart", str(out)]
    result = subprocess.run(command, capture_output=True, text=True, encoding="utf-8", errors="replace")
    if result.returncode != 0:
        sys.exit(f"ffmpeg could not cut the {fmt} trailer:\n{result.stderr[-3000:]}")
    return out


def contact_sheet(video: pathlib.Path, seconds: float, columns: int) -> pathlib.Path:
    """A sheet of frames through the cut, every couple of seconds, for a look without playing it."""
    out = video.with_name(video.stem + "_sheet.png")
    step = max(seconds / 24.0, 0.5)
    rows = (int(seconds / step) + columns) // columns
    subprocess.run([ffmpeg_tool("ffmpeg"), "-v", "error", "-y", "-i", str(video), "-vf",
                    f"fps=1/{step:.3f},scale=480:-1,tile={columns}x{rows}:padding=4:color=gray", "-frames:v", "1",
                    str(out)], check=True)
    return out


def print_plan(cut: dict, fmt: str) -> None:
    fps = cut["fps"]
    print(f"\n{fmt}:")
    try:
        placed = timeline(cut, fmt)
    except SystemExit as reason:
        print(f"  (the times wait on the recordings: {reason})")
        return
    for piece in placed:
        way = " backwards" if piece.get("reverse") else ""
        fast = f" at {piece['speed']:g}x" if piece["speed"] != 1.0 else ""
        print(f"  {piece['start']:6.2f}  {piece['frames'] / fps:5.2f} s  {piece['shot']}  {piece['begin']:.2f} to {piece['end']:.2f}{way}{fast}")
    print(f"  {total_seconds(placed, fps):.2f} s in all")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--format", choices=FORMATS, help="only this trailer")
    parser.add_argument("--shots", help="record these shots again, comma separated")
    parser.add_argument("--fresh", action="store_true", help="record every shot again")
    parser.add_argument("--cut-only", action="store_true", help="cut from the recordings there are")
    parser.add_argument("--record-only", action="store_true", help="record, but do not cut")
    parser.add_argument("--draft", action="store_true", help="only a quick small encode")
    parser.add_argument("--dry-run", action="store_true", help="show the plan and stop")
    parser.add_argument("--jobs", type=int, default=4, help="how many shots record at once")
    args = parser.parse_args()

    cut = load_cut()
    formats = [args.format] if args.format else list(FORMATS)
    RENDERS.mkdir(exist_ok=True)
    (RENDERS / ".gdignore").touch()
    forced = set(args.shots.split(",")) if args.shots else set()
    unknown = forced - set(cut["shots"])
    if unknown:
        sys.exit(f"No shot called {', '.join(sorted(unknown))} in the cut.")

    for fmt in formats:
        needed = sorted({piece["shot"] for piece in pieces_for(cut, fmt)} | (forced & set(cut["shots"])))
        stale = [shot for shot in needed if args.fresh or shot in forced or not is_current(cut, fmt, shot)]
        if args.dry_run:
            print(f"{fmt}: would record {', '.join(stale) if stale else 'nothing'}")
            print_plan(cut, fmt)
            continue
        if stale and not args.cut_only:
            print(f"Recording {len(stale)} {fmt} shots, {args.jobs} at a time: {', '.join(stale)}", flush=True)
            record_format(cut, fmt, stale, args.jobs)
    if args.dry_run or args.record_only:
        return

    for fmt in formats:
        placed = timeline(cut, fmt)
        seconds = total_seconds(placed, cut["fps"])
        settings = [DRAFT] if args.draft else [DRAFT, FINAL]
        for each in settings:
            out = encode(cut, fmt, placed, each)
            print(f"wrote {out} ({seconds:.1f} s, {out.stat().st_size / 1048576:.1f} MB)", flush=True)
            if each is DRAFT:
                sheet = contact_sheet(out, seconds, 6 if fmt == "wide" else 8)
                print(f"wrote {sheet}")


if __name__ == "__main__":
    main()
