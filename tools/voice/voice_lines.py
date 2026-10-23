"""Voice the game's lines with ElevenLabs: one take per line, with the time each character is spoken.

    python tools/voice/voice_lines.py              voice every line that is missing or out of date
    python tools/voice/voice_lines.py --dry-run    list what would be voiced, and how many characters
    python tools/voice/voice_lines.py --only ch1.lever
    python tools/voice/voice_lines.py --force      voice again even lines that are up to date
    python tools/voice/voice_lines.py --prune      also delete clips whose lines are gone
    python tools/voice/voice_lines.py --fix-starts time the first word of takes led by a direction again

Godot exports the lines from content (dev/export_voice_lines.gd), so line ids are built in one place.
A line is voiced when its voice has an entry in voices.json, which also sets the model, its settings,
and an optional "direction": a v3 stage direction such as "[rapid-fire]" said before every line to
shape the delivery. A line's voice is its speaker's, such as "imp", or for a speaker with several
voices the speaker's and its own, such as "confessor.recliner". The direction is not spoken and its timings are dropped. Its clip goes to
assets/voice/<speaker>/<line id>.mp3, with <line id>.json beside it holding the timings, and
assets/voice/manifest.json records the text and voice settings each clip was made from. A clip is
out of date when either changes. The game plays a clip only while its line's text still matches.

v3 times a direction's characters over the first moments of the take, which are already the line's
first word, so that word comes back timed late and squeezed, and the game, which starts a page where
its first character is timed, would skip the start of it. A take led by a direction has its first word
timed again from its sound (which needs ffmpeg on the path); --fix-starts does the same for the takes
made before.
"""

import argparse
import array
import base64
import hashlib
import json
import math
import os
import pathlib
import subprocess
import sys
import tempfile

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from elevenlabs import ROOT, ApiError, api_key, request  # noqa: E402

GODOT = os.environ.get("GODOT", r"C:\Program Files\Godot\Godot_Console.exe")
VOICES = pathlib.Path(__file__).resolve().parent / "voices.json"
VOICE_DIR = ROOT / "assets" / "voice"
MANIFEST = VOICE_DIR / "manifest.json"
OUTPUT_FORMAT = "mp3_44100_128"
DEFAULT_MODEL = "eleven_v3"
FALLBACK_MODEL = "eleven_multilingual_v2"
DEFAULT_SETTINGS = {
    "eleven_v3": {"stability": 0.5},
    "eleven_multilingual_v2": {"stability": 0.4, "similarity_boost": 0.8, "style": 0.3, "use_speaker_boost": True},
}
# Timing a first word from the take's sound: a frame of the take louder than SOUND_DB is sound; QUIET_GAP
# seconds of quiet part the word from anything before it, such as a click (a stop inside a word is
# shorter); a word timed less than LATE_ENOUGH seconds after its sound begins loses nothing you hear and
# is left alone; and a word timed again starts FIRST_WORD_LEAD seconds before its sound gets that loud,
# as the first word of a take with no direction is timed.
SOUND_RATE = 44100
SOUND_FRAME = 0.005
SOUND_DB = -45.0
QUIET_GAP = 0.06
LATE_ENOUGH = 0.02
FIRST_WORD_LEAD = 0.05


def export_lines() -> list[dict]:
    with tempfile.TemporaryDirectory() as folder:
        out = pathlib.Path(folder) / "lines.json"
        result = subprocess.run(
            [GODOT, "--headless", "--path", str(ROOT), "-s", "res://dev/export_voice_lines.gd", "--", f"--out={out}"],
            capture_output=True, text=True)
        if result.returncode != 0 or not out.exists():
            sys.exit(f"Godot could not export the lines:\n{result.stdout}\n{result.stderr}")
        return json.loads(out.read_text(encoding="utf-8"))["lines"]


def voice_of(line: dict) -> str:
    """The name of the voice that says a line: its speaker's, or a voice of its own, such as confessor.recliner."""
    return line.get("voice") or line["speaker"]


def voice_setup(voice: dict) -> tuple[str, dict, str]:
    model = voice.get("model_id", DEFAULT_MODEL)
    return model, voice.get("voice_settings", DEFAULT_SETTINGS.get(model, {})), voice.get("direction", "")


