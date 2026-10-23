extends GutTest
## Everyone Else's guesses: a guess that repeats another question's share holds the same number, and
## every guess has the imp's lines for a close guess, a low one and a high one.

const CHAPTERS_DIR := "res://content/chapters"
## The outcomes a guess reports.
const OUTCOMES: Array[StringName] = [&"close", &"low", &"high"]

var _chapters: Array[ChapterData] = []


func before_all() -> void:
	var loader := ContentLoader.new(Profile.axis_ids())
	for file in DirAccess.get_files_at(CHAPTERS_DIR):
		if file.get_extension() == "json":
			var chapter := loader.load_chapter(CHAPTERS_DIR.path_join(file))
			if chapter != null:
				_chapters.append(chapter)


func test_a_guess_that_repeats_a_share_holds_the_same_number() -> void:
	var offenders := PackedStringArray()
	for question in _guesses():
		var named := str(question.stage.get("of", ""))
		if named == "":
			continue
		var option := _option(named)
		if option == null:
			offenders.append("%s: no option %s" % [question.id, named])
		elif not is_equal_approx(option.crowd, float(question.stage.get("truth", -1.0))):
			offenders.append("%s: %s is %s, not %s" % [question.id, named, option.crowd, question.stage.get("truth")])
	assert_eq(offenders, PackedStringArray(), "\n".join(offenders))


func test_every_guess_has_lines_for_every_outcome() -> void:
	var offenders := PackedStringArray()
	for question in _guesses():
		for outcome in OUTCOMES:
			if question.lines_in(outcome).is_empty():
				offenders.append("%s: no %s lines" % [question.id, outcome])
	assert_eq(offenders, PackedStringArray(), "\n".join(offenders))


func test_there_are_guesses() -> void:
	assert_gt(_guesses().size(), 0)


func _guesses() -> Array[QuestionData]:
	var found: Array[QuestionData] = []
	for chapter in _chapters:
		for beat in chapter.beats:
			if beat is QuestionData and str((beat as QuestionData).stage.get("type", "")) == "guess":
				found.append(beat as QuestionData)
	return found


## The option named [param named], as chapter, question and option ids joined with dots.
func _option(named: String) -> OptionData:
	var parts := named.split(".")
	if parts.size() != 3:
		return null
	for chapter in _chapters:
		if chapter.id == StringName(parts[0]):
			var question := chapter.find_beat(StringName(parts[1])) as QuestionData
			return question.find_option(StringName(parts[2])) if question != null else null
	return null
