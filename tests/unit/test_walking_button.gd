extends GutTest
## The walking button: dormant it is only a push button; woken it grows limbs, opens its eyes and gets
## up; its words float over it and go where it goes; and walking off takes all of it out of sight.

const SCENE := "res://figures/walking_button/walking_button.tscn"
## How many times faster than life the tests run its motion.
const FAST := 20.0
## Seconds between blinks in the tests, so no blink shuts its eyes while they are being checked.
const NO_BLINKS := 1000.0

var _time_scale := 1.0


func before_each() -> void:
	_time_scale = Engine.time_scale
	Engine.time_scale = FAST


func after_each() -> void:
	Engine.time_scale = _time_scale


func test_dormant_it_is_only_a_push_button() -> void:
	var walker := _walker()
	assert_false(walker.alive)
	assert_eq(_lines(walker.limbs).size(), 0, "no limbs")
	assert_eq(_lines(walker.face).size(), 0, "no eyes")


func test_coming_alive_grows_limbs_and_opens_its_eyes() -> void:
	var walker := _walker()
	watch_signals(walker)
	await walker.come_alive()
	assert_true(walker.alive)
	assert_signal_emitted(walker, "came_alive")
	assert_eq(_lines(walker.limbs).size(), 4, "two legs and two arms")
	assert_eq(_open_eyes(walker).size(), 2, "two open dot eyes")


func test_coming_alive_gets_it_up_on_its_feet() -> void:
	var walker := _walker()
	await walker.come_alive()
	var base := walker.to_local(walker.body.global_position)
	assert_lt(base.y, -walker.limbs.leg_length * 0.5, "its base is up off the ground")
	for foot in [walker.limbs.left_foot, walker.limbs.right_foot]:
		var on_ground := walker.to_local(walker.limbs.to_global(foot))
		assert_almost_eq(on_ground.y, 0.0, walker.tap_height + 0.5, "its feet are on the ground")


func test_saying_puts_words_over_it() -> void:
	var walker := _walker()
	walker.alive = true
	await walker.say("Ow! That [red]hurt[/red].")
	var words := _words(walker)
	assert_not_null(words, "it has words")
	assert_eq(words.label.get_parsed_text(), "Ow! That hurt.")
	var cap_top := walker.body.to_global(walker.body.cap_middle() + Vector2.UP * walker.body.cap_radius)
	assert_lt(words.global_position.y, cap_top.y, "the words float over its cap")
	assert_almost_eq(words.global_position.x, walker.global_position.x, 1.0, "the words are centred over it")


func test_its_words_go_where_it_goes() -> void:
	var walker := _walker()
	walker.alive = true
	await walker.say("Unbelievable.")
	await walker.walk_to(walker.position.x - 300.0)
	assert_almost_eq(_words(walker).global_position.x, walker.global_position.x, 1.0, "its words came along")


func test_fading_its_words_lets_them_go() -> void:
	var walker := _walker()
	walker.alive = true
	await walker.say("Nothing.")
	await walker.fade_words()
	assert_null(_words(walker))


func test_walking_to_a_spot_ends_there_facing_the_way_it_went() -> void:
	var walker := _walker()
	walker.alive = true
	var to := walker.position.x + 333.0
	watch_signals(walker)
	await walker.walk_to(to)
	assert_almost_eq(walker.position.x, to, 0.01)
	assert_eq(walker.facing, 1)
	assert_signal_emitted(walker, "stepped")


func test_walking_off_left_takes_all_of_it_off_the_canvas() -> void:
	var walker := _walker()
	walker.alive = true
	walker.position.x = 300.0
	watch_signals(walker)
	await walker.walk_off(-1)
	assert_signal_emitted(walker, "walked_off")
	assert_lt(_canvas_bounds(walker).end.x, 0.0, "nothing of it is left on the canvas")


func test_walking_off_right_takes_its_words_too() -> void:
	var walker := _walker()
	walker.alive = true
	walker.position.x = walker.get_viewport_rect().end.x - 300.0
	await walker.say("Unbelievable. I did nothing to you. Nothing.")
	await walker.walk_off(1)
	var words := _words(walker)
	var left_of_words := words.global_position.x - words.label.get_content_width() * 0.5
	assert_gt(_canvas_bounds(walker).position.x, walker.get_viewport_rect().end.x, "its body is off the canvas")
	assert_gt(left_of_words, walker.get_viewport_rect().end.x, "and so are its words")


func test_turning_moves_its_eyes_the_way_it_faces() -> void:
	var walker := _walker()
	walker.alive = true
	await walker.face_toward(-1)
	assert_eq(walker.facing, -1)
	assert_eq(_open_eyes(walker).size(), 2, "its eyes are open")
	for eye: InkLine in _open_eyes(walker):
		assert_lt(eye.path[0].x, walker.face.cap_middle.x + walker.face.cap_radius * walker.face.eye_spread,
				"its eyes have slid over to the left")


func test_a_fist_pose_clenches_a_fist() -> void:
	var fist := ButtonArmPose.find(&"fist")
	assert_not_null(fist)
	var walker := _walker()
	walker.alive = true
	await walker.hold_arms(fist)
	var fists := _lines(walker.limbs).filter(func(line: InkLine) -> bool: return line.dot_radius > 0.0)
	assert_eq(fists.size(), 1, "one clenched fist")


func test_an_unknown_pose_is_nothing() -> void:
	assert_null(ButtonArmPose.find(&"no_such_pose"))


## A walking button in the tree, dormant, mid canvas.
func _walker() -> WalkingButton:
	var walker := (load(SCENE) as PackedScene).instantiate() as WalkingButton
	walker.position = Vector2(960.0, 800.0)
	walker.blink_gap = Vector2.ONE * NO_BLINKS
	add_child_autofree(walker)
	return walker


func _lines(drawing: InkDrawing) -> Array[InkLine]:
	return drawing._build_lines(InkStyle.get_default(), InkPalette.get_default())


func _open_eyes(walker: WalkingButton) -> Array:
	return _lines(walker.face).filter(func(line: InkLine) -> bool: return line.dot_radius > 0.0)


## The words it is saying, or null when it says nothing.
func _words(walker: WalkingButton) -> Plea:
	for child in walker.get_children():
		if child is Plea and not child.is_queued_for_deletion():
			return child
	return null


## The box around every point of its body, limbs and face, on the canvas.
func _canvas_bounds(walker: WalkingButton) -> Rect2:
	var box := Rect2(walker.get_global_transform_with_canvas().origin, Vector2.ZERO)
	for drawing: InkDrawing in [walker.body, walker.limbs, walker.face]:
		var to_canvas := drawing.get_global_transform_with_canvas()
		for line in _lines(drawing):
			for point in line.path:
				box = box.expand(to_canvas * point)
	return box
