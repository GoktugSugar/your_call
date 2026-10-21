class_name VoiceLibrary
extends RefCounted
## Finds the voice clip for a line. The voice tools list every clip in the manifest by line id, with
## the SHA-1 of the text it was made from. A clip only plays while its line still says exactly that,
## so a rewritten line goes quiet until it is voiced again instead of playing the old take.

const MANIFEST_PATH := "res://assets/voice/manifest.json"

static var _manifest: Dictionary = {}
static var _loaded := false


## The clip for [param line], or null when it has none or its text has changed since.
static func clip_for(line: LineData) -> VoiceClip:
	var entry := find_entry(_loaded_manifest(), line)
	var audio := str(entry.get("audio", ""))
	if entry.is_empty() or not ResourceLoader.exists(audio):
		return null
	var clip := VoiceClip.new()
	clip.stream = load(audio) as AudioStream
	clip.text = Markup.strip(line.text)
	var timing: Variant = JSON.parse_string(FileAccess.get_file_as_string(str(entry.get("timing", ""))))
	if timing is Dictionary and str(timing.get("characters", "")) == clip.text:
		clip.starts = PackedFloat32Array(timing.get("starts", []))
		clip.ends = PackedFloat32Array(timing.get("ends", []))
	return clip if clip.stream != null else null


## The entry for [param line] in [param manifest], or an empty dictionary when it has none or the
## line's spoken text no longer matches the text the clip was made from.
static func find_entry(manifest: Dictionary, line: LineData) -> Dictionary:
	var entry: Variant = manifest.get(line.id)
	if not entry is Dictionary:
		return {}
	if str(entry.get("text_sha1", "")) != Markup.strip(line.text).sha1_text():
		return {}
	return entry


## Forgets the loaded manifest, so the next lookup reads it again, such as after voicing new lines.
static func reload() -> void:
	_loaded = false


static func _loaded_manifest() -> Dictionary:
	if not _loaded:
		_loaded = true
		_manifest = {}
		if FileAccess.file_exists(MANIFEST_PATH):
			var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
			if data is Dictionary:
				_manifest = data
	return _manifest
