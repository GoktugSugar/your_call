extends GutTest
## The confession booth in Chapter 7: confessors file in from its data, the one speaking in the box is
## the one whose voice says the line, each takes the verdict meant for it, and only the walking button
## says its own lines over itself.

const SCENE := "res://stages/booth/booth_stage.tscn"
const CHAPTER := "res://content/chapters/ch7_confession_booth.json"
## How many times faster than life the tests run it.
const FAST := 10.0

var _time_scale := 1.0
var _chapter: ChapterData


func before_all() -> void:
	_chapter = ContentLoader.new(Profile.axis_ids()).load_chapter(CHAPTER)


func before_each() -> void:
	_time_scale = Engine.time_scale
	Engine.time_scale = FAST


func after_each() -> void:
	Engine.time_scale = _time_scale


func _stage(beat: StringName) -> BoothStage:
	var stage := (load(SCENE) as PackedScene).instantiate() as BoothStage
	add_child_autofree(stage)
	stage.setup(_chapter.find_beat(beat) as QuestionData)
	return stage


func _bodies(stage: BoothStage) -> Array[Node2D]:
	var bodies: Array[Node2D] = []
	for child in stage.get_children():
		if child is StickFigure or child is WalkingButton:
			bodies.append(child as Node2D)
	return bodies


func test_one_confessor_stands_in_the_booth() -> void:
	var stage := _stage(&"recliner")
	var bodies := _bodies(stage)
	assert_eq(bodies.size(), 1)
	assert_true(bodies[0] is StickFigure)
	assert_false(bodies[0].visible, "it waits off the page until the booth is drawn")


func test_two_confessors_come_in_from_either_side() -> void:
	var stage := _stage(&"two_stories")
	var bodies := _bodies(stage)
	assert_eq(bodies.size(), 2)
	assert_lt(bodies[0].position.x, stage.booth.position.x, "her from the left")
	assert_gt(bodies[1].position.x, stage.booth.position.x, "him from the right")
	for body in bodies:
		assert_between(body.position.x, stage.walk_bounds.x, stage.walk_bounds.y, "clear of the imp's wing")


func test_the_button_confesses_as_the_walking_button() -> void:
	var stage := _stage(&"button_confession")
	var bodies := _bodies(stage)
	assert_eq(bodies.size(), 1)
	assert_true(bodies[0] is WalkingButton)


func test_only_the_button_says_its_own_lines() -> void:
	var question := _chapter.find_beat(&"button_confession") as QuestionData
	var stage := _stage(&"button_confession")
	var said := 0
	for line in question.ask:
		if stage.speaks(line):
			said += 1
			assert_eq(line.speaker, &"button")
	assert_eq(said, 1, "one line of the ask floats over the button")
	var other := _stage(&"recliner")
	for line in (_chapter.find_beat(&"recliner") as QuestionData).ask:
		assert_false(other.speaks(line), "a confessor speaks in the box")


func test_every_confessor_line_has_a_confessor_to_say_it() -> void:
	for beat in _chapter.beats:
		var question := beat as QuestionData
		if question == null or str(question.stage.get("type", "")) != "booth":
			continue
		var voices := []
		for entry: Dictionary in question.stage.get("confessors", []):
			voices.append(StringName(str(entry.get("voice", ""))))
		for line in question.ask:
			if line.speaker == &"confessor":
				assert_has(voices, line.voice, "%s: %s has a confessor" % [question.id, line.id])


func test_each_confessor_takes_the_verdict_meant_for_it() -> void:
	var stage := _stage(&"two_stories")
	var bodies := _bodies(stage)
	for body in bodies:
		body.visible = true
	await stage.play_consequence(0)
	var her := bodies[0] as StickFigure
	var him := bodies[1] as StickFigure
	assert_eq(her.eyes, StickFigure.Eyes.OPEN, "believed, she keeps her eyes open")
	assert_eq(him.eyes, StickFigure.Eyes.CLOSED, "not believed, he shuts his eyes")


func test_every_verdict_names_one_the_booth_knows() -> void:
	var known := [BoothStage.GUILTY, BoothStage.CLEARED, BoothStage.EVERYONE]
	for beat in _chapter.beats:
		var question := beat as QuestionData
		if question == null or str(question.stage.get("type", "")) != "booth":
			continue
		for option in question.options:
			var verdict: Variant = option.outcome.get("verdict", "")
			var verdicts: Array = verdict.values() if verdict is Dictionary else [verdict]
			for each: Variant in verdicts:
				assert_has(known, StringName(str(each)), "%s %s" % [question.id, option.id])
