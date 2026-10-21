extends GutTest
## The silent profile.


func test_nudges_add_up_per_axis() -> void:
	var profile := Profile.new()
	profile.apply({&"one_many": 1.0, &"ends_rules": -1.0})
	profile.apply({&"one_many": 1.0})
	assert_eq(profile.leanings, {&"one_many": 2.0, &"ends_rules": -1.0})


func test_each_nudge_is_announced() -> void:
	var profile := Profile.new()
	watch_signals(profile)
	profile.apply({&"one_many": -1.0})
	assert_signal_emitted_with_parameters(profile, "nudged", [&"one_many", -1.0])


func test_portrait_survives_a_round_trip_through_save_data() -> void:
	var profile := Profile.new()
	profile.apply({&"mercy_justice": 1.0, &"one_many": -2.0})
	var restored := Profile.new()
	restored.load_data(profile.to_data())
	assert_eq(restored.leanings, profile.leanings)


func test_axes_load_from_content() -> void:
	assert_has(Profile.axis_ids(), "one_many")
