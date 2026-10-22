extends GutTest
## Every page of every line in content/ fits the dialogue box: shown at the size the box gives it,
## it wraps onto exactly the lines it was measured on, and no more than the box holds. A line with
## placeholders is checked once for every way its stage fills it.

const CHAPTERS_DIR := "res://content/chapters"
const BOX_SCENE := "res://ui/dialogue/dialogue_box.tscn"

var _box: DialogueBox
var _lines: Array[LineData] = []


func before_all() -> void:
	var loader := ContentLoader.new(Profile.axis_ids())
	for file in DirAccess.get_files_at(CHAPTERS_DIR):
		if file.get_extension() != "json":
			continue
		var chapter := loader.load_chapter(CHAPTERS_DIR.path_join(file))
		if chapter == null:
			continue
		for beat in chapter.beats:
			if beat is NarrationData:
				_lines.append_array((beat as NarrationData).lines)
			elif beat is QuestionData:
				var question := beat as QuestionData
				# Words floating over the stage are not shown in the box.
				for line in question.all_lines():
					if not line in question.stage_lines:
						_lines.append_array(StageFills.filled_lines(question, line))


func before_each() -> void:
	_box = (load(BOX_SCENE) as PackedScene).instantiate() as DialogueBox
	add_child_autofree(_box)


func test_there_are_lines_to_check() -> void:
	assert_gt(_lines.size(), 0)


func test_every_page_keeps_the_lines_it_was_measured_on() -> void:
	var offenders := PackedStringArray()
	for line in _lines:
		for page in _box.paginate(line.text):
			var bbcode := Markup.to_bbcode(page, InkPalette.get_default())
			var size := _box.text_size_for(bbcode)
			var measured := _box.measure_label.get_line_count()
			_box.text_label.size = Vector2(size.x, 0.0)
			_box.text_label.text = bbcode
			var shown := _box.text_label.get_line_count()
			if shown != measured or measured > _box.max_lines:
				offenders.append("%s: measured %d lines, shown on %d: %s" % [line.id, measured, shown, page])
	assert_eq(offenders, PackedStringArray(), "\n".join(offenders))
