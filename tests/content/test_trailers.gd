extends GutTest
## The trailers' lines in dev/trailer/trailer_lines.json load cleanly, follow the text rules and are all
## voiced, and the cut in dev/trailer/trailer_cut.json names only lines the trailers have and questions
## the run has, none of which can fire an ending: the trailers show no secret ending, nor the way to one.

const LINES_PATH := "res://dev/trailer/trailer_lines.json"
const CUT_PATH := "res://dev/trailer/trailer_cut.json"
const RUN_PATH := "res://content/run.json"
const CHAPTERS_DIR := "res://content/chapters"
const MANIFEST_PATH := "res://assets/voice/manifest.json"

var _lines: ChapterData
var _problems := PackedStringArray()
var _cut := {}


func before_all() -> void:
	var loader := ContentLoader.new(Profile.axis_ids())
	_lines = loader.load_chapter(LINES_PATH)
	_problems = loader.problems
	var cut: Variant = loader.read_json(CUT_PATH)
	_cut = cut if cut is Dictionary else {}


func test_the_lines_load_without_problems() -> void:
	assert_not_null(_lines)
	assert_eq(_problems, PackedStringArray(), "\n".join(_problems))
	assert_false(_cut.is_empty(), "the cut loads")


func test_the_lines_follow_the_text_rules() -> void:
	var offenders := PackedStringArray()
	for line in _all_lines():
		for problem in Markup.tag_problems(line.text):
			offenders.append("%s: %s" % [line.id, problem])
		if Markup.has_dash(line.text) or Markup.has_stray_brace(line.text):
			offenders.append(line.id)
	assert_eq(offenders, PackedStringArray(), "\n".join(offenders))


func test_every_line_is_voiced_from_its_own_words() -> void:
	var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	assert_true(manifest is Dictionary, "the voice manifest reads")
	if not manifest is Dictionary:
		return
	var silent := PackedStringArray()
	for line in _all_lines():
		if VoiceLibrary.find_entry(manifest, line).is_empty():
			silent.append(line.id)
	assert_eq(silent, PackedStringArray(), "no clip, or one made from other words")


func test_the_cut_names_only_lines_the_trailers_have() -> void:
	var known := {}
	for beat in _lines.beats if _lines != null else []:
		known[String(beat.id)] = true
	var unknown := PackedStringArray()
	for name in _named_lines():
		if not known.has(name):
			unknown.append(name)
	assert_eq(unknown, PackedStringArray(), "\n".join(unknown))


func test_the_cut_plays_only_questions_that_fire_no_ending() -> void:
	var questions := {}
	for chapter in ContentLoader.new(Profile.axis_ids()).load_run(RUN_PATH, CHAPTERS_DIR):
		for beat in chapter.beats:
			if beat is QuestionData:
				questions["%s.%s" % [chapter.id, beat.id]] = beat
	var offenders := PackedStringArray()
	for shot: Dictionary in _cut.get("shots", {}).values():
		if not shot.has("question"):
			continue
		var path := str(shot["question"])
		var question: QuestionData = questions.get(path)
		if question == null:
			offenders.append("%s is not in the run" % path)
			continue
		var endings: Array = [question.ending] + question.endings.values()
		for option in question.options:
			endings.append_array([option.ending] + option.endings.values())
		if endings.any(func(ending: StringName) -> bool: return ending != &""):
			offenders.append("%s can fire an ending" % path)
	assert_eq(offenders, PackedStringArray(), "\n".join(offenders))


func _all_lines() -> Array[LineData]:
	var lines: Array[LineData] = []
	for beat in _lines.beats if _lines != null else []:
		lines.append_array(beat.all_lines())
	return lines


## Every trailers' line the cut names: in what a question asks and answers, in what the steps say, and
## what the box is parked for.
func _named_lines() -> PackedStringArray:
	var names := PackedStringArray()
	for shot: Dictionary in _cut.get("shots", {}).values():
		for entry: Variant in shot.get("ask", []):
			if entry is String:
				names.append(entry)
		for said: Variant in shot.get("react", {}).values():
			for entry: Variant in said:
				if entry is String:
					names.append(entry)
		for step: Dictionary in shot.get("steps", []) + shot.get("picks", []):
			var say: Variant = step.get("say", [])
			for entry: Variant in say if say is Array else [say]:
				names.append(str(entry))
		if shot.has("park"):
			names.append(str(shot["park"]))
	return names
