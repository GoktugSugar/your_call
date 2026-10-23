"""Exports the browser build, ready to upload to itch.io.

    python tools/web/export_web.py               # builds/web, and builds/your_call_web.zip to upload
    python tools/web/export_web.py --dry-run     # what would go where, without exporting

The browser build would otherwise load every voice clip before its menu: well over a hundred
megabytes. Instead it carries the voice of the menu and the first chapter, and every later chapter's
voice goes into a pack of its own beside it (voice/<chapter>.bin, listed in voice/packs.json), which the
game fetches in the background while the player plays ([VoicePacks]). This exports the build with the
"Web" preset, leaving the later chapters' voice out, then each chapter's pack through a preset made for
the moment and taken away again, and zips the lot. Needs Godot's export templates; the Windows build
needs none of this and is exported as it is. Standard library only.
"""

import argparse
import json
import pathlib
import re
import shutil
import subprocess
import sys
import zipfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
GODOT = pathlib.Path("C:/Program Files/Godot/Godot_Console.exe")
PRESETS = ROOT / "export_presets.cfg"
MANIFEST = ROOT / "assets" / "voice" / "manifest.json"
# The chapters whose voice the build carries itself: the menu's barks and the first chapter's lines.
CARRIED = ["menu", "ch1"]
# itch.io's limits on a browser game, by its HTML5 docs.
MOST_FILES = 1000
LARGEST_FILE = 200 * 1024 * 1024
LARGEST_TOTAL = 500 * 1024 * 1024


def run_order() -> list[str]:
    run = json.loads((ROOT / "content" / "run.json").read_text(encoding="utf-8"))
    order = []
    for file in run["chapters"]:
        chapter = json.loads((ROOT / "content" / "chapters" / file).read_text(encoding="utf-8"))
        order.append(chapter["id"])
    return order


def voice_by_chapter() -> dict[str, list[str]]:
    """Every voice file, its audio and its timings, grouped by the chapter its line is in."""
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    grouped: dict[str, list[str]] = {}
    for line_id, entry in manifest.items():
        files = [entry[key] for key in ("audio", "timing") if entry.get(key)]
        grouped.setdefault(line_id.split(".", 1)[0], []).extend(files)
    return grouped


def section(text: str, name: str) -> tuple[int, int]:
    """Where the preset called [name] and its options sit in [text], as a span."""
    starts = [m.start() for m in re.finditer(r"^\[preset\.\d+\]$", text, re.M)] + [len(text)]
    for i, start in enumerate(starts[:-1]):
        if f'\nname="{name}"\n' in text[start:starts[i + 1]]:
            return start, starts[i + 1]
    sys.exit(f'No preset called "{name}" in {PRESETS.name}')


def export(kind: str, preset: str, target: pathlib.Path) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    done = subprocess.run([str(GODOT), "--headless", "--path", str(ROOT), kind, preset, str(target)],
                          capture_output=True, text=True)
    if done.returncode != 0 or not target.exists():
        sys.exit(f"Exporting {target.name} failed:\n{done.stdout[-2000:]}\n{done.stderr[-2000:]}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--out", type=pathlib.Path, default=ROOT / "builds" / "web")
    parser.add_argument("--zip", type=pathlib.Path, default=ROOT / "builds" / "your_call_web.zip")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    order = run_order()
    voice = voice_by_chapter()
    packed = [chapter for chapter in order if chapter not in CARRIED and voice.get(chapter)]
    carried_mb = sum((ROOT / f.removeprefix("res://")).stat().st_size for c in CARRIED for f in voice.get(c, [])) / 1048576
    print(f"The build carries the voice of {', '.join(CARRIED)} ({carried_mb:.1f} MB); packs for " + ", ".join(
        f"{c} ({sum((ROOT / f.removeprefix('res://')).stat().st_size for f in voice[c]) / 1048576:.1f} MB)" for c in packed))
    if args.dry_run:
        return

    # The builds sit inside the project, so Godot is told to leave them alone.
    (ROOT / "builds").mkdir(exist_ok=True)
    (ROOT / "builds" / ".gdignore").touch()
    kept = PRESETS.read_text(encoding="utf-8")
    try:
        # The build, leaving out every packed chapter's voice.
        start, end = section(kept, "Web")
        web = kept[start:end]
        leave_out = ", ".join(f"assets/voice/*/{chapter}.*" for chapter in packed)
        web = re.sub(r'^exclude_filter="(.*)"$', lambda m: f'exclude_filter="{m.group(1)}, {leave_out}"', web, count=1, flags=re.M)
        PRESETS.write_text(kept[:start] + web + kept[end:], encoding="utf-8", newline="\n")
        if args.out.exists():
            shutil.rmtree(args.out)
        print("exporting the build", flush=True)
        export("--export-release", "Web", args.out / "index.html")
        # A pack per chapter, through a preset of only that chapter's voice.
        number = len(re.findall(r"^\[preset\.\d+\]$", kept, re.M))
        for chapter in packed:
            files = ", ".join(f'"{f}"' for f in voice[chapter])
            pack = re.sub(r"^\[preset\.\d+\]$", f"[preset.{number}]", kept[start:end], count=1, flags=re.M)
            pack = re.sub(r"^\[preset\.\d+\.options\]$", f"[preset.{number}.options]", pack, count=1, flags=re.M)
            pack = re.sub(r'^name=".*"$', 'name="Web voice"', pack, count=1, flags=re.M)
            pack = re.sub(r'^export_filter=".*"$', f'export_filter="resources"\nexport_files=PackedStringArray({files})', pack, count=1, flags=re.M)
            pack = re.sub(r'^exclude_filter=".*"$', 'exclude_filter=""', pack, count=1, flags=re.M)
            PRESETS.write_text(kept + "\n" + pack, encoding="utf-8", newline="\n")
            print(f"exporting the voice of {chapter}", flush=True)
            export("--export-pack", "Web voice", args.out / "voice" / f"{chapter}.pck")
            # Renamed .bin: itch's CDN gzips a .pck, and a browser fetching it gzipped stops short.
            (args.out / "voice" / f"{chapter}.pck").rename(args.out / "voice" / f"{chapter}.bin")
    finally:
        PRESETS.write_text(kept, encoding="utf-8", newline="\n")
    (args.out / "voice" / "packs.json").write_text(json.dumps(packed), encoding="utf-8", newline="\n")

    files = [f for f in args.out.rglob("*") if f.is_file()]
    total = sum(f.stat().st_size for f in files)
    largest = max(files, key=lambda f: f.stat().st_size)
    print(f"{len(files)} files, {total / 1048576:.1f} MB in all; the largest is {largest.name}, "
          f"{largest.stat().st_size / 1048576:.1f} MB; index.pck {(args.out / 'index.pck').stat().st_size / 1048576:.1f} MB")
    if len(files) > MOST_FILES or largest.stat().st_size > LARGEST_FILE or total > LARGEST_TOTAL:
        sys.exit("Over itch.io's limits for a browser game.")
    with zipfile.ZipFile(args.zip, "w", zipfile.ZIP_DEFLATED) as bundle:
        for file in files:
            bundle.write(file, file.relative_to(args.out).as_posix())
    print(f"Upload {args.zip.relative_to(ROOT).as_posix()} to itch.io as the browser build.")


if __name__ == "__main__":
    main()
