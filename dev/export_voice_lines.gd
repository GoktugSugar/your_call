extends SceneTree
## Development only: writes every line of content to JSON for the voice tools, the chapters', the
## main menu's and the trailers', with its id, its speaker, the voice that says it, its plain text (colour tags stripped,
## as it is spoken) and that text's SHA-1. The game checks the same hash before it plays a clip, so a clip never plays over text
## it was not made from.
## A line with placeholders is written once for every way its stage fills it, each under its own id,
## with [code]fills[/code] naming the line it fills. A line marked not voiced is left out.
## [codeblock]
## Godot_Console --headless --path . -s res://dev/export_voice_lines.gd -- --out=C:/somewhere/lines.json
## [/codeblock]
## Exits with code 1 if the content has problems.

const CHAPTERS_DIR := "res://content/chapters"
const MENU_PATH := "res://content/menu.json"
## Files of lines outside the run, in the chapter form: the trailers' (dev/trailer/).
const OTHER_LINES: PackedStringArray = ["res://dev/trailer/trailer_lines.json"]


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
					if not spoken_line.voiced:
						continue
					var entry := _entry(spoken_line)
					if spoken_line.id != line.id:
						entry["fills"] = line.id
					lines.append(entry)
	var menu := loader.load_menu(MENU_PATH)
	for line in menu.all_lines() if menu != null else []:
		if line.voiced:
			lines.append(_entry(line))
	for path in OTHER_LINES:
		var other := loader.load_chapter(path)
		for beat in other.beats if other != null else []:
			for line in beat.all_lines():
				if line.voiced:
					lines.append(_entry(line))
	for problem in loader.problems:
		printerr(problem)
	for line_id in unfilled:
		printerr("%s has placeholders its stage lists no fillings for, so it cannot be voiced" % line_id)
	var json := FileAccess.open(out, FileAccess.WRITE)
	json.store_string(JSON.stringify({"lines": lines}, "  "))
	json.close()
	print("export_voice_lines: %d lines to %s" % [lines.size(), out])
	quit(1 if not loader.problems.is_empty() else 0)


## What the voice tools need of [param line]: its id, who says it in which voice, and its spoken text
## with that text's hash.
func _entry(line: LineData) -> Dictionary:
	var spoken := Markup.strip(line.text)
	return {"id": line.id, "speaker": String(line.speaker), "voice": line.voice_name(), "text": spoken,
			"sha1": spoken.sha1_text(), "direction": line.direction}
