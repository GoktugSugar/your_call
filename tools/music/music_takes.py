"""Takes of a piece of music from ElevenLabs (Eleven Music), to choose one by ear.

    python tools/music/music_takes.py trailer_bed --dry-run   # its sections, and what a batch would cost
    python tools/music/music_takes.py trailer_bed             # a batch of takes in music_auditions/trailer_bed/
    python tools/music/music_takes.py trailer_bed --save 2    # take 2 becomes the piece the trailer plays

What each piece asks for is in music.json beside this script: the model, and its sections in order, each
with how long it runs, what it is (a section name in square brackets, no lyrics, so it stays
instrumental), the styles it should have and the styles it should not. The sections are timed to the
places in the trailer they play under. Takes are scratch audio, kept out of git; a new batch is numbered
on from the last. Music costs about 900 credits a minute. The key comes from the ELEVENLABS_API_KEY
environment variable or .env at the project root, and is never printed.
"""

import argparse
import json
import pathlib
import shutil
import sys
import urllib.error
import urllib.request

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1] / "voice"))
from elevenlabs import API, ROOT, TIMEOUT_SECONDS, ApiError, api_key  # noqa: E402

PIECES = pathlib.Path(__file__).with_name("music.json")
AUDITIONS = ROOT / "music_auditions"
# The plan's own quality: the Creator plan's downloads stop at 128 kbps.
OUTPUT_FORMAT = "mp3_44100_128"
CREDITS_PER_MINUTE = 900


def body(piece: dict) -> dict:
    chunks = []
    for section in piece["sections"]:
        chunk = {
            "text": section["text"],
            "duration_ms": int(round(section["seconds"] * 1000)),
            "positive_styles": section["styles"] + piece.get("styles", []),
        }
        avoid = section.get("avoid", []) + piece.get("avoid", [])
        if avoid:
            chunk["negative_styles"] = avoid
        chunks.append(chunk)
    return {"composition_plan": {"chunks": chunks}, "model_id": piece.get("model", "music_v2_5")}


def generate(piece: dict, key: str) -> bytes:
    req = urllib.request.Request(
        f"{API}/music?output_format={OUTPUT_FORMAT}",
        data=json.dumps(body(piece)).encode("utf-8"),
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


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("piece", help="the piece's name in music.json")
    parser.add_argument("--save", type=int, metavar="TAKE", help="make this take the piece the trailer plays")
    parser.add_argument("--takes", type=int, help="how many takes to make, in place of the piece's own count")
    parser.add_argument("--dry-run", action="store_true", help="show what would be asked for and stop")
    args = parser.parse_args()

    pieces = {name: piece for name, piece in json.loads(PIECES.read_text(encoding="utf-8")).items()
              if isinstance(piece, dict)}
    if args.piece not in pieces:
        sys.exit(f"No piece called {args.piece} in {PIECES.name}. There are: {', '.join(sorted(pieces))}")
    piece = pieces[args.piece]

    if args.save is not None:
        take = take_path(args.piece, args.save)
        if not take.exists():
            sys.exit(f"No take {take.relative_to(ROOT)}")
        target = ROOT / piece["file"]
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(take, target)
        print(f"{take.relative_to(ROOT)} is now {piece['file']}")
        return

    takes = args.takes or piece.get("takes", 1)
    seconds = sum(section["seconds"] for section in piece["sections"])
    print(f"{args.piece}: {takes} takes of {seconds:.1f} s with {piece.get('model', 'music_v2_5')}, "
          f"about {round(takes * seconds / 60 * CREDITS_PER_MINUTE)} credits")
    for section in piece["sections"]:
        print(f"  {section['seconds']:5.1f} s  {section['text']}: {', '.join(section['styles'])}")
    if args.dry_run:
        print(json.dumps(body(piece), indent=2))
        return
    key = api_key()
    folder = AUDITIONS / args.piece
    folder.mkdir(parents=True, exist_ok=True)
    first = 1 + len(list(folder.glob(f"{args.piece}_*.mp3")))
    for number in range(first, first + takes):
        path = take_path(args.piece, number)
        path.write_bytes(generate(piece, key))
        print(f"  {path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
