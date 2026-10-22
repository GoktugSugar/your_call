extends GutTest
## The gun chapter: the gun stage's shots and what lowering it leads to, hidden options, the kill tally
## and what skipped chapters leave behind.

const GUN_SCENE := "res://stages/gun/gun_stage.tscn"


func test_shooting_a_target_reports_it_and_counts_the_kill() -> void:
	var stage := _gun({"targets": [_target("man", 640.0), _target("other", 1200.0)]},
			[{"shoot": "man"}, {"shoot": "other"}])
	assert_eq(await stage.play_consequence(0), &"man")
	assert_eq(stage.run.kills.count, 1)
	assert_true(stage.run.kills.has(&"stranger"))


func test_lowering_the_gun_holds_and_kills_nobody() -> void:
	var stage := _gun({"targets": [_target("man", 960.0)]}, [{"shoot": "man"}, {"hold": true}])
	assert_eq(await stage.play_consequence(1), &"held")
	assert_eq(stage.run.kills.count, 0)


func test_an_empty_gun_only_clicks() -> void:
	var stage := _gun({"empty": true, "targets": [_target("them", 960.0)]}, [{"shoot": "them"}, {"hold": true}])
	assert_eq(await stage.play_consequence(0), &"click")
	assert_eq(stage.run.kills.count, 0)


func test_turned_on_the_player_it_frames_the_view_and_nothing_dies() -> void:
	var stage := _gun({"targets": []}, [{"shoot": "self"}, {"hold": true}])
	assert_true(stage.option_point(0).is_finite())
	assert_eq(await stage.play_consequence(0), &"self")
	assert_eq(stage.run.kills.count, 0)


func test_firing_blind_from_the_row_hits_one_of_them_and_the_reveal_names_it() -> void:
	var targets: Array = []
	for colour: String in ["red", "blue", "green"]:
		var entry := _target(colour, 600.0 + targets.size() * 300.0)
		entry["role"] = colour
		entry["crowd"] = 20
		entry["label"] = colour
		targets.append(entry)
	var stage := _gun({"targets": targets}, [{"shoot": "any"}, {"hold": true}])
	var hit := await stage.play_consequence(0)
	assert_true(String(hit) in ["red", "blue", "green"], "hit %s" % hit)
	var split := stage.reveal_split(0)
	assert_eq(split.labels, PackedStringArray(["red", "blue", "green", "held the shot"]))
	assert_eq(split.labels[split.pick], String(hit))
	assert_eq(split.roles[0], &"red")


func test_an_armed_target_answers_a_lowered_gun() -> void:
	var fires := _gun({"fires_back": 100, "targets": [_target("armed", 960.0)]}, [{"shoot": "armed"}, {"hold": true}])
	assert_eq(await fires.play_consequence(1), &"fired")
	var holds := _gun({"fires_back": 0, "targets": [_target("armed", 960.0)]}, [{"shoot": "armed"}, {"hold": true}])
	assert_eq(await holds.play_consequence(1), &"lowered")


func test_a_dying_target_dies_anyway_but_is_not_the_player_s_kill() -> void:
	var stage := _gun({"dies_anyway": true, "targets": [_target("dying", 960.0)]}, [{"shoot": "dying"}, {"hold": true}])
	assert_eq(await stage.play_consequence(1), &"held")
	assert_eq(stage.run.kills.count, 0)


func test_alone_the_gun_lowers_itself_when_time_runs_out() -> void:
	var stage := _gun({"alone": {"seconds": 0.05}, "targets": [_target("person", 960.0)]}, [{"shoot": "person"}, {"hold": true}])
	assert_true(stage.chooses_alone())
	stage.set_choosing(true)
	var picked := await stage.choose()
	# Out of the signal's emission before the stage is freed with the test.
	await get_tree().process_frame
	assert_eq(picked, 1)


