extends GutTest
## The Portrait: a leaning read against how often its axis came up and some doubt, the portrait kept
## whole in the save (an older save's too), and the posting the strongest leaning earns, or the imp's job
## when nothing leans far.

const STAGE_SCENE := "res://stages/posting/posting_stage.tscn"
const POSTINGS := {"one_many": ["plea", "lever"], "mercy_justice": ["curtain", "gavel"],
		"risk_safety": ["pin", "paper"]}


func test_a_leaning_is_read_against_how_often_its_axis_came_up() -> void:
	var profile := Profile.new()
	profile.apply({&"one_many": 1.0})
	profile.apply({&"one_many": 1.0})
	profile.apply({&"one_many": -1.0})
	assert_almost_eq(profile.lean(&"one_many"), 1.0 / 3.0, 0.001)
	assert_almost_eq(profile.lean(&"one_many", 1.0), 0.25, 0.001)
	assert_eq(profile.lean(&"risk_safety"), 0.0)


func test_doubt_keeps_an_axis_that_came_up_once_from_reading_as_all_the_way_over() -> void:
	var profile := Profile.new()
	profile.apply({&"self_others": 0.3})
	assert_almost_eq(profile.lean(&"self_others"), 1.0, 0.001)
	assert_lt(profile.lean(&"self_others", 2.0), 0.2)


func test_the_portrait_comes_back_whole_from_the_save() -> void:
	var profile := Profile.new()
	profile.apply({&"one_many": 1.0, &"risk_safety": -0.5})
	profile.apply({&"one_many": -0.5})
	var restored := Profile.new()
	restored.load_data(JSON.parse_string(JSON.stringify(profile.to_data())))
	assert_eq(restored.leanings, profile.leanings)
	assert_eq(restored.reach, profile.reach)


func test_an_older_save_of_leanings_alone_still_loads() -> void:
	var restored := Profile.new()
	restored.load_data({"one_many": 2.0, "risk_safety": -1.0})
	assert_eq(restored.leanings, {&"one_many": 2.0, &"risk_safety": -1.0})
	assert_almost_eq(restored.lean(&"risk_safety"), -1.0, 0.001)
	assert_true(Profile.is_valid_data({"one_many": 2.0}))
	assert_false(Profile.is_valid_data({"leanings": {"one_many": "lots"}}))


func test_the_strongest_leaning_picks_the_posting_for_its_pole() -> void:
	var profile := Profile.new()
	for i in 6:
		profile.apply({&"mercy_justice": 1.0})
	profile.apply({&"one_many": -1.0})
	assert_eq(_posting_stage().posting_for(profile), &"gavel")
	var other := Profile.new()
	for i in 6:
		other.apply({&"risk_safety": -1.0})
	assert_eq(_posting_stage().posting_for(other), &"pin")


func test_a_portrait_that_leans_nowhere_far_takes_the_imps_job() -> void:
	var profile := Profile.new()
	profile.apply({&"one_many": 1.0})
	profile.apply({&"one_many": -1.0})
	assert_eq(_posting_stage().posting_for(profile), &"imp")
	assert_eq(_posting_stage().posting_for(Profile.new()), &"imp")


func _posting_stage() -> PostingStage:
	var stage := (load(STAGE_SCENE) as PackedScene).instantiate() as PostingStage
	autofree(stage)
	var question := QuestionData.new()
	question.stage = {"type": "posting", "nowhere": 0.2, "nowhere_posting": "imp", "postings": POSTINGS}
	stage.question = question
	return stage
