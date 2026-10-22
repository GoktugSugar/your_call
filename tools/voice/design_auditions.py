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

# The dead who confess in Chapter 7, each read with their own first line from docs/SCRIPT.md, tags
# stripped. Ordinary people, not cartoons: none sounds like the imp's New York swagger or the button's
# whine, and the two in 7.10 are equally sincere, so neither voice sounds like the liar.
CONFESSORS = {
    "recliner": (
        "I paid for that seat. The whole seat. The recline is part of the seat. It is a button, it is right "
        "there, the airline put it there for me to press.",
        [
            ("frequent_flyer",
             "A middle aged American man, a frequent flyer with a firm sense of entitlement. Mid pitch, slightly "
             "nasal, defensive and exasperated, explaining what he thinks is obvious. Natural, conversational. "
             "Perfect audio quality."),
            ("clipped_executive",
             "A brisk, self assured English businessman in his fifties. Clipped, impatient and condescending, "
             "as if arguing with a flight attendant. Natural pace. Perfect audio quality."),
            ("stubborn_midwesterner",
             "A gruff, stubborn American man in his sixties from the Midwest. Low and grumbling, folksy and "
             "immovable, certain he is in the right. Unhurried. Perfect audio quality."),
        ]),
    "wedding": (
        "It was cream. And she knew exactly what she was doing when she sat me at the very back table, next "
        "to her ghastly uncle. This was years in the making. She started it.",
        [
            ("catty_thirties",
             "A sharp, catty American woman in her thirties. Bright and confident, a little sing song, "
             "defensive with a sly edge of pride. Natural, conversational. Perfect audio quality."),
            ("haughty_english",
             "A glamorous, haughty English woman in her forties. Smooth, arch and theatrical, wounded pride "
             "under a polished surface. Perfect audio quality."),
            ("sweet_southern",
             "A fiery woman in her late twenties with a Southern American accent. Quick and indignant, sweetly "
             "vicious. Perfect audio quality."),
        ]),
    "loan": (
        "I carried him for a year. A whole year. And not one thank you, not one honest word about it, just "
        "excuses and, I noticed, a brand new phone.",
        [
            ("simmering_brother",
             "A tightly wound American man in his forties. Mid low pitch, measured but simmering with "
             "resentment, self righteous. Natural, conversational. Perfect audio quality."),
            ("blunt_northerner",
             "A blunt man in his fifties with a Northern English accent. Plain spoken and stubborn, hurt "
             "underneath, never raises his voice. Perfect audio quality."),
            ("aggrieved_aussie",
             "An earnest, aggrieved Australian man in his late thirties. A warm voice gone bitter, talking fast "
             "when he defends himself. Perfect audio quality."),
        ]),
    "secret": (
        "If I said something and I was wrong, I lose her forever. If I said something and I was right, I am "
        "the one who detonated her whole life.",
        [
            ("quiet_guilt",
             "A soft spoken American woman in her thirties. Quiet, anxious and guilty, choosing her words "
             "carefully, close to tears but holding together. Perfect audio quality."),
            ("weary_irish",
             "A gentle Irish woman in her forties. Warm and low, weary with regret, slow and sincere. Perfect "
             "audio quality."),
            ("nervous_english",
             "A tense young English woman in her twenties. Breathy, nervous and defensive, her words tumbling "
             "out. Perfect audio quality."),
        ]),
    "promise": (
        "She made me promise while she was already going. What was I supposed to say. No? You do not argue "
        "with a dying woman. You say yes, and you mean it, and I did mean it, I swear I did.",
        [
            ("worn_father",
             "A tired working class American man in his forties. Low and rough, grieving and sincere, his voice "
             "catching. Natural pace. Perfect audio quality."),
            ("soft_scot",
             "A gentle Scottish man in his fifties. Soft, heavy with grief and guilt, plain spoken. Perfect "
             "audio quality."),
            ("strained_young_dad",
             "A worn out young father in his thirties, neutral American accent. Quiet and strained, pleading to "
             "be understood. Perfect audio quality."),
        ]),
    "favorite": (
        "You want to know the last honest thing they ever said to me. They told me they wished I had more of "
        "my brother in me. I was twelve years old.",
        [
            ("cold_daughter",
             "A woman in her forties, neutral American accent. Calm and cold on the surface, decades of hurt "
             "underneath, bitter and precise. Perfect audio quality."),
            ("controlled_son",
             "A man in his forties with a soft English accent. Quiet and controlled, bitter, a hurt that never "
             "healed. Perfect audio quality."),
            ("husky_guarded",
             "A woman in her late thirties with a low, husky voice. Flat, guarded and wounded, every word "
             "deliberate. Perfect audio quality."),
        ]),
    "good_deed": (
        "He would be dead. Do you understand that. Dead, in the ground, twenty years now, if I had not gone "
        "in after him.",
        [
            ("proud_rescuer",
             "A big hearted, boastful American man in his fifties. Loud and warm, proud of himself, wounded that "
             "he is not appreciated. Perfect audio quality."),
            ("pompous_english",
             "A pompous English man in his sixties. Plummy, indignant and self important, lecturing. Perfect "
             "audio quality."),
            ("brash_bostonian",
             "A barrel chested man in his forties with a Boston accent. Brash and aggrieved, talking with his "
             "hands. Perfect audio quality."),
        ]),
    "whistle": (
        "What he did was real. I did not invent it, I did not stretch it, I reported exactly what happened "
        "and it was bad.",
        [
            ("firm_professional",
             "A precise, intense American woman in her thirties. Controlled and articulate, shaken but firm, "
             "anger held in. Perfect audio quality."),
            ("dignified_londoner",
             "A tired, dignified woman in her forties with a London accent. Measured and hurt, quietly furious. "
             "Perfect audio quality."),
            ("earnest_canadian",
             "A young professional woman in her late twenties with a Canadian accent. Earnest and frustrated, "
             "her voice tight with disbelief. Perfect audio quality."),
        ]),
    "her": (
        "I told him one thing. One. The single worst thing I have ever done, a thing I never breathed to "
        "another living soul, and I told him because he was my best friend.",
        [
            ("raw_betrayed",
             "A woman in her thirties, neutral American accent. Raw and emotional, betrayed, sincere, on the "
             "edge of tears. Perfect audio quality."),
            ("trembling_welsh",
             "A woman in her forties with a soft Welsh accent. Hurt and accusing, her voice trembling. Perfect "
             "audio quality."),
            ("fierce_english",
             "A young woman in her twenties with an English accent. Fierce, wounded and intense. Perfect audio "
             "quality."),
        ]),
    "him": (
        "That is not what happened. She told me that secret, yes. And then she told other people herself, "
        "drunk, at a party, and panicked in the morning, and needed a body to pin it on.",
        [
            ("steady_sad",
             "A man in his thirties, neutral American accent. Calm, steady and sad, quietly insistent and "
             "sincere. Perfect audio quality."),
            ("gentle_irish",
             "A man in his forties with a soft Irish accent. Gentle and wounded, patient, resigned. Perfect "
             "audio quality."),
            ("earnest_english",
             "A young man in his twenties with an English accent. Earnest, frustrated and hurt, trying to stay "
             "calm. Perfect audio quality."),
        ]),
}

