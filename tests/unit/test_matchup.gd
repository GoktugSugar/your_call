extends GutTest
## Who Would Win's matchup stage: crowds, the walking button as a fighter, everyone the player has
## killed as one mob, the ask picked by what the run remembers, and the bar voted in each side's colour.

const MATCHUP_SCENE := "res://stages/matchup/matchup_stage.tscn"


func test_a_side_of_many_is_a_crowd_of_at_most_the_most() -> void:
	var stage := _matchup([{"doodle": "brawler", "count": 100, "role": "blue"}, {"doodle": "gorilla", "role": "secondary"}])
	assert_eq(_copies(stage, 0), stage.crowd_most)
	assert_eq(_copies(stage, 1), 1)


func test_a_small_crowd_draws_every_one_of_them() -> void:
	var stage := _matchup([{"doodle": "brawler", "count": 5, "role": "blue"}, {"doodle": "boxer", "role": "red"}])
	assert_eq(_copies(stage, 0), 5)


func test_a_side_takes_its_colour() -> void:
	var stage := _matchup([{"doodle": "brawler", "count": 3, "role": "green"}, {"doodle": "boxer", "role": "red"}])
	var copy := stage.slots[0].get_child(0).get_child(0)
	assert_eq(copy.get(&"role"), &"green")


func test_the_walking_button_stands_as_a_fighter() -> void:
	var stage := _matchup([{"doodle": "brawler", "role": "green"}, {"button": true, "role": "green"}])
	var group := stage.slots[1].get_child(0)
	assert_true(group.get_child(0) is WalkingButton)
	assert_true((group.get_child(0) as WalkingButton).alive)


func test_everyone_killed_stands_as_one_mob_counted_in_the_label() -> void:
	var run := RunState.new()
	run.kills.add(&"soul", 30)
	var stage := _matchup([{"doodle": "brawler", "kills": true, "role": "red"}, {"doodle": "brawler", "role": "green"}],
			["all {kills} you killed", "You"], run)
	assert_eq(_copies(stage, 0), stage.crowd_most)
	assert_eq(stage.words[0].text, "all 30 you killed")
	assert_eq(stage.option_labels()[0], "all 30 you killed")


func test_the_ask_follows_what_the_run_remembers() -> void:
	var data := {"asks": [{"if": "button_shot", "ask": "shot"}, {"ask": "spared"}]}
	var spared := _matchup([{"doodle": "brawler"}, {"button": true}], ["You", "the button"], RunState.new(), data)
	assert_eq(spared.ask_key(), &"spared")
	var run := RunState.new()
	run.remember(RunState.BUTTON_SHOT)
	var shot := _matchup([{"doodle": "brawler"}, {"button": true}], ["You", "the button"], run, data)
	assert_eq(shot.ask_key(), &"shot")


func test_the_bar_votes_in_each_side_s_colour() -> void:
	var stage := _matchup([{"doodle": "brawler", "count": 100, "role": "blue"}, {"doodle": "gorilla", "role": "secondary"}])
	var split := stage.reveal_split(1)
	assert_eq(split.roles, [&"blue", &"secondary"])
	assert_eq(split.pick, 1)


func test_the_sides_say_vs() -> void:
	var stage := _matchup([{"doodle": "brawler"}, {"doodle": "gorilla"}])
	assert_eq(stage.or_label.text, "vs")


## How many drawings stand on [param side] of [param stage].
func _copies(stage: MatchupStage, side: int) -> int:
	return stage.slots[side].get_child(0).get_child_count()


func _matchup(sides: Array, labels := ["Left", "Right"], run := RunState.new(), extra := {}) -> MatchupStage:
	var question := QuestionData.new()
	question.id = &"matchup"
	question.stage = {"type": "matchup", "sides": sides}
	question.stage.merge(extra)
	for i in labels.size():
		var option := OptionData.new()
		option.id = StringName("side_%d" % i)
		option.label = labels[i]
		option.crowd = 50.0
		question.options.append(option)
	var stage := (load(MATCHUP_SCENE) as PackedScene).instantiate() as MatchupStage
	stage.run = run
	add_child_autofree(stage)
	stage.setup(question)
	return stage
