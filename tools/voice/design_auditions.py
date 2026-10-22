"""Design candidate voices for a speaker with ElevenLabs Voice Design, and save every preview of each.

Every candidate for a speaker reads the same lines, so they can be compared side by side. A design is
charged by the characters of the text it reads and comes back as three takes, so all three are kept:
the first under the candidate's slug, the others as <slug>_2 and <slug>_3. The takes and an index of
what made them (description, generated voice id, model) go to voice_auditions/ at the project root,
which git and Godot both ignore. A chosen take can later be saved as a permanent voice from its
generated voice id, with save_voice.py.

    python tools/voice/design_auditions.py                              the imp's candidates
    python tools/voice/design_auditions.py --speaker button --dry-run   what the button's would spend
    python tools/voice/design_auditions.py --speaker button --only prissy_clerk

The ElevenLabs key comes from the ELEVENLABS_API_KEY environment variable, or from .env at the
project root. It is never printed or written anywhere else.
"""

import argparse
import base64
import json
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from elevenlabs import ROOT, ApiError, api_key, request  # noqa: E402

DEFAULT_OUT = ROOT / "voice_auditions"
MODELS = ["eleven_ttv_v3", "eleven_multilingual_ttv_v2"]

# The imp's first two lines of the game, tags stripped, read by every candidate.
IMP_TEXT = (
    "Oh, you are awake. Do not thank me, and do not ask where here is, because I will not tell you "
    "and you would not much enjoy the answer. You are dead. That part is not up for appeal. You steered "
    "a car into the next world with a skinful of wine in you, Your Honour, and now you are on the wrong "
    "side of the bench for once."
)

# Variations on the voice brief in docs/PREMISE.md section 14: a small devil with a big personality,
# gleeful, quick, theatrical and delighted with himself, lower and warmer than a squeaky goblin.
IMP_CANDIDATES = [
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

# The walking button's two lines in 2.11, and one sentence more for the audition alone: Voice Design
# reads no fewer than 100 characters.
BUTTON_TEXT = (
    "Ow! Fuck. That actually hurt, you absolute prick. Unbelievable. I did nothing to you. Nothing. "
    "I was just sitting there, minding my own business."
)

# Small, put out and easily offended, swearing as written (docs/DECISIONS.md, the Chapter 2 check-in).
# Each is a different kind of small, and none sounds like the imp's low New York swagger.
BUTTON_CANDIDATES = [
    ("prissy_clerk",
     "A small, fussy, easily offended little thing that has just come to life. Adult male, light and fairly "
     "high but not squeaky, a little nasal, crisp English accent. Huffy and indignant, like a petty clerk "
     "whose stapler was moved. Clipped, wounded delivery with sharp gasps. Perfect audio quality."),
    ("scrappy_tough",
     "A tiny tough guy with a very short fuse. Small, scrappy adult male voice, higher than average with a "
     "gravelly edge, broad London accent. Put out and quick to take offence, swears with real feeling. "
     "Fast, huffy delivery. Perfect audio quality."),
    ("wounded_whiner",
     "A small, whiny, deeply wounded voice. Young adult male, high but never childlike, wobbling with outrage "
     "and close to tears. Melodramatic and sniffy, feels terribly hard done by. Neutral American accent. "
     "Perfect audio quality."),
    ("prim_auntie",
     "A small, prim and thoroughly offended woman. Light, high, clipped voice, middle aged, refined English "
     "accent. Scandalised and put out, with sharp intakes of breath, and she swears with crisp disgust. "
     "Perfect audio quality."),
    ("squeaky_crank",
     "A tiny, squeaky, cranky little creature. High, small and pinched, like a cartoon gremlin with a grudge, "
     "gruff despite its size. Outraged and grumbling, swearing under its breath. Perfect audio quality."),
]

# Who can be auditioned: the text their candidates read, and the candidates, each a slug and a description.
AUDITIONS = {
    "imp": (IMP_TEXT, IMP_CANDIDATES),
    "button": (BUTTON_TEXT, BUTTON_CANDIDATES),
}


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
    parser.add_argument("--speaker", default="imp", choices=sorted(AUDITIONS), help="who the voice is for")
    parser.add_argument("--out", type=pathlib.Path, default=DEFAULT_OUT, help="folder for the previews")
    parser.add_argument("--only", nargs="*", help="slugs of the candidates to design, default all")
    parser.add_argument("--dry-run", action="store_true", help="list what would be designed and what it spends")
    args = parser.parse_args()
    text, candidates = AUDITIONS[args.speaker]
    wanted = set(args.only) if args.only else None
    chosen = [(number, slug, description) for number, (slug, description) in enumerate(candidates, start=1)
              if wanted is None or slug in wanted]
    if args.dry_run:
        for number, slug, _description in chosen:
            print(f"{args.speaker}_{number:02d}_{slug}")
        print(f"{len(chosen)} designs reading {len(text)} characters each: {len(chosen) * len(text)} characters")
        return
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
    index_path = args.out / f"{args.speaker}_auditions.json"
    index = json.loads(index_path.read_text(encoding="utf-8")) if index_path.exists() else {"text": text, "candidates": []}
    for number, slug, description in chosen:
        result, model = design(description, text, key, MODELS)
        for take, preview in enumerate(result["previews"], start=1):
            take_slug = slug if take == 1 else f"{slug}_{take}"
            extension = "wav" if "wav" in preview.get("media_type", "") else "mp3"
            path = args.out / f"{args.speaker}_{number:02d}_{take_slug}.{extension}"
            path.write_bytes(base64.b64decode(preview["audio_base_64"]))
            index["candidates"] = [c for c in index["candidates"] if c["slug"] != take_slug]
            index["candidates"].append({
                "number": number,
                "take": take,
                "slug": take_slug,
                "file": path.name,
                "description": description,
                "model": model,
                "generated_voice_id": preview.get("generated_voice_id"),
                "duration_secs": preview.get("duration_secs"),
            })
            print(f"{path.name}: {preview.get('duration_secs', '?')} s, model {model}")
    index["candidates"].sort(key=lambda c: (c["number"], c.get("take", 1)))
    index_path.write_text(json.dumps(index, indent=2), encoding="utf-8", newline="\n")
    print(f"Saved to {args.out}")


if __name__ == "__main__":
    main()
