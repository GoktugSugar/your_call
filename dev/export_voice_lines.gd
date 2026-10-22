extends SceneTree
## Development only: writes every line of content to JSON for the voice tools, with its id, its
## speaker, its plain text (colour tags stripped, as it is spoken) and that text's SHA-1. The game
## checks the same hash before it plays a clip, so a clip never plays over text it was not made from.
## A line with placeholders is written once for every way its stage fills it, each under its own id.
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
	var unfilled := PackedStringArray()
	for file in DirAccess.get_files_at(CHAPTERS_DIR):
		if file.get_extension() != "json":
			continue
		var chapter := loader.load_chapter(CHAPTERS_DIR.path_join(file))
		if chapter == null:
			continue
		for beat in chapter.beats:
			for line in beat.all_lines():
				var spoken_lines: Array = [line]
				if beat is QuestionData:
					spoken_lines = StageFills.filled_lines(beat as QuestionData, line)
				if spoken_lines.is_empty():
					unfilled.append(line.id)
				for spoken_line: LineData in spoken_lines:
					var spoken := Markup.strip(spoken_line.text)
					lines.append({"id": spoken_line.id, "speaker": String(spoken_line.speaker), "text": spoken,
							"sha1": spoken.sha1_text(), "direction": spoken_line.direction})
	for problem in loader.problems:
		printerr(problem)
	for line_id in unfilled:
		printerr("%s has placeholders its stage lists no fillings for, so it cannot be voiced" % line_id)
	var json := FileAccess.open(out, FileAccess.WRITE)
	json.store_string(JSON.stringify({"lines": lines}, "  "))
	json.close()
	print("export_voice_lines: %d lines to %s" % [lines.size(), out])
	quit(1 if not loader.problems.is_empty() else 0)
