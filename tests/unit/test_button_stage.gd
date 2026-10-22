extends GutTest
## The button stage in 2.11: pressed, the walking button comes alive and the imp is taken aback; left
## be, nothing stirs.

const SCENE := "res://stages/button/button_stage.tscn"
const CHAPTER := "res://content/chapters/ch2_buttons.json"
## How many times faster than life the tests run it.
const FAST := 10.0
## Seconds to wait for the imp's face before giving up.
const MAX_WAIT := 5.0

var _time_scale := 1.0


func before_each() -> void:
	_time_scale = Engine.time_scale
	Engine.time_scale = FAST


func after_each() -> void:
	Engine.time_scale = _time_scale


## The stage set up for 2.11, The Button That Walks Away: option 0 presses it, option 1 leaves it be.
func _stage() -> ButtonStage:
	var chapter := ContentLoader.new(Profile.axis_ids()).load_chapter(CHAPTER)
	var stage := (load(SCENE) as PackedScene).instantiate() as ButtonStage
	add_child_autofree(stage)
	stage.setup(chapter.find_beat(&"walks_away") as QuestionData)
	return stage


func test_the_imp_is_taken_aback_when_the_button_comes_alive() -> void:
	var stage := _stage()
	watch_signals(stage)
	stage.play_consequence(0)
	assert_true(await wait_for_signal(stage.imp_face_cued, MAX_WAIT), "the imp's face is cued")
	assert_signal_emitted_with_parameters(stage, "imp_face_cued", [&"surprised"])


func test_leaving_the_button_be_leaves_the_imp_alone() -> void:
	var stage := _stage()
	watch_signals(stage)
	await stage.play_consequence(1)
	assert_signal_not_emitted(stage, "imp_face_cued")
