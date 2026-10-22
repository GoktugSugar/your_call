class_name MenuStage
extends DoodlesStage
## A menu of doodles, such as the campaign's classes: a row of small ink doodles, one per option, each
## over its label, picked the way a would you rather is. Pointing at a doodle lifts it and lights its
## label, and clicking picks it; the amber loop circles the pick, the rest dissolve, and the pick hops.
## Stage data: [code]{"type": "menu", "doodles": ["knight_shield", "rogue_dagger", "wizard_hat"]}[/code],
## one doodle per option, left to right.

## The scene each label is made from.
@export var word_scene: PackedScene
## How far apart the first and last doodles stand, middle to middle.
@export_range(100.0, 1800.0, 1.0) var row_width := 1240.0
## Where the middle of the row stands, on its baseline.
@export var row_middle := Vector2(960.0, 560.0)
## The size the doodles are drawn at, as a multiple of their natural size.
@export_range(0.2, 2.0, 0.01) var doodle_scale := 0.72


func setup(for_question: QuestionData) -> void:
	var count: int = (for_question.stage.get(_DOODLES_KEY, []) as Array).size()
	slots.clear()
	words.clear()
	for i in count:
		var slot := Node2D.new()
		slot.position = row_middle + Vector2(_offset(i, count), 0.0)
		slot.scale = Vector2.ONE * doodle_scale
		add_child(slot)
		slots.append(slot)
		var word := word_scene.instantiate() as ChoiceWord
		add_child(word)
		words.append(word)
	flourish_radii *= doodle_scale
	or_label.visible = false
	super.setup(for_question)


## How far the doodle at [param index] of [param count] stands from the middle of the row.
func _offset(index: int, count: int) -> float:
	if count <= 1:
		return 0.0
	return lerpf(-row_width * 0.5, row_width * 0.5, float(index) / (count - 1))
