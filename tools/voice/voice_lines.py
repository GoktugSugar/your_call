"""Voice the game's lines with ElevenLabs: one take per line, with the time each character is spoken.

    python tools/voice/voice_lines.py              voice every line that is missing or out of date
    python tools/voice/voice_lines.py --dry-run    list what would be voiced, and how many characters
    python tools/voice/voice_lines.py --only ch1.lever
    python tools/voice/voice_lines.py --force      voice again even lines that are up to date
    python tools/voice/voice_lines.py --prune      also delete clips whose lines are gone

Godot exports the lines from content (dev/export_voice_lines.gd), so line ids are built in one place.
A line is voiced when its speaker has a voice in voices.json, which also sets the model, its settings,
and an optional "direction": a v3 stage direction such as "[rapid-fire]" said before every line to
shape the delivery. The direction is not spoken and its timings are dropped. Its clip goes to
assets/voice/<speaker>/<line id>.mp3, with <line id>.json beside it holding the timings, and
assets/voice/manifest.json records the text and voice settings each clip was made from. A clip is
out of date when either changes. The game plays a clip only while its line's text still matches.
"""

import argparse
import base64
import hashlib
import json
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


def export_lines() -> list[dict]:
    with tempfile.TemporaryDirectory() as folder:
        out = pathlib.Path(folder) / "lines.json"
        result = subprocess.run(
            [GODOT, "--headless", "--path", str(ROOT), "-s", "res://dev/export_voice_lines.gd", "--", f"--out={out}"],
            capture_output=True, text=True)
        if result.returncode != 0 or not out.exists():
            sys.exit(f"Godot could not export the lines:\n{result.stdout}\n{result.stderr}")
        return json.loads(out.read_text(encoding="utf-8"))["lines"]


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


def synthesize(text: str, voice: dict, key: str) -> tuple[bytes, dict, str]:
    model, settings, direction = voice_setup(voice)
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


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--only", help="voice only lines whose id starts with this")
    parser.add_argument("--force", action="store_true", help="voice again even lines that are up to date")
    parser.add_argument("--prune", action="store_true", help="delete clips whose lines no longer exist")
    parser.add_argument("--dry-run", action="store_true", help="list what would be voiced and stop")
    args = parser.parse_args()

    voices = json.loads(VOICES.read_text(encoding="utf-8")) if VOICES.exists() else {}
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8")) if MANIFEST.exists() else {}
    lines = export_lines()

    todo = []
    for line in lines:
        voice = voices.get(line["speaker"])
        if voice is None or (args.only and not line["id"].startswith(args.only)):
            continue
        entry = manifest.get(line["id"], {})
        fresh = entry.get("text_sha1") == line["sha1"] and entry.get("voice") == signature(voice)
        if args.force or not fresh:
            todo.append((line, voice))
    unvoiced = sorted({line["speaker"] for line in lines if line["speaker"] not in voices})
    if unvoiced:
        print(f"No voice yet for: {', '.join(unvoiced)}")
    print(f"{len(todo)} lines to voice, {sum(len(line['text']) for line, _ in todo)} characters")
    if args.dry_run:
        for line, _ in todo:
            print(f"  {line['id']}: {line['text'][:70]}")
        return

    key = api_key() if todo else ""
    for line, voice in todo:
        audio, timing, model = synthesize(line["text"], voice, key)
        folder = VOICE_DIR / line["speaker"]
        folder.mkdir(parents=True, exist_ok=True)
        (folder / f"{line['id']}.mp3").write_bytes(audio)
        (folder / f"{line['id']}.json").write_text(json.dumps(timing), encoding="utf-8", newline="\n")
        if timing["characters"] != line["text"]:
            print(f"  note: {line['id']}'s timings cover slightly different characters; the game will spread them evenly")
        manifest[line["id"]] = {
            "speaker": line["speaker"],
            "audio": f"res://assets/voice/{line['speaker']}/{line['id']}.mp3",
            "timing": f"res://assets/voice/{line['speaker']}/{line['id']}.json",
            "text_sha1": line["sha1"],
            "voice": signature(voice),
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
