extends GutTest
## The trailer's lines follow the text rules every line in the game does, and its cut names only what
## exists: questions in the run, lines in the trailer's file, cinematics, kinds of shot, and the music
## and sounds it lays over the pictures.

const LINES_PATH := "res://trailer/trailer_lines.json"
const CUT_PATH := "res://trailer/trailer_cut.json"
const RUN_PATH := "res://content/run.json"
const CHAPTERS_DIR := "res://content/chapters"
const KINDS: PackedStringArray = ["narration", "question", "cinematic", "title", "reveal"]

var _lines: ChapterData
var _cut := {}
var _questions := {}
var _problems := PackedStringArray()


func before_all() -> void:
	var loader := ContentLoader.new(Profile.axis_ids())
	_lines = loader.load_chapter(LINES_PATH)
	var cut: Variant = loader.read_json(CUT_PATH)
	_cut = cut if cut is Dictionary else {}
	var run: Variant = loader.read_json(RUN_PATH)
	for file: Variant in run.get("chapters", []) if run is Dictionary else []:
		var chapter := loader.load_chapter(CHAPTERS_DIR.path_join(str(file)))
		if chapter == null:
			continue
		for beat in chapter.beats:
			if beat is QuestionData:
				_questions["%s.%s" % [chapter.id, beat.id]] = beat
	_problems = loader.problems


func test_the_lines_and_the_cut_load_without_problems() -> void:
	assert_not_null(_lines)
	assert_false(_cut.is_empty())
	assert_eq(_problems, PackedStringArray(), "\n".join(_problems))


func test_every_line_follows_the_text_rules() -> void:
	var offenders := PackedStringArray()
	for beat in _lines.beats:
		assert_true(beat is NarrationData, "%s is narration, as every trailer line is" % beat.id)
		for line in beat.all_lines():
			if Markup.has_dash(line.text):
				offenders.append("%s has a dash" % line.id)
			if Markup.has_stray_brace(line.text):
				offenders.append("%s has a stray brace" % line.id)
			for problem in Markup.tag_problems(line.text):
				offenders.append("%s: %s" % [line.id, problem])
	assert_eq(offenders, PackedStringArray(), "\n".join(offenders))


func test_the_title_card_words_are_plain_and_have_no_dash() -> void:
	for shot: Dictionary in _shots_of_kind("title"):
		for key: String in ["title", "line"]:
			var words := str(shot.get(key, ""))
			assert_false(Markup.has_dash(words), "%s has a dash: %s" % [key, words])
			assert_false(Markup.has_tags(words), "%s carries a colour tag: %s" % [key, words])


func test_every_shot_is_a_known_kind_and_names_what_exists() -> void:
	var names := {}
	for beat in _lines.beats:
		names[String(beat.id)] = true
	var offenders := PackedStringArray()
	var shots: Dictionary = _cut.get("shots", {})
	for id: String in shots:
		var shot: Dictionary = shots[id]
		var kind := str(shot.get("kind", ""))
		if not kind in KINDS:
			offenders.append("%s: no kind of shot called '%s'" % [id, kind])
		if shot.has("question") and not _questions.has(str(shot["question"])):
			offenders.append("%s: no question '%s' in the run" % [id, shot["question"]])
		var named: Array = shot.get("say", []).duplicate()
		for key: String in ["ask", "reaction"]:
			if shot.has(key) and str(shot[key]) != QuestionShot.NOTHING:
				named.append(shot[key])
		for set_lines: Variant in (shot.get("sets", {}) as Dictionary).values():
			if str(set_lines) != QuestionShot.NOTHING:
				named.append(set_lines)
		for name: Variant in named:
			if not names.has(str(name)):
				offenders.append("%s: no lines called '%s' in %s" % [id, name, LINES_PATH])
		if kind == "cinematic":
			var scene := str(shot.get("scene", ""))
			if not ResourceLoader.exists(RunPlayer.CINEMATIC_SCENE % [scene, scene]):
				offenders.append("%s: no cinematic '%s'" % [id, scene])
	assert_eq(offenders, PackedStringArray(), "\n".join(offenders))


func test_the_cut_takes_only_from_shots_there_are() -> void:
	var shots: Dictionary = _cut.get("shots", {})
	for piece: Dictionary in _cut.get("cut", []):
		assert_true(shots.has(str(piece.get("shot", ""))), "the cut takes from a shot called %s" % piece.get("shot", ""))
		assert_gt(float(piece.get("length", 0.0)), 0.0)


func test_every_sound_laid_over_the_cut_exists() -> void:
	var sound: Dictionary = _cut.get("sound", {})
	var files: Array = sound.get("music", []) + sound.get("sounds", [])
	for each: Dictionary in files:
		assert_true(FileAccess.file_exists(str(each.get("file", ""))), "%s exists" % each.get("file", ""))


func _shots_of_kind(kind: String) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	var shots: Dictionary = _cut.get("shots", {})
	for id: String in shots:
		if str((shots[id] as Dictionary).get("kind", "")) == kind:
			found.append(shots[id])
	return found
