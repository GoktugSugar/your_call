extends GutTest
## The content loader reads well formed chapters and names every problem in malformed ones.

const AXES: PackedStringArray = ["one_many", "ends_rules"]

var _dir := ""


func before_each() -> void:
	_dir = "user://test_content_loader"
	DirAccess.make_dir_recursive_absolute(_dir)


func after_each() -> void:
	for file in DirAccess.get_files_at(_dir):
		DirAccess.remove_absolute(_dir.path_join(file))
	DirAccess.remove_absolute(_dir)


func _write(data: Variant) -> String:
	var path := _dir.path_join("chapter.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data) if not data is String else data)
	file.close()
	return path


func _question(overrides := {}) -> Dictionary:
	var question := {
		"kind": "question", "id": "lever", "number": "1.02", "title": "The Lever",
		"verb": "binary", "weight": "medium", "stage": {"type": "trolley"},
		"ask": ["Your call."],
		"options": [
			{"id": "pull", "label": "Pull the lever", "crowd": 87, "profile": {"one_many": 1}, "reaction": ["You pulled."]},
			{"id": "nothing", "label": "Do nothing", "crowd": 13, "reaction": [{"text": "Hands in pockets.", "face": "smug"}]},
		],
		"reveal": {"heading": "how others chose"},
	}
	question.merge(overrides, true)
	return question


func _load(question: Dictionary) -> ContentLoader:
	var loader := ContentLoader.new(AXES)
	loader.load_chapter(_write({"id": "ch1", "title": "The Tracks", "beats": [question]}))
	return loader


func test_well_formed_chapter_loads_without_problems() -> void:
	var loader := ContentLoader.new(AXES)
	var chapter := loader.load_chapter(_write({"id": "ch1", "title": "The Tracks", "beats": [_question()]}))
	assert_eq(loader.problems, PackedStringArray())
	var question := chapter.find_beat(&"lever") as QuestionData
	assert_eq(question.options[0].profile, {&"one_many": 1.0})
	assert_eq(question.options[1].reaction[0].face, &"smug")


func test_lines_get_ids_from_where_they_sit() -> void:
	var loader := ContentLoader.new(AXES)
	var chapter := loader.load_chapter(_write({"id": "ch1", "title": "The Tracks", "beats": [_question()]}))
	var question := chapter.find_beat(&"lever") as QuestionData
	assert_eq(question.ask[0].id, "ch1.lever.ask.1")
	assert_eq(question.options[0].reaction[0].id, "ch1.lever.pull.1")


func test_a_cinematic_beat_names_its_scene() -> void:
	var loader := ContentLoader.new(AXES)
	var chapter := loader.load_chapter(_write({"id": "ch1", "title": "The Tracks",
			"beats": [{"kind": "cinematic", "id": "crash", "scene": "crash"}, _question()]}))
	assert_eq(loader.problems, PackedStringArray())
	assert_eq((chapter.find_beat(&"crash") as CinematicData).scene, &"crash")


func test_pleas_in_stage_data_become_plea_lines() -> void:
	var question := _question({"stage": {"type": "trolley", "tracks": [{"figures": ["stranger"]},
			{"figures": [{"kind": "stranger", "says": "Please. Not me."}]}]}})
	var loader := ContentLoader.new(AXES)
	var chapter := loader.load_chapter(_write({"id": "ch1", "title": "The Tracks", "beats": [question]}))
	var lines := (chapter.find_beat(&"lever") as QuestionData).stage_lines
	assert_eq(lines.size(), 1)
	assert_eq(lines[0].text, "Please. Not me.")
	assert_eq(lines[0].speaker, &"plea")
	assert_eq(lines[0].id, "ch1.lever.stage.1")


func test_a_line_can_carry_a_voice_direction() -> void:
	var question := _question()
	question.options[0].reaction = [{"text": "What.", "direction": "[furious]"}]
	var loader := ContentLoader.new(AXES)
	var chapter := loader.load_chapter(_write({"id": "ch1", "title": "The Tracks", "beats": [question]}))
	assert_eq(loader.problems, PackedStringArray())
	assert_eq((chapter.find_beat(&"lever") as QuestionData).options[0].reaction[0].direction, "[furious]")


func test_unknown_key_is_reported() -> void:
	assert_eq(_load(_question({"wieght": "heavy"})).problems.size(), 1)


func test_unknown_profile_axis_is_reported() -> void:
	var question := _question()
	question.options[0].profile = {"head_heart": 1}
	assert_string_contains("\n".join(_load(question).problems), "unknown profile axis 'head_heart'")


func test_unknown_verb_is_reported() -> void:
	assert_string_contains("\n".join(_load(_question({"verb": "riddle"})).problems), "verb 'riddle'")


func test_question_with_one_option_is_reported() -> void:
	var question := _question()
	question.options = [question.options[0]]
	assert_string_contains("\n".join(_load(question).problems), "at least two options")


func test_broken_json_is_reported_with_its_line() -> void:
	var loader := ContentLoader.new(AXES)
	assert_null(loader.load_chapter(_write("{\n  \"id\": \"ch1\",\n  oops\n}")))
	assert_eq(loader.problems.size(), 1)
