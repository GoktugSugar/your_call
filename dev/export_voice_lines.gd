extends SceneTree
## Development only: writes every line of content to JSON for the voice tools, with its id, its
## speaker, its plain text (colour tags stripped, as it is spoken) and that text's SHA-1. The game
## checks the same hash before it plays a clip, so a clip never plays over text it was not made from.
## [codeblock]
## Godot_Console --headless --path . -s res://dev/export_voice_lines.gd -- --out=C:/somewhere/lines.json
## [/codeblock]
## Exits with code 1 if the content has problems.

const CHAPTERS_DIR := "res://content/chapters"


func _initialize() -> void:
	var args := DevArgs.parse()
	var out: String = args.get("out", "user://voice_lines.json")
	var loader := ContentLoader.new(Profile.axis_ids())
	var lines: Array[Dictionary] = []
	for file in DirAccess.get_files_at(CHAPTERS_DIR):
		if file.get_extension() != "json":
			continue
		var chapter := loader.load_chapter(CHAPTERS_DIR.path_join(file))
		if chapter == null:
			continue
		for beat in chapter.beats:
			for line in _lines_of(beat):
				var spoken := Markup.strip(line.text)
				lines.append({"id": line.id, "speaker": String(line.speaker), "text": spoken, "sha1": spoken.sha1_text(),
						"direction": line.direction})
	for problem in loader.problems:
		printerr(problem)
	var json := FileAccess.open(out, FileAccess.WRITE)
	json.store_string(JSON.stringify({"lines": lines}, "  "))
	json.close()
	print("export_voice_lines: %d lines to %s" % [lines.size(), out])
	quit(1 if not loader.problems.is_empty() else 0)


func _lines_of(beat: BeatData) -> Array[LineData]:
	var lines: Array[LineData] = []
	if beat is NarrationData:
		lines.append_array((beat as NarrationData).lines)
	elif beat is QuestionData:
		var question := beat as QuestionData
		lines.append_array(question.ask)
		lines.append_array(question.stage_lines)
		for option in question.options:
			lines.append_array(option.reaction)
	return lines
