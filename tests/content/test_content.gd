extends GutTest
## Every chapter under content/ loads cleanly and follows the text rules in PREMISE.md section 9.

const CHAPTERS_DIR := "res://content/chapters"
## Verbs whose crowd split is shown, not used: their shares should add up to the whole crowd.
const DISPLAY_ONLY_VERBS: PackedStringArray = ["binary", "multiple_choice"]
const WHOLE_CROWD := 100.0

var _chapters: Array[ChapterData] = []
var _problems := PackedStringArray()


func before_all() -> void:
	var loader := ContentLoader.new(Profile.axis_ids())
	for file in DirAccess.get_files_at(CHAPTERS_DIR):
		if file.get_extension() == "json":
			var chapter := loader.load_chapter(CHAPTERS_DIR.path_join(file))
			if chapter != null:
				_chapters.append(chapter)
	_problems = loader.problems


func test_there_is_content() -> void:
	assert_gt(_chapters.size(), 0)


func test_every_chapter_loads_without_problems() -> void:
	assert_eq(_problems, PackedStringArray(), "\n".join(_problems))


func test_no_player_facing_text_has_a_dash() -> void:
	var offenders := PackedStringArray()
	for text in _player_facing_text():
		if Markup.has_dash(text):
			offenders.append(text)
	assert_eq(offenders, PackedStringArray(), "\n".join(offenders))


func test_narration_tags_are_well_formed() -> void:
	var offenders := PackedStringArray()
	for line in _all_lines():
		for problem in Markup.tag_problems(line.text):
			offenders.append("%s: %s" % [line.id, problem])
	assert_eq(offenders, PackedStringArray(), "\n".join(offenders))


func test_labels_and_headings_carry_no_tags() -> void:
	var offenders := PackedStringArray()
	for question in _questions():
		if Markup.has_tags(question.reveal_heading):
			offenders.append("%s heading" % question.id)
		for option in question.options:
			if Markup.has_tags(option.label):
				offenders.append("%s option %s" % [question.id, option.id])
	assert_eq(offenders, PackedStringArray(), "\n".join(offenders))


func test_display_only_crowd_splits_add_up_to_the_whole_crowd() -> void:
	var offenders := PackedStringArray()
	for question in _questions():
		if not String(question.verb) in DISPLAY_ONLY_VERBS:
			continue
		var total := 0.0
		for option in question.options:
			total += option.crowd
		if not is_equal_approx(total, WHOLE_CROWD):
			offenders.append("%s adds up to %s" % [question.id, total])
	assert_eq(offenders, PackedStringArray(), "\n".join(offenders))


func test_every_question_has_a_stage_scene() -> void:
	var offenders := PackedStringArray()
	for question in _questions():
		var type := str(question.stage.get("type", ""))
		if not ResourceLoader.exists(QuestionPlayer.STAGE_SCENE % [type, type]):
			offenders.append("%s: no stage '%s'" % [question.id, type])
	assert_eq(offenders, PackedStringArray(), "\n".join(offenders))


func _questions() -> Array[QuestionData]:
	var found: Array[QuestionData] = []
	for chapter in _chapters:
		for beat in chapter.beats:
			if beat is QuestionData:
				found.append(beat)
	return found


func _all_lines() -> Array[LineData]:
	var lines: Array[LineData] = []
	for chapter in _chapters:
		for beat in chapter.beats:
			if beat is NarrationData:
				lines.append_array((beat as NarrationData).lines)
			elif beat is QuestionData:
				var question := beat as QuestionData
				lines.append_array(question.ask)
				for option in question.options:
					lines.append_array(option.reaction)
	return lines


func _player_facing_text() -> PackedStringArray:
	var texts := PackedStringArray()
	for line in _all_lines():
		texts.append(line.text)
	for question in _questions():
		texts.append(question.reveal_heading)
		for option in question.options:
			texts.append(option.label)
	return texts