def signature(voice: dict) -> str:
    """Changes whenever the voice, its settings or its direction change, so every clip made with it goes out of date."""
    model, settings, direction = voice_setup(voice)
    recipe = {"voice_id": voice["voice_id"], "model_id": model, "voice_settings": settings}
    if direction:
        recipe["direction"] = direction
    return hashlib.sha1(json.dumps(recipe, sort_keys=True).encode("utf-8")).hexdigest()[:12]


def synthesize(text: str, voice: dict, key: str, line_direction: str = "") -> tuple[bytes, dict, str]:
    model, settings, direction = voice_setup(voice)
    direction = line_direction or direction
    for attempt_model in dict.fromkeys([model, FALLBACK_MODEL]):
        # Only v3 reads stage directions; another model would say them aloud.
        prefix = f"{direction} " if direction and attempt_model == "eleven_v3" else ""
        body = {"text": prefix + text, "model_id": attempt_model,
                "voice_settings": settings if attempt_model == model else DEFAULT_SETTINGS[attempt_model]}
        path = f"/text-to-speech/{voice['voice_id']}/with-timestamps?output_format={OUTPUT_FORMAT}"
        try:
            response = request("POST", path, key, body)
        except ApiError as error:
            if attempt_model != FALLBACK_MODEL and error.status in (400, 422):
                print(f"  {attempt_model} refused ({error.body[:160]}); trying {FALLBACK_MODEL}")
                continue
            raise
        alignment = response.get("alignment") or response.get("normalized_alignment") or {}
        skip = len(prefix)
        timing = {
            "text": text,
            "characters": "".join(alignment.get("characters", [])[skip:]),
            "starts": alignment.get("character_start_times_seconds", [])[skip:],
            "ends": alignment.get("character_end_times_seconds", [])[skip:],
        }
        return base64.b64decode(response["audio_base64"]), timing, attempt_model
    raise RuntimeError("no model left to try")


def is_led(direction: str, model: str) -> bool:
    """Whether a take was voiced with a direction said before its line, which only v3 reads."""
    return bool(direction) and model == "eleven_v3"


def sound_levels(take: pathlib.Path, seconds: float) -> list[float]:
    """The take's loudness in dB over its first seconds, a frame at a time."""
    raw = subprocess.run(["ffmpeg", "-v", "error", "-t", f"{seconds:.3f}", "-i", str(take), "-ac", "1",
                          "-ar", str(SOUND_RATE), "-f", "s16le", "-"], capture_output=True, check=True).stdout
    samples = array.array("h")
    samples.frombytes(raw)
    size = round(SOUND_FRAME * SOUND_RATE)
    levels = []
    for at in range(0, len(samples) - size + 1, size):
        power = sum(sample * sample for sample in samples[at:at + size]) / size
        levels.append(10 * math.log10(power) - 20 * math.log10(32768) if power > 0 else -120.0)
    return levels


def sound_start(levels: list[float], at: float) -> float:
    """When the sound heard at the moment [at], or starting within LATE_ENOUGH of it, began: back from it
    to the first quiet long enough to part words, in seconds into the take. [at] itself when there is no
    such sound, as for a word timed again, which starts in the quiet before its sound."""
    frame = min(int(at / SOUND_FRAME), len(levels))
    if all(level < SOUND_DB for level in levels[frame:frame + round(LATE_ENOUGH / SOUND_FRAME) + 1]):
        return at
    quiet = 0
    while frame > 0:
        frame -= 1
        quiet = quiet + 1 if levels[frame] < SOUND_DB else 0
        if quiet * SOUND_FRAME >= QUIET_GAP:
            break
    return (frame + quiet) * SOUND_FRAME


def time_first_word(timing: dict, take: pathlib.Path) -> bool:
    """If the first word is timed to start after its sound does, spreads its letters evenly from just
    before that sound to where they end; the stop after them keeps its time. Returns whether the timings
    changed."""
    starts, ends, text = timing["starts"], timing["ends"], timing["characters"]
    last = (text.find(" ") if " " in text else len(text)) - 1
    if last < 0 or len(starts) != len(text) or len(ends) != len(text):
        return False
    while last > 0 and not text[last].isalnum():
        last -= 1
    letters_end = ends[last]
    sound = sound_start(sound_levels(take, max(letters_end, starts[0]) + LATE_ENOUGH), starts[0])
    if starts[0] - sound < LATE_ENOUGH:
        return False
    begin = round(max(0.0, sound - FIRST_WORD_LEAD), 3)
    step = (letters_end - begin) / (last + 1)
    for i in range(last + 1):
        starts[i] = round(begin + step * i, 3)
        if i < last:
            ends[i] = round(begin + step * (i + 1), 3)
    return True