# Who can be auditioned: the text their candidates read, and the candidates, each a slug and a description.
# A role with several voices, such as the confessors, names each as role.voice; --speaker confessor
# auditions them all.
AUDITIONS = {
    "imp": (IMP_TEXT, IMP_CANDIDATES),
    "button": (BUTTON_TEXT, BUTTON_CANDIDATES),
    **{f"confessor.{name}": audition for name, audition in CONFESSORS.items()},
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
    parser.add_argument("--speaker", default="imp", help="who the voice is for: " + ", ".join(sorted(AUDITIONS))
                        + ", or a role such as confessor for all of its voices")
    parser.add_argument("--out", type=pathlib.Path, default=DEFAULT_OUT, help="folder for the previews")
    parser.add_argument("--only", nargs="*", help="slugs of the candidates to design, default all")
    parser.add_argument("--dry-run", action="store_true", help="list what would be designed and what it spends")
    args = parser.parse_args()
    roles = [role for role in AUDITIONS if role == args.speaker or role.startswith(args.speaker + ".")]
    if not roles:
        sys.exit(f"No auditions for {args.speaker}. Known: {', '.join(sorted(AUDITIONS))}")
    wanted = set(args.only) if args.only else None
    plan = []
    for role in roles:
        text, candidates = AUDITIONS[role]
        chosen = [(number, slug, description) for number, (slug, description) in enumerate(candidates, start=1)
                  if wanted is None or slug in wanted]
        if chosen:
            plan.append((role, text, chosen))
    if args.dry_run:
        for role, text, chosen in plan:
            for number, slug, _description in chosen:
                print(f"{role}_{number:02d}_{slug} reads {len(text)} characters")
        designs = sum(len(chosen) for _role, _text, chosen in plan)
        print(f"{designs} designs: {sum(len(text) * len(chosen) for _role, text, chosen in plan)} characters")
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
    for role, text, chosen in plan:
        audition(role, text, chosen, key, args.out)
    print(f"Saved to {args.out}")


def audition(role: str, text: str, chosen: list[tuple[int, str, str]], key: str, out: pathlib.Path) -> None:
    """Designs each chosen candidate for role, keeps all of its takes, and records them in role's index."""
    index_path = out / f"{role}_auditions.json"
    index = json.loads(index_path.read_text(encoding="utf-8")) if index_path.exists() else {"text": text, "candidates": []}
    for number, slug, description in chosen:
        result, model = design(description, text, key, MODELS)
        for take, preview in enumerate(result["previews"], start=1):
            take_slug = slug if take == 1 else f"{slug}_{take}"
            extension = "wav" if "wav" in preview.get("media_type", "") else "mp3"
            path = out / f"{role}_{number:02d}_{take_slug}.{extension}"
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
        # Written after every design, so a failure part way keeps what was already paid for.
        index["candidates"].sort(key=lambda c: (c["number"], c.get("take", 1)))
        index_path.write_text(json.dumps(index, indent=2), encoding="utf-8", newline="\n")


if __name__ == "__main__":
    main()
