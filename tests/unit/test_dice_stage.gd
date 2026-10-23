extends GutTest
## The die in Chapter 8: it lands on a face and reports whether the roll made the target, and an option
## that does not ask for a roll leaves the die out of it.

const SCENE := "res://stages/dice/dice_stage.tscn"
const CHAPTER := "res://content/chapters/ch8_campaign.json"
## How many times faster than life the tests run it.
const FAST := 20.0

var _time_scale := 1.0
var _chapter: ChapterData


func before_all() -> void:
	_chapter = ContentLoader.new(Profile.axis_ids()).load_chapter(CHAPTER)


func before_each() -> void:
	_time_scale = Engine.time_scale
	Engine.time_scale = FAST


func after_each() -> void:
	Engine.time_scale = _time_scale


func _stage(beat: StringName, seed: int) -> DiceStage:
	var stage := (load(SCENE) as PackedScene).instantiate() as DiceStage
	stage.roll_seed = seed
	add_child_autofree(stage)
	stage.setup(_chapter.find_beat(beat) as QuestionData)
	return stage


func test_a_roll_reports_whether_it_made_the_target() -> void:
	for seed in [1, 2, 3, 4, 5, 6]:
		var stage := _stage(&"first_roll", seed)
		var result := await stage.play_consequence(-1)
		var target := int(stage.question.stage.get("target", 1))
		assert_between(stage.rolled(), 1, 6)
		assert_eq(result, DiceStage.MADE if stage.rolled() >= target else DiceStage.MISSED, "seed %d" % seed)
		assert_eq(stage.die.face, stage.rolled(), "the die shows the face it landed on")


func test_only_the_honest_option_rolls() -> void:
	var stage := _stage(&"final_roll", 1)
	var question := stage.question
	for i in question.options.size():
		if not bool(question.options[i].outcome.get("roll", false)):
			assert_eq(await stage.play_consequence(i), &"", "%s leaves the die out of it" % question.options[i].id)
			assert_false(stage.die.visible)


func test_the_caption_shows_the_target() -> void:
	var stage := _stage(&"first_roll", 1)
	assert_string_contains(stage.caption.get_parsed_text(), "roll a 3 or higher")
