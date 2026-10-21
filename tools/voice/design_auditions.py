"""Design candidate voices for the imp with ElevenLabs Voice Design, and save one preview of each.

Every candidate reads the same lines, so they can be compared side by side. The previews and an
index of what made them (description, generated voice id, model) go to voice_auditions/ at the
project root, which git and Godot both ignore. A chosen candidate can later be saved as a permanent
voice from its generated voice id.

    python tools/voice/design_auditions.py

The ElevenLabs key comes from the ELEVENLABS_API_KEY environment variable, or from .env at the
project root. It is never printed or written anywhere else.
"""

import argparse
import base64
import json
import os
import pathlib
import sys
import urllib.error
import urllib.request

API = "https://api.elevenlabs.io/v1"
ROOT = pathlib.Path(__file__).resolve().parents[2]
DEFAULT_OUT = ROOT / "voice_auditions"
MODELS = ["eleven_ttv_v3", "eleven_multilingual_ttv_v2"]

# The imp's first two lines of the game, tags stripped, read by every candidate.
SAMPLE_TEXT = (
    "Oh, you are awake. Do not thank me, and do not ask where here is, because I will not tell you "
    "and you would not much enjoy the answer. You are dead. That part is not up for appeal. You steered "
    "a car into the next world with a skinful of wine in you, Your Honour, and now you are on the wrong "
    "side of the bench for once."
)

# Variations on the voice brief in docs/PREMISE.md section 14: a small devil with a big personality,
# gleeful, quick, theatrical and delighted with himself, lower and warmer than a squeaky goblin.
CANDIDATES = [
    ("british_showman",
     "A mischievous little devil with a big personality. Adult male, British accent, medium low and warm "
     "pitch. Gleeful, theatrical and smug, like a delighted game show host savouring a cruel joke. Quick, "
     "crisp delivery with playful emphasis. Never squeaky. Perfect audio quality."),
    ("gravel_trickster",
     "A sly old trickster demon. Raspy, gravelly middle aged male voice, low and warm, with a wicked chuckle "
     "under every line. Conspiratorial and amused, enjoying himself far too much. Unhurried, intimate "
     "delivery. Neutral accent. Perfect audio quality."),
    ("silky_needler",
     "A polished, smug tormentor. Smooth, silky baritone male voice, velvety and amused, with a faint sneer. "
     "Refined English accent. Needles slowly and savours every word, quietly mocking, never angry. Measured "
     "pace. Perfect audio quality."),
    ("quick_imp",
     "An impish, quick witted devil bouncing with glee. Young adult male, mid pitch but never high, "
     "slightly nasal edge, American accent. Fast talking with sharp comic timing and playful sarcasm, "
     "grinning through every line. Perfect audio quality."),
    ("wiseguy_barker",
     "A wry little devil with a carnival barker's swagger. Male, mid low pitch, New York flavour, fast and "
     "punchy, mocking and gleeful, like a bookie egging on a stupid bet. Big personality, theatrical "
     "flourishes. Perfect audio quality."),
]


def api_key() -> str:
    key = os.environ.get("ELEVENLABS_API_KEY", "").strip()
    env_file = ROOT / ".env"
    if not key and env_file.exists():
        for line in env_file.read_text(encoding="utf-8").splitlines():
            name, _, value = line.partition("=")
            if name.strip() == "ELEVENLABS_API_KEY":
                key = value.strip().strip('"').strip("'")
    if not key:
        sys.exit("No ELEVENLABS_API_KEY in the environment or in .env at the project root.")
    return key


class ApiError(Exception):
    def __init__(self, status: int, body: str):
        super().__init__(f"HTTP {status}: {body[:600]}")
        self.status = status
        self.body = body


def request(method: str, path: str, key: str, body: dict | None = None) -> dict:
    data = json.dumps(body).encode("utf-8") if body is not None else None
    req = urllib.request.Request(API + path, data=data, method=method, headers={
        "xi-api-key": key,
        "Content-Type": "application/json",
        "Accept": "application/json",
    })
    try:
        with urllib.request.urlopen(req, timeout=180) as response:
            return json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as error:
        raise ApiError(error.code, error.read().decode("utf-8", "replace")) from None


def design(description: str, text: str, key: str, models: list[str]) -> tuple[dict, str]:
    """Designs voices for a description. Tries each model in turn, and the older endpoint if needed."""
    last: ApiError | None = None
    for model in models:
        body = {"voice_description": description, "text": text, "model_id": model, "auto_generate_text": False}
        try:
            return request("POST", "/text-to-voice/design", key, body), model
        except ApiError as error:
            last = error
            if error.status == 404:
                break
            if error.status in (400, 422) and "model" in error.body.lower():
                continue
            raise
    if last is not None and last.status == 404:
        body = {"voice_description": description, "text": text, "auto_generate_text": False}
        return request("POST", "/text-to-voice/create-previews", key, body), "create-previews"
    raise last if last else RuntimeError("no model to try")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--out", type=pathlib.Path, default=DEFAULT_OUT, help="folder for the previews")
    parser.add_argument("--only", nargs="*", help="slugs of the candidates to design, default all")
    args = parser.parse_args()
    key = api_key()

    try:
        subscription = request("GET", "/user/subscription", key)
        used, limit = subscription.get("character_count"), subscription.get("character_limit")
        print(f"ElevenLabs account ok: {used} of {limit} characters used this period, tier {subscription.get('tier')}")
    except ApiError as error:
        if error.status != 401:
            raise
        print("This key cannot read the account's usage, so skipping that check.")

    args.out.mkdir(parents=True, exist_ok=True)
    (args.out / ".gdignore").touch()
    index_path = args.out / "imp_auditions.json"
    index = json.loads(index_path.read_text(encoding="utf-8")) if index_path.exists() else {"text": SAMPLE_TEXT, "candidates": []}
    wanted = set(args.only) if args.only else None
    for number, (slug, description) in enumerate(CANDIDATES, start=1):
        if wanted is not None and slug not in wanted:
            continue
        result, model = design(description, SAMPLE_TEXT, key, MODELS)
        preview = result["previews"][0]
        extension = "wav" if "wav" in preview.get("media_type", "") else "mp3"
        path = args.out / f"imp_{number:02d}_{slug}.{extension}"
        path.write_bytes(base64.b64decode(preview["audio_base_64"]))
        index["candidates"] = [c for c in index["candidates"] if c["slug"] != slug]
        index["candidates"].append({
            "number": number,
            "slug": slug,
            "file": path.name,
            "description": description,
            "model": model,
            "generated_voice_id": preview.get("generated_voice_id"),
            "duration_secs": preview.get("duration_secs"),
        })
        print(f"{path.name}: {preview.get('duration_secs', '?')} s, model {model}")
    index["candidates"].sort(key=lambda c: c["number"])
    index_path.write_text(json.dumps(index, indent=2), encoding="utf-8")
    print(f"Saved to {args.out}")


if __name__ == "__main__":
    main()
