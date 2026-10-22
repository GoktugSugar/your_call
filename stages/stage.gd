class_name Stage
extends Node2D
## A question's presentation: the tableau above the dialogue box, its in-scene controls, and the
## consequence it plays once the player has chosen. A stage builds itself from its question's data,
## so one stage serves every question that uses it.
## The question player drives a stage through [method setup], [method enter], [method set_choosing],
## [method play_consequence] and [method leave], awaiting each one.

## Emitted when the pointer moves onto or off an in-scene control. [code]-1[/code] means none.
signal option_hovered(index: int)
## Emitted when the player picks an option with an in-scene control.
signal option_committed(index: int)

## Which wing the imp stands in while this stage is up.
@export var imp_wing := Imp.Wing.RIGHT
## Seconds the tableau takes to draw itself on.
@export_range(0.0, 5.0, 0.01) var enter_duration := 0.9
## Seconds the tableau takes to dissolve away.
@export_range(0.0, 5.0, 0.01) var leave_duration := 0.6

## The question being staged.
var question: QuestionData


## Builds the tableau for [param for_question]. Called once, after the stage is in the tree.
func setup(for_question: QuestionData) -> void:
	question = for_question


## Draws the tableau on.
func enter() -> void:
	var drawings := _ink_drawings()
	if drawings.is_empty():
		return
	for drawing in drawings:
		drawing.reveal = 0.0
	var tween := create_tween().set_parallel(true)
	for drawing in drawings:
		tween.tween_property(drawing, ^"reveal", 1.0, enter_duration)
	await tween.finished


## Turns the in-scene controls on or off.
func set_choosing(_active: bool) -> void:
	pass


## Shows that an option is under the pointer in the choice row. [code]-1[/code] clears it.
func highlight_option(_index: int) -> void:
	pass


## Plays what happens when the option at [param index] is picked.
func play_consequence(_index: int) -> void:
	pass


## Dissolves the tableau away.
func leave() -> void:
	var drawings := _ink_drawings()
	if drawings.is_empty():
		return
	var tween := create_tween().set_parallel(true)
	for drawing in drawings:
		tween.tween_property(drawing, ^"dissolve", 1.0, leave_duration)
	await tween.finished


## Where on the canvas a pointer picks the option at [param index] in the scene, or
## [code]Vector2.INF[/code] when the scene has no control for it and it is picked only in the choice row.
func option_point(_index: int) -> Vector2:
	return Vector2.INF


func _ink_drawings() -> Array[InkDrawing]:
	var found: Array[InkDrawing] = []
	var pending: Array[Node] = [self]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if node is InkDrawing and node.is_visible_in_tree():
			found.append(node)
		pending.append_array(node.get_children())
	return found