func test_the_charging_thing_is_the_button_and_remembers_how_it_went() -> void:
	var shot := _gun({"charge": {"seconds": 6}, "targets": [{"id": "thing", "doodle": "question_mark", "x": 960}]},
			[{"shoot": "thing"}, {"hold": true}])
	assert_eq(await shot.play_consequence(0), &"shot")
	assert_true(shot.run.remembers(RunState.BUTTON_SHOT))
	var again := _gun({"charge": {"seconds": 6}, "targets": [{"id": "thing", "doodle": "question_mark", "x": 960}]},
			[{"shoot": "thing"}, {"hold": true}])
	again.run.remember(RunState.BUTTON_WOKE)
	assert_eq(await again.play_consequence(0), &"shot_again")
	var waved := _gun({"charge": {"seconds": 6}, "targets": [{"id": "thing", "doodle": "question_mark", "x": 960}]},
			[{"shoot": "thing"}, {"hold": true}])
	assert_eq(await waved.play_consequence(1), &"waved")
	assert_true(waved.run.remembers(RunState.BUTTON_SPARED))


func test_a_hidden_option_stays_out_of_the_row_and_the_reveal() -> void:
	var question := _question({"type": "gun", "targets": []}, [{"shoot": "man"}, {"shoot": "imp"}, {"shoot": "bear"}])
	question.options[1].hidden = true
	assert_eq(question.shown_options(), PackedInt32Array([0, 2]))
	var split := RevealSplit.of(question, 2)
	assert_eq(split.labels.size(), 2)
	assert_eq(split.pick, 1)


func test_the_choice_row_can_be_dismissed_with_no_pick() -> void:
	var row := (load("res://ui/choices/choice_row.tscn") as PackedScene).instantiate() as ChoiceRow
	add_child_autofree(row)
	watch_signals(row)
	row.offer(PackedStringArray(["Shoot the man", "Shoot the bear"]), Rect2(400.0, 900.0, 1100.0, 120.0))
	row.dismiss()
	assert_signal_emitted_with_parameters(row, "committed", [-1])
	assert_false(row.is_offering())


func test_the_kill_tally_counts_by_kind() -> void:
	var kills := KillTally.new()
	kills.add(&"soul", 5)
	kills.add(&"bear")
	kills.add(&"people", 0)
	assert_eq(kills.count, 6)
	assert_true(kills.has(&"bear"))
	assert_false(kills.has(&"people"))


func test_a_run_takes_what_a_skipped_chapter_leaves_behind() -> void:
	var chapter := ChapterData.new()
	chapter.if_skipped = {"remember": ["button_woke"], "kills": {"stranger": 2}}
	var run := RunState.new()
	run.assume(chapter)
	assert_true(run.remembers(RunState.BUTTON_WOKE))
	assert_eq(run.kills.count, 2)


func _target(id: String, x: float) -> Dictionary:
	return {"id": id, "kind": "stranger", "x": x}


## A gun stage in the tree for [param stage_data], with an option per outcome in [param outcomes],
## quick in everything it does.
func _gun(stage_data: Dictionary, outcomes: Array) -> GunStage:
	var data := {"type": "gun"}
	data.merge(stage_data, true)
	var stage := (load(GUN_SCENE) as PackedScene).instantiate() as GunStage
	stage.aim_seed = 7
	for property: String in ["aim_time", "kick_time", "jolt_time", "lower_time", "flash_time", "reveal_time", "arrive_time"]:
		stage.set(property, 0.02)
	for property: String in ["aim_hold", "settle", "slow_death", "answer_after"]:
		stage.set(property, 0.0)
	stage.run = RunState.new()
	add_child_autofree(stage)
	stage.setup(_question(data, outcomes))
	return stage


func _question(stage_data: Dictionary, outcomes: Array) -> QuestionData:
	var question := QuestionData.new()
	question.id = &"gun"
	question.stage = stage_data
	question.reveal_labels = PackedStringArray()
	for i in outcomes.size():
		var option := OptionData.new()
		option.id = StringName("option_%d" % i)
		option.label = "Option %d" % i
		option.outcome = outcomes[i]
		option.crowd = 100.0 / outcomes.size()
		question.options.append(option)
	if outcomes.size() == 2:
		question.reveal_labels = PackedStringArray(["fired", "held the shot"])
	return question
