extends GutTest
## The would you rather doodles and their stage: each doodle id makes a doodle that fits the room a
## doodle has, and the stage puts each one over its option and answers the pointer.

const STAGE_SCENE := "res://stages/doodles/doodles_stage.tscn"
## The tallest a doodle may stand above its origin, in pixels.
const TALLEST := 240.0
## The furthest a doodle may spread either side of its origin, so it stays inside its slot.
const HALF_WIDTH := 200.0
## How far a doodle's middle may sit off its origin, and its lowest point below it.
const SLACK := 8.0


func test_there_are_doodles() -> void:
	assert_gt(DoodlesStage.all_ids().size(), 0)


func test_every_doodle_id_makes_a_doodle() -> void:
	for id in DoodlesStage.all_ids():
		var doodle := DoodlesStage.make_doodle(id)
		assert_not_null(doodle, id)
		if doodle != null:
			doodle.free()


func test_an_unknown_id_makes_nothing() -> void:
	assert_null(DoodlesStage.make_doodle("no_such_doodle"))


func test_every_doodle_stands_centred_on_its_origin_and_fits_its_room() -> void:
	for id in DoodlesStage.all_ids():
		var doodle := DoodlesStage.make_doodle(id)
		var bounds := _bounds(doodle)
		doodle.free()
		assert_lte(bounds.end.y, SLACK, "%s hangs no lower than its baseline" % id)
		assert_lte(-bounds.position.y, TALLEST, "%s is no taller than the room" % id)
		assert_almost_eq(bounds.get_center().x, 0.0, SLACK, "%s is centred on its origin" % id)
		assert_lte(bounds.size.x * 0.5, HALF_WIDTH, "%s is no wider than the room" % id)


func test_the_first_doodle_goes_left_over_the_first_option() -> void:
	var stage := _staged()
	assert_true(stage.slots[0].get_child(0) is GiantDuck)
	assert_true(stage.slots[1].get_child(0) is TinyHorses)
	assert_eq(stage.words[0].text, "The giant duck")
	assert_eq(stage.words[1].text, "The tiny horses")
	assert_lt(stage.slots[0].position.x, stage.slots[1].position.x)


func test_pointing_at_a_doodle_while_choosing_hovers_its_option() -> void:
	var stage := _staged()
	stage.set_choosing(true)
	watch_signals(stage)
	stage._unhandled_input(_motion(stage.option_point(1)))
	assert_signal_emitted_with_parameters(stage, "option_hovered", [1])


func test_clicking_a_doodle_while_choosing_commits_its_option() -> void:
	var stage := _staged()
	stage.set_choosing(true)
	watch_signals(stage)
	stage._unhandled_input(_press(stage.option_point(0)))
	assert_signal_emitted_with_parameters(stage, "option_committed", [0])


func test_the_doodles_ignore_the_pointer_until_choosing() -> void:
	var stage := _staged()
	watch_signals(stage)
	stage._unhandled_input(_motion(stage.option_point(0)))
	stage._unhandled_input(_press(stage.option_point(0)))
	assert_signal_not_emitted(stage, "option_hovered")
	assert_signal_not_emitted(stage, "option_committed")


## A doodles stage in the tree, set up for the duck or the horses.
func _staged() -> DoodlesStage:
	var stage := (load(STAGE_SCENE) as PackedScene).instantiate() as DoodlesStage
	add_child_autofree(stage)
	var question := QuestionData.new()
	question.stage = {"type": "doodles", "doodles": ["giant_duck", "tiny_horses"]}
	for label: String in ["The giant duck", "The tiny horses"]:
		var option := OptionData.new()
		option.label = label
		question.options.append(option)
	stage.setup(question)
	return stage


func _motion(at: Vector2) -> InputEventMouseMotion:
	var motion := InputEventMouseMotion.new()
	motion.position = at
	return motion


func _press(at: Vector2) -> InputEventMouseButton:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = at
	return press


## The box around every point of [param doodle]'s lines.
func _bounds(doodle: InkDrawing) -> Rect2:
	var lines := doodle._build_lines(InkStyle.get_default(), InkPalette.get_default())
	var box := Rect2(lines[0].path[0], Vector2.ZERO)
	for line in lines:
		for point in line.path:
			box = box.expand(point)
	return box
