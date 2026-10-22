"""Takes of a sound effect from ElevenLabs, to choose one by ear.

    python tools/sfx/sound_takes.py gunshot --dry-run   # what it would ask for
    python tools/sfx/sound_takes.py gunshot             # a batch of takes in sfx_auditions/gunshot/
    python tools/sfx/sound_takes.py gunshot --save 2    # take 2 becomes the game's gunshot

What each sound asks for (its description, length, how many takes and where the chosen one goes) is in
sounds.json beside this script. Takes are scratch audio, kept out of git; a new batch is numbered on
from the last. The key comes from the ELEVENLABS_API_KEY environment variable or .env at the project
root, and is never printed.
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

SOUNDS = pathlib.Path(__file__).with_name("sounds.json")
AUDITIONS = ROOT / "sfx_auditions"
OUTPUT_FORMAT = "mp3_44100_128"


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


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("sound", help="the sound's name in sounds.json")
    parser.add_argument("--save", type=int, metavar="TAKE", help="make this take the game's sound")
    parser.add_argument("--dry-run", action="store_true", help="show what would be asked for and stop")
    args = parser.parse_args()

    sounds = {name: sound for name, sound in json.loads(SOUNDS.read_text(encoding="utf-8")).items()
              if isinstance(sound, dict)}
    if args.sound not in sounds:
        sys.exit(f"No sound called {args.sound} in {SOUNDS.name}. There are: {', '.join(sorted(sounds))}")
    sound = sounds[args.sound]

    if args.save is not None:
        take = take_path(args.sound, args.save)
        if not take.exists():
            sys.exit(f"No take {take.relative_to(ROOT)}")
        target = ROOT / sound["file"]
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(take, target)
        print(f"{take.relative_to(ROOT)} is now {sound['file']}")
        return

    print(f"{args.sound}: {sound['takes']} takes of {sound['seconds']} s, influence {sound['influence']}")
    print(f"  {sound['prompt']}")
    if args.dry_run:
        return
    key = api_key()
    folder = AUDITIONS / args.sound
    folder.mkdir(parents=True, exist_ok=True)
    first = 1 + len(list(folder.glob(f"{args.sound}_*.mp3")))
    for number in range(first, first + sound["takes"]):
        path = take_path(args.sound, number)
        path.write_bytes(generate(sound, key))
        print(f"  {path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
