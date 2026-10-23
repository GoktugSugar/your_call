extends GutTest
## The guess at the room: a guess within the question's reach of the truth is close, under it low, over
## it high, the guess is filed in the run under what it was about, and the run reads how a set of
## guesses ran and the share that made every pick.

const STAGE_SCENE := "res://stages/guess/guess_stage.tscn"


func test_a_guess_near_the_truth_is_close() -> void:
	assert_eq(await _guess(55.0, 51.0), &"close")


func test_a_guess_under_the_truth_is_low() -> void:
	assert_eq(await _guess(20.0, 51.0), &"low")


func test_a_guess_over_the_truth_is_high() -> void:
	assert_eq(await _guess(90.0, 51.0), &"high")


func test_a_guess_is_filed_under_what_it_was_about() -> void:
	var stage := _stage(51.0)
	_answer_soon(stage, 31.0)
	await stage.play_consequence(-1)
	var filed: Dictionary = stage.run.guesses.get(&"wallet", {})
	assert_eq(filed.get("about"), "strangers")
	assert_almost_eq(float(filed.get("gap", 0.0)), -20.0, 0.01)


func test_the_run_reads_how_its_guesses_ran() -> void:
	var run := RunState.new()
	var question := QuestionData.new()
	for guess in [[30.0, 50.0], [40.0, 50.0]]:
		question.id = StringName("q%d" % run.guesses.size())
		run.record_guess(question, &"strangers", guess[0], guess[1])
	assert_almost_eq(run.guess_lean(&"strangers"), -15.0, 0.01)
	assert_eq(run.guess_lean(&"nobody"), 0.0)


func test_the_share_that_made_every_pick_multiplies() -> void:
	var run := RunState.new()
	run.picks = [{"share": 50.0}, {"share": 10.0}, {"share": 80.0}]
	assert_almost_eq(run.odds_of_every_pick(), 0.04, 0.0001)


func test_huge_counts_read_the_way_they_are_said() -> void:
	assert_eq(Numbers.huge(25000.0), "25,000")
	assert_eq(Numbers.huge(5.0e6), "5 million")
	assert_eq(Numbers.huge(3.0e10), "30 billion")
	assert_eq(Numbers.huge(1.0e21), "a thousand billion billion")
	assert_eq(Numbers.huge(9.6e17), "a billion billion")


## Plays a guess of [param guess] at a question whose truth is [param truth], and returns how it came out.
func _guess(guess: float, truth: float) -> StringName:
	var stage := _stage(truth)
	_answer_soon(stage, guess)
	return await stage.play_consequence(-1)


func _stage(truth: float) -> GuessStage:
	var stage := (load(STAGE_SCENE) as PackedScene).instantiate() as GuessStage
	stage.reveal_time = 0.05
	stage.gap_fade = 0.0
	stage.after_hold = 0.0
	add_child_autofree(stage)
	var question := QuestionData.new()
	question.id = &"wallet"
	question.stage = {"type": "guess", "truth": truth, "about": "strangers", "close": 10,
			"gap": {"text": "off by {gap}"}, "exact": {"text": "spot on"}}
	stage.setup(question)
	return stage


## Sets [param guess] on [param stage] just after it starts waiting for one.
func _answer_soon(stage: GuessStage, guess: float) -> void:
	get_tree().create_timer(0.05).timeout.connect(func() -> void: stage.guessed.emit(guess))
