"""Save a designed audition as a permanent ElevenLabs voice, and record it in tools/voice/voices.json.

    python tools/voice/save_voice.py <role> <audition slug>
    python tools/voice/save_voice.py imp wiseguy_barker

<role> is who the voice is for in the game, such as imp. The audition comes from
voice_auditions/imp_auditions.json, written by design_auditions.py.
"""

import argparse
import json
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from design_auditions import DEFAULT_OUT  # noqa: E402
from elevenlabs import ApiError, api_key, request  # noqa: E402

VOICES = pathlib.Path(__file__).resolve().parent / "voices.json"
VOICE_NAME = "Your Call: {role} ({slug})"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("role")
    parser.add_argument("slug")
    args = parser.parse_args()

    index = json.loads((DEFAULT_OUT / "imp_auditions.json").read_text(encoding="utf-8"))
    candidate = next((c for c in index["candidates"] if c["slug"] == args.slug), None)
    if candidate is None:
        sys.exit(f"No audition called {args.slug}.")
    body = {
        "voice_name": VOICE_NAME.format(role=args.role, slug=args.slug),
        "voice_description": candidate["description"],
        "generated_voice_id": candidate["generated_voice_id"],
    }
    key = api_key()
    try:
        voice = request("POST", "/text-to-voice", key, body)
    except ApiError as error:
        if error.status != 404:
            raise
        voice = request("POST", "/text-to-voice/create-voice-from-preview", key, body)

    voices = json.loads(VOICES.read_text(encoding="utf-8")) if VOICES.exists() else {}
    voices[args.role] = {
        "voice_id": voice["voice_id"],
        "name": body["voice_name"],
        "description": candidate["description"],
        "designed_with": candidate["model"],
    }
    VOICES.write_text(json.dumps(voices, indent=2) + "\n", encoding="utf-8", newline="\n")
    print(f"Saved {body['voice_name']} as voice {voice['voice_id']}, recorded in {VOICES.name}")


if __name__ == "__main__":
    main()
