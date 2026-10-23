class_name Stage
extends Node2D
## A question's presentation: the tableau above the dialogue box, its in-scene controls, and the
## consequence it plays once the player has chosen. A stage builds itself from its question's data,
## so one stage serves every question that uses it.
## The question player drives a stage through [method setup], [method enter], [method set_choosing],
## [method play_consequence] and [method leave], awaiting each one. A stage can also report how the
## consequence came out, so the imp reacts to it; bring the offer round again; take the player's choice
## by itself, with no choice row; fill the placeholders in its question's lines and labels; pick how the
## question is asked, or find there is nothing to choose; make its own reveal; and cue the imp's face at
## a moment of its own. It reads and changes what the run remembers through [member run].

## Emitted when the pointer moves onto or off an in-scene control. [code]-1[/code] means none.
signal option_hovered(index: int)
## Emitted when the player picks an option with an in-scene control.
signal option_committed(index: int)
## Emitted when something on the stage should change the imp's face, such as a button coming alive.
## [param face] is one of his faces: grin, smug, glare or surprised.
signal imp_face_cued(face: StringName)

## Which wing the imp stands in while this stage is up.
@export var imp_wing := Imp.Wing.RIGHT
## Seconds the tableau takes to draw itself on.
@export_range(0.0, 5.0, 0.01) var enter_duration := 0.9
## Seconds the tableau takes to dissolve away.
@export_range(0.0, 5.0, 0.01) var leave_duration := 0.6

## The question being staged.
var question: QuestionData
## The dialogue box, handed over by the question player, for a stage whose imp speaks at moments of
## its own, such as over a countdown or while a pin spins.
var dialogue: DialogueBox
## What the run remembers, handed over by the question player: the profile, the money chapter's wallet,
## facts such as the walking button having come alive. A stage on its own, as in a sampler, gets a fresh one.
var run := RunState.new()


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


## Which of the question's asks to pose, by name, such as [code]nothing[/code] when there is nothing
## to sell back. Empty poses the plain ask.
func ask_key() -> StringName:
	return &""


## Whether there is anything to choose this time. When there is not, the question is only its ask: no
## choice, no consequence, no reaction and no reveal.
func offers_choice() -> bool:
	return true


## The words in the choice row right now, in option order, their placeholders filled. A stage whose
## options change between rounds, such as an auction's rising bid, gives its own.
func option_labels() -> PackedStringArray:
	var labels := PackedStringArray()
	var values := fills()
	for label in question.option_labels():
		labels.append(label.format(values))
	return labels


## Whether the stage takes the player's choice by itself, with no choice row, as the timer does.
## Such a stage answers [method choose].
func chooses_alone() -> bool:
	return false


## Waits for the player's choice on a stage that [method chooses_alone], and returns its index.
func choose() -> int:
	return 0


## Plays what happens when the option at [param index] is picked. Returns how it came out, such as
## [code]lives[/code], which picks the imp's reaction, or an empty name when it can go only one way.
func play_consequence(_index: int) -> StringName:
	return &""


## Whether the offer comes round again after this round's reaction, as on an offer ladder.
func another_round() -> bool:
	return false


## The values the stage fills into its question's placeholders right now, such as the amount on offer.
func fills() -> Dictionary:
	return {}


## A short name for each value in [method fills], such as an amount in digits or a country's code.
## A filled line's id ends with the names of the values it uses.
func fill_keys() -> Dictionary:
	return {}


## [param lines] with their placeholders filled from the stage as it is now.
func fill(lines: Array[LineData]) -> Array[LineData]:
	return LineData.fill_all(lines, fills(), fill_keys())


## What the crowd reveal shows once the question is over, with [param pick] as the player's last choice.
func reveal_split(pick: int) -> RevealSplit:
	return RevealSplit.of(question, pick)


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
