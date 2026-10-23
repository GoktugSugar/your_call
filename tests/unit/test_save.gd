extends GutTest
## The save: what the run remembers comes back whole through a save file, a save is only picked up while
## the run still has its beat, anything unreadable counts as no save, the record of endings keeps each
## ending once, and the auto save keeps the moment each beat began and, at an ending, the moment the last
## choice began, so the run picks up just before it.

const SAVE_PATH := "user://tests/run.json"
const RECORD_PATH := "user://tests/endings.json"


func before_each() -> void:
	RunSave.path = SAVE_PATH
	EndingsRecord.path = RECORD_PATH
	SaveData.remove(SAVE_PATH)
	SaveData.remove(RECORD_PATH)


func after_each() -> void:
	SaveData.remove(SAVE_PATH)
	SaveData.remove(RECORD_PATH)
	RunSave.path = RunSave.DEFAULT_PATH
	EndingsRecord.path = EndingsRecord.DEFAULT_PATH
	RunSave.pending = null


func test_what_the_run_remembers_comes_back_whole() -> void:
	var run := _remembering_run()
	var back := RunState.from_data(JSON.parse_string(JSON.stringify(run.to_data())))
	assert_not_null(back)
	if back == null:
		return
	assert_eq(back.profile.leanings, run.profile.leanings)
	assert_eq(back.kills.count, 4)
	assert_eq(back.kills.kinds, run.kills.kinds)
	assert_true(back.remembers(&"button_woke"))
	assert_true(back.remembers(&"class_bard"))
	assert_false(back.remembers(&"button_shot"))
	assert_eq(back.wallet.start, 10000)
	assert_eq(back.wallet.balance, 6200)
	assert_eq(back.wallet.bought.size(), 2)
	assert_eq(back.wallet.bought[1].id, &"years")
	assert_eq(back.wallet.bought[1].units, 3)
	assert_eq(back.wallet.bought[1].buyback_share, 25.0)
	assert_eq(back.wallet.passed.size(), 1)
	assert_eq(back.wallet.passed[0].label, "Charisma")


func test_a_run_with_no_wallet_open_comes_back_without_one() -> void:
	var run := RunState.new()
	run.remember(&"button_woke")
	var back := RunState.from_data(JSON.parse_string(JSON.stringify(run.to_data())))
	assert_not_null(back)
	if back != null:
		assert_null(back.wallet)


func test_a_save_is_picked_up_at_its_beat() -> void:
	assert_true(RunSave.write(RunSave.snapshot(&"c2", &"c2_q3", _remembering_run())))
	var save := RunSave.load_valid(_chapters())
	assert_not_null(save)
	if save == null:
		return
	assert_eq(save.chapter, &"c2")
	assert_eq(save.beat, &"c2_q3")
	assert_true(save.run.remembers(&"button_woke"))


func test_a_save_whose_beat_the_run_no_longer_has_is_no_save() -> void:
	RunSave.write(RunSave.snapshot(&"c2", &"gone", RunState.new()))
	assert_null(RunSave.load_valid(_chapters()))
	RunSave.write(RunSave.snapshot(&"c9", &"c2_q1", RunState.new()))
	assert_null(RunSave.load_valid(_chapters()))


func test_a_save_of_another_version_is_no_save() -> void:
	var data := RunSave.snapshot(&"c1", &"c1_q1", RunState.new())
	data["version"] = RunSave.VERSION + 1
	RunSave.write(data)
	assert_null(RunSave.load_valid(_chapters()))


func test_an_unreadable_save_is_no_save() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_PATH.get_base_dir())
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string("{ \"version\": 1, \"chapter\": ")
	file.close()
	assert_null(RunSave.load_valid(_chapters()))


func test_a_save_with_a_broken_run_is_no_save() -> void:
	var data := RunSave.snapshot(&"c1", &"c1_q1", RunState.new())
	data["run"]["kills"] = {"stranger": "lots"}
	RunSave.write(data)
	assert_null(RunSave.load_valid(_chapters()))


func test_no_file_is_no_save_and_clearing_forgets_it() -> void:
	assert_null(RunSave.load_valid(_chapters()))
	RunSave.write(RunSave.snapshot(&"c1", &"c1_q1", RunState.new()))
	RunSave.clear()
	assert_null(RunSave.load_valid(_chapters()))


func test_a_write_cut_short_before_the_move_still_reads() -> void:
	RunSave.write(RunSave.snapshot(&"c1", &"c1_q2", RunState.new()))
	DirAccess.rename_absolute(SAVE_PATH, SAVE_PATH + SaveData.WRITING)
	var save := RunSave.load_valid(_chapters())
	assert_not_null(save)
	if save != null:
		assert_eq(save.beat, &"c1_q2")


func test_continue_hands_its_save_over_once() -> void:
	RunSave.pending = RunSave.new()
	assert_not_null(RunSave.take_pending())
	assert_null(RunSave.take_pending())


