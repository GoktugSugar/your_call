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


func test_labels_headings_and_stage_words_carry_no_tags() -> void:
	var offenders := PackedStringArray()
	for question in _questions():
		var plain := PackedStringArray([question.reveal_heading, question.reveal_mark])
		plain.append_array(question.option_labels())
		plain.append_array(question.bar_labels())
		plain.append_array(question.stage_texts)
		for text in plain:
			if Markup.has_tags(text):
				offenders.append("%s: %s" % [question.id, text])
	assert_eq(offenders, PackedStringArray(), "\n".join(offenders))


func test_every_curly_bracket_frames_a_placeholder() -> void:
	var offenders := PackedStringArray()
	for text in _player_facing_text():
		if Markup.has_stray_brace(text):
			offenders.append(text)
	assert_eq(offenders, PackedStringArray(), "\n".join(offenders))


func test_every_placeholder_is_one_its_stage_fills() -> void:
	var offenders := PackedStringArray()
	for question in _questions():
		var fills := StageFills.names(question)
		var texts := PackedStringArray(question.stage_texts)
		for line in question.all_lines():
			texts.append(line.text)
		for text in texts:
			for name in Markup.placeholders(text):
				if not name in fills:
					offenders.append("%s: the %s stage does not fill {%s}" % [question.id, question.stage.get("type", ""), name])
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


func test_every_cinematic_has_a_scene() -> void:
	var offenders := PackedStringArray()
	for chapter in _chapters:
		for beat in chapter.beats:
			if beat is CinematicData:
				var scene := (beat as CinematicData).scene
				if not ResourceLoader.exists(RunPlayer.CINEMATIC_SCENE % [scene, scene]):
					offenders.append("%s: no cinematic '%s'" % [beat.id, scene])
	assert_eq(offenders, PackedStringArray(), "\n".join(offenders))


func test_every_soul_on_a_track_is_a_known_kind() -> void:
	var offenders := PackedStringArray()
	for question in _questions():
		if str(question.stage.get("type", "")) != "trolley":
			continue
		for track: Dictionary in question.stage.get("tracks", []):
			for entry: Variant in track.get("figures", []):
				var kind := str((entry as Dictionary).get("kind", "") if entry is Dictionary else entry)
				if not SoulKind.exists(StringName(kind)):
					offenders.append("%s: no soul kind '%s'" % [question.id, kind])
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
			lines.append_array(beat.all_lines())
	return lines


func _player_facing_text() -> PackedStringArray:
	var texts := PackedStringArray()
	for line in _all_lines():
		texts.append(line.text)
	for question in _questions():
		texts.append(question.reveal_heading)
		texts.append(question.reveal_mark)
		texts.append_array(question.option_labels())
		texts.append_array(question.bar_labels())
		texts.append_array(question.stage_texts)
	return texts