def fix_starts(manifest: dict) -> None:
    """Times the first word of every take whose line has a direction again from its sound, as a new take is."""
    fixed = []
    for line_id, entry in sorted(manifest.items()):
        if not is_led(entry.get("direction", ""), entry.get("model", "")):
            continue
        timing_path = ROOT / entry["timing"].removeprefix("res://")
        timing = json.loads(timing_path.read_text(encoding="utf-8"))
        if time_first_word(timing, ROOT / entry["audio"].removeprefix("res://")):
            timing_path.write_text(json.dumps(timing), encoding="utf-8", newline="\n")
            fixed.append(line_id)
    print(f"Timed the first word again in {len(fixed)} takes" + (f": {', '.join(fixed)}" if fixed else ""))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--only", help="voice only lines whose id starts with this")
    parser.add_argument("--force", action="store_true", help="voice again even lines that are up to date")
    parser.add_argument("--prune", action="store_true", help="delete clips whose lines no longer exist")
    parser.add_argument("--dry-run", action="store_true", help="list what would be voiced and stop")
    parser.add_argument("--fix-starts", action="store_true",
                        help="time the first word of the takes led by a direction again, from their sound, and stop")
    args = parser.parse_args()

    voices = json.loads(VOICES.read_text(encoding="utf-8")) if VOICES.exists() else {}
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8")) if MANIFEST.exists() else {}
    if args.fix_starts:
        fix_starts(manifest)
        return
    lines = export_lines()

    todo = []
    for line in lines:
        voice = voices.get(voice_of(line))
        if voice is None or (args.only and not line["id"].startswith(args.only)):
            continue
        entry = manifest.get(line["id"], {})
        fresh = (entry.get("text_sha1") == line["sha1"] and entry.get("voice") == signature(voice)
                 and entry.get("direction", "") == line.get("direction", ""))
        if args.force or not fresh:
            todo.append((line, voice))
    unvoiced = sorted({voice_of(line) for line in lines if voice_of(line) not in voices})
    if unvoiced:
        print(f"No voice yet for: {', '.join(unvoiced)}")
    print(f"{len(todo)} lines to voice, {sum(len(line['text']) for line, _ in todo)} characters")
    if args.dry_run:
        for line, _ in todo:
            print(f"  {line['id']}: {line['text'][:70]}")
        return

    key = api_key() if todo else ""
    for line, voice in todo:
        audio, timing, model = synthesize(line["text"], voice, key, line.get("direction", ""))
        folder = VOICE_DIR / line["speaker"]
        folder.mkdir(parents=True, exist_ok=True)
        (folder / f"{line['id']}.mp3").write_bytes(audio)
        if is_led(line.get("direction") or voice_setup(voice)[2], model):
            time_first_word(timing, folder / f"{line['id']}.mp3")
        (folder / f"{line['id']}.json").write_text(json.dumps(timing), encoding="utf-8", newline="\n")
        if timing["characters"] != line["text"]:
            print(f"  note: {line['id']}'s timings cover slightly different characters; the game will spread them evenly")
        manifest[line["id"]] = {
            "speaker": line["speaker"],
            "audio": f"res://assets/voice/{line['speaker']}/{line['id']}.mp3",
            "timing": f"res://assets/voice/{line['speaker']}/{line['id']}.json",
            "text_sha1": line["sha1"],
            "voice": signature(voice),
            "direction": line.get("direction", ""),
            "model": model,
            "seconds": round(timing["ends"][-1], 3) if timing["ends"] else None,
        }
        MANIFEST.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8", newline="\n")
        print(f"  voiced {line['id']} ({model}, {manifest[line['id']]['seconds']} s)")

    gone = sorted(set(manifest) - {line["id"] for line in lines})
    if gone and args.prune:
        for line_id in gone:
            entry = manifest.pop(line_id)
            for resource in (entry["audio"], entry["timing"]):
                path = ROOT / resource.removeprefix("res://")
                path.unlink(missing_ok=True)
                pathlib.Path(str(path) + ".import").unlink(missing_ok=True)
        MANIFEST.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8", newline="\n")
        print(f"Pruned {len(gone)} clips whose lines are gone")
    elif gone:
        print(f"{len(gone)} clips belong to lines that are gone; run with --prune to delete them")


if __name__ == "__main__":
    main()
