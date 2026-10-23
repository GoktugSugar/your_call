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