func test_each_ending_is_recorded_once_in_the_order_reached() -> void:
	EndingsRecord.add(&"baby")
	EndingsRecord.add(&"dollar")
	EndingsRecord.add(&"baby")
	assert_eq(EndingsRecord.seen(), PackedStringArray(["baby", "dollar"]))


func test_the_auto_save_keeps_the_moment_each_beat_began() -> void:
	var parts := _auto_save()
	var player: RunPlayer = parts[0]
	var saver: AutoSave = parts[1]
	var chapter: ChapterData = _chapters()[1]
	player.chapter_started.emit(chapter)
	player.beat_started.emit(chapter.beats[2])
	saver.run.remember(&"button_shot")
	var save := RunSave.load_valid(_chapters())
	assert_not_null(save)
	if save == null:
		return
	assert_eq(save.beat, &"c2_q3")
	assert_false(save.run.remembers(&"button_shot"), "what changed during the beat waits for the next one")
	assert_true(saver.save_now())
	assert_false(RunSave.load_valid(_chapters()).run.remembers(&"button_shot"), "Save keeps the beat's start again")


func test_an_ending_keeps_the_save_at_the_choice_that_fired_it_and_is_recorded() -> void:
	var parts := _auto_save()
	var player: RunPlayer = parts[0]
	var saver: AutoSave = parts[1]
	player.chapter_started.emit(_chapters()[0])
	player.beat_started.emit(_chapters()[0].beats[1])
	saver.run.remember(&"pulled_baby")
	player.ending_reached.emit(&"baby")
	var save := RunSave.load_valid(_chapters())
	assert_not_null(save, "the run can be picked up after an ending")
	if save != null:
		assert_eq(save.beat, &"c1_q2")
		assert_false(save.run.remembers(&"pulled_baby"), "it picks up as the choice began")
	assert_eq(EndingsRecord.seen(), PackedStringArray(["baby"]))
	assert_false(saver.can_save(), "the pause has nothing to save after an ending")


func test_an_ending_a_tableau_fires_picks_up_at_the_last_choice_before_it() -> void:
	var parts := _auto_save()
	var player: RunPlayer = parts[0]
	var saver: AutoSave = parts[1]
	var chapter: ChapterData = _chapters()[1]
	player.chapter_started.emit(chapter)
	player.beat_started.emit(chapter.beats[3])
	saver.run.remember(&"pulled_lever")
	player.beat_started.emit(chapter.beats[4])
	player.ending_reached.emit(&"posted_lever")
	var save := RunSave.load_valid(_chapters())
	assert_not_null(save)
	if save != null:
		assert_eq(save.beat, &"c2_q4", "the posting is no choice: the lever before it is")
		assert_false(save.run.remembers(&"pulled_lever"))


func test_an_auto_save_turned_off_never_touches_the_save() -> void:
	RunSave.write(RunSave.snapshot(&"c1", &"c1_q2", RunState.new()))
	var parts := _auto_save()
	var player: RunPlayer = parts[0]
	var saver: AutoSave = parts[1]
	saver.enabled = false
	player.chapter_started.emit(_chapters()[1])
	player.beat_started.emit(_chapters()[1].beats[0])
	player.ending_reached.emit(&"baby")
	var save := RunSave.load_valid(_chapters())
	assert_not_null(save)
	if save != null:
		assert_eq(save.beat, &"c1_q2")
	assert_eq(EndingsRecord.seen(), PackedStringArray())


## A run player and an auto save on it, the save remembering a fresh run.
func _auto_save() -> Array:
	var player := RunPlayer.new()
	add_child_autofree(player)
	var saver := AutoSave.new()
	saver.run_player = player
	add_child_autofree(saver)
	saver.run = RunState.new()
	return [player, saver]


func _remembering_run() -> RunState:
	var run := RunState.new()
	run.profile.apply({&"head_heart": -0.5, &"risk_safety": 1.25})
	run.kills.add(&"stranger", 3)
	run.kills.add(&"bear")
	run.remember(&"button_woke")
	run.remember(&"class_bard")
	var wallet := run.open_wallet(10000)
	wallet.buy(Purchase.make(&"charisma_no", "Ten More IQ", "brain", 2800))
	var years := Purchase.make(&"years", "A stranger's years", "hourglass", 1000)
	years.units = 3
	years.buyback_share = 25.0
	wallet.buy(years)
	wallet.pass_on(Purchase.make(&"charisma", "Charisma", "smile", 1500))
	return run


## Two chapters of three and five questions, ids c1 and c2, beats c1_q1 and on. Each has an option to
## choose, but the second chapter's last, a tableau.
func _chapters() -> Array[ChapterData]:
	var chapters: Array[ChapterData] = []
	for count in [3, 5]:
		var chapter := ChapterData.new()
		chapter.id = StringName("c%d" % (chapters.size() + 1))
		for i in count:
			var question := QuestionData.new()
			question.id = StringName("%s_q%d" % [chapter.id, i + 1])
			if not (count == 5 and i == count - 1):
				question.options.append(OptionData.new())
			chapter.beats.append(question)
		chapters.append(chapter)
	return chapters
