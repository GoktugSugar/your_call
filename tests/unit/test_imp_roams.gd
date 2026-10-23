extends GutTest
## The imp floats and roams when the page is his: with no stage up he warps forward to the middle, and
## his drifts for each page then keep near where he wandered; with a stage up, or shot, he keeps where he
## is; and before a stage he warps home to his wing. A warp leaves a copy of him soaking away where he
## was, gone once he is whole again; a warp stopped short never leaves anyone waiting on it.

const IMP_SCENE := "res://figures/imp/imp.tscn"

var _imp: Imp


func before_each() -> void:
	_imp = (load(IMP_SCENE) as PackedScene).instantiate() as Imp
	_imp.move_seed = 7
	_imp.min_stay = 0.0
	_imp.roam_stay = 0.0
	# Quick moves and a quick entrance, so the tests do not wait on his timing.
	var motion := _imp.get_node(^"Motion") as ImpMotion
	motion.drift_time = Vector2(0.02, 0.02)
	motion.soak_time = 0.02
	motion.ink_time = 0.02
	motion.pop_settle = 0.0
	_imp.scribble_duration = 0.05
	_imp.pop_settle = 0.0
	add_child_autofree(_imp)
	await _imp.appear(Imp.Wing.RIGHT)


func test_he_floats_off_the_ground_with_his_legs_hanging() -> void:
	await wait_process_frames(2)
	assert_lt(_imp.drawing.position.y, -_imp.motion.float_height + _imp.motion.float_bob + 0.01)
	assert_eq(_imp.drawing.dangle, 1.0)


func test_with_a_stage_up_he_keeps_to_his_wing() -> void:
	_imp.free_to_roam = false
	_imp.forward_chance = 1.0
	for i in 5:
		await _imp.move_for_line()
		assert_true(_imp.right_wing.has_point(_imp.position), "line %d at %s" % [i, _imp.position])


func test_once_the_page_is_his_he_warps_forward_to_the_middle() -> void:
	_imp.free_to_roam = true
	_imp.forward_chance = 1.0
	await _imp.move_for_line()
	assert_true(_imp.middle.has_point(_imp.position), str(_imp.position))


func test_a_long_trip_is_one_warp_that_leaves_a_copy_soaking_away() -> void:
	watch_signals(_imp)
	var target := _imp.middle.get_center()
	var before := get_child_count()
	_imp.warp_to(target)
	assert_eq(get_child_count(), before + 1, "a copy of him is left where he was")
	assert_eq(_imp.drawing.reveal, 0.0, "his lines start again from nothing where he goes")
	await wait_for_signal(_imp.arrived, 2.0)
	await wait_process_frames(1)
	assert_signal_emit_count(_imp, "arrived", 1)
	assert_eq(_imp.position, target)
	assert_eq(_imp.drawing.reveal, 1.0)
	assert_eq(get_child_count(), before, "the copy is gone")


func test_a_page_s_move_is_a_drift_in_his_wing_with_no_copy_left() -> void:
	var before := get_child_count()
	watch_signals(_imp)
	await _imp.move_if_settled()
	assert_eq(get_child_count(), before)
	assert_signal_emit_count(_imp, "arrived", 1)
	assert_true(_imp.right_wing.has_point(_imp.position), str(_imp.position))


func test_a_warp_stopped_short_lets_go_and_leaves_him_whole() -> void:
	var motion := _imp.motion
	motion.soak_time = 5.0
	motion.ink_time = 5.0
	watch_signals(_imp)
	var waited := [false]
	var trip := func() -> void:
		await _imp.warp_to(_imp.middle.get_center())
		waited[0] = true
	trip.call()
	motion.stop()
	await wait_process_frames(1)
	assert_true(waited[0], "whoever waited on the warp is let go")
	assert_signal_not_emitted(_imp, "arrived")
	assert_false(_imp.is_moving())
	assert_eq(_imp.drawing.reveal, 1.0)
	assert_eq(_imp.scale, Vector2.ONE)


func test_out_on_the_floor_his_drifts_keep_near_where_he_wandered() -> void:
	_imp.free_to_roam = true
	_imp.forward_chance = 1.0
	_imp.roam_chance = 0.0
	await _imp.move_for_line()
	var spot := _imp.position
	for i in 4:
		await _imp.move_for_line()
		assert_lt(absf(_imp.position.x - spot.x), _imp.roam_room.x, "line %d at %s" % [i, _imp.position])


func test_before_a_stage_he_warps_home_to_his_wing() -> void:
	_imp.free_to_roam = true
	_imp.forward_chance = 1.0
	await _imp.move_for_line()
	_imp.free_to_roam = false
	await _imp.go_home()
	assert_true(_imp.right_wing.has_point(_imp.position), str(_imp.position))


func test_shot_he_stays_where_he_is() -> void:
	_imp.free_to_roam = true
	_imp.forward_chance = 1.0
	_imp.rounded = true
	var where := _imp.position
	await _imp.move_for_line()
	assert_eq(_imp.position, where)
