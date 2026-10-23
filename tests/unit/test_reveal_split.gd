extends GutTest
## A reveal knows when the player's pick was the least popular, for the imp to say so before it.


func _split(shares: Array, pick: int) -> RevealSplit:
	var split := RevealSplit.new()
	split.shares = PackedFloat32Array(shares)
	split.pick = pick
	return split


func test_the_shortest_bar_is_the_least_popular() -> void:
	assert_true(_split([44, 25, 31], 1).is_least_popular())


func test_any_other_bar_is_not() -> void:
	assert_false(_split([44, 25, 31], 0).is_least_popular())
	assert_false(_split([44, 25, 31], 2).is_least_popular())


func test_a_tie_for_the_shortest_counts() -> void:
	assert_true(_split([50, 25, 25], 2).is_least_popular())


func test_no_pick_is_never_the_least_popular() -> void:
	assert_false(_split([44, 25, 31], -1).is_least_popular())


func test_options_some_runs_do_not_see_have_no_bar_and_the_rest_add_up() -> void:
	var question := QuestionData.new()
	question.reveal_heading = "how others built their hero"
	for entry: Array in [["take", 30.0, ""], ["walk", 50.0, ""], ["knight", 19.0, "class_knight"], ["rogue", 21.0, "class_rogue"]]:
		var option := OptionData.new()
		option.id = StringName(entry[0])
		option.label = entry[0]
		option.crowd = entry[1]
		if entry[2] != "":
			option.requires = PackedStringArray([entry[2]])
		question.options.append(option)
	var run := RunState.new()
	run.remember(&"class_rogue")
	var split := RevealSplit.of(question, 3, run)
	assert_eq(Array(split.labels), ["take", "walk", "rogue"])
	assert_eq(split.pick, 2, "the pick is counted among the bars shown")
	var total := 0.0
	for share in split.shares:
		total += share
	assert_almost_eq(total, RevealSplit.WHOLE, 0.01)

