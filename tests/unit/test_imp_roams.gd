extends GutTest
## The imp roams when the page is his: with no stage up he steps forward to the middle, a long trip a run
## of hops, and his hops on the spot then keep near where he wandered; with a stage up, or shot, he keeps
## where he is; and before a stage he hops home to his wing.

const IMP_SCENE := "res://figures/imp/imp.tscn"

var _imp: Imp


func before_each() -> void:
	_imp = (load(IMP_SCENE) as PackedScene).instantiate() as Imp
	_imp.hop_seed = 7
	_imp.min_stay = 0.0
	_imp.roam_stay = 0.0
	# Quick hops and a quick entrance, so the tests do not wait on his timing.
	_imp.hop_duration = 0.02
	_imp.hop_windup = 0.0
	_imp.land_squash_time = 0.0
	_imp.hop_settle = 0.0
	_imp.stride_settle = 0.0
	_imp.scribble_duration = 0.05
	_imp.pop_settle = 0.0
	add_child_autofree(_imp)
	await _imp.appear(Imp.Wing.RIGHT)


func test_with_a_stage_up_he_keeps_to_his_wing() -> void:
	_imp.free_to_roam = false
	_imp.forward_chance = 1.0
	for i in 5:
		await _imp.hop_for_line()
		assert_true(_imp.right_wing.has_point(_imp.position), "line %d at %s" % [i, _imp.position])


func test_once_the_page_is_his_he_steps_forward_to_the_middle() -> void:
	_imp.free_to_roam = true
	_imp.forward_chance = 1.0
	await _imp.hop_for_line()
	assert_true(_imp.middle.has_point(_imp.position), str(_imp.position))


func test_a_long_trip_is_a_run_of_hops() -> void:
	watch_signals(_imp)
	var target := _imp.middle.get_center()
	var hops := ceili(_imp.position.distance_to(target) / _imp.stride)
	await _imp.travel_to(target)
	assert_gt(hops, 1)
	assert_signal_emit_count(_imp, "landed", hops)
	assert_lt(_imp.position.distance_to(target), 1.0)


func test_out_on_the_floor_his_hops_on_the_spot_keep_near_where_he_wandered() -> void:
	_imp.free_to_roam = true
	_imp.forward_chance = 1.0
	_imp.roam_chance = 0.0
	await _imp.hop_for_line()
	var spot := _imp.position
	for i in 4:
		await _imp.hop_for_line()
		assert_lt(absf(_imp.position.x - spot.x), _imp.roam_room.x, "line %d at %s" % [i, _imp.position])


func test_before_a_stage_he_hops_home_to_his_wing() -> void:
	_imp.free_to_roam = true
	_imp.forward_chance = 1.0
	await _imp.hop_for_line()
	_imp.free_to_roam = false
	await _imp.go_home()
	assert_true(_imp.right_wing.has_point(_imp.position), str(_imp.position))


func test_shot_he_stays_where_he_is() -> void:
	_imp.free_to_roam = true
	_imp.forward_chance = 1.0
	_imp.rounded = true
	var where := _imp.position
	await _imp.hop_for_line()
	assert_eq(_imp.position, where)
