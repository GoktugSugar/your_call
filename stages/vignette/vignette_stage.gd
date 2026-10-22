class_name VignetteStage
extends Stage
## A doodle that sets the scene while the imp narrates, such as the campaign's tavern, its beast or its
## dragon, with the options offered in the choice row. Picked, the doodle answers the way the option
## says: it hops, shakes, falls over and dissolves, or backs away, fading.
## Stage data: [code]{"type": "vignette", "doodle": "dragon"}[/code]. An option's outcome can say how
## the doodle answers: [code]{"doodle": "fall"}[/code], or [code]shake[/code] or [code]leave[/code];
## it hops otherwise.

## Where the doodle stands: its origin goes on this node's.
@export var slot: Node2D
## The size the doodle is drawn at, as a multiple of its natural size.
@export_range(0.2, 3.0, 0.01) var doodle_scale := 1.3

@export_group("Hop")
## How high it hops.
@export_range(0.0, 120.0, 0.5) var hop_height := 22.0
## Seconds the hop takes, up and back down.
@export_range(0.05, 2.0, 0.01) var hop_time := 0.42

@export_group("Shake")
## How far it shakes side to side, in pixels.
@export_range(0.0, 80.0, 0.5) var shake_distance := 12.0
## How many times it shakes each way.
@export_range(1, 12) var shakes := 4
## Seconds the shaking takes.
@export_range(0.05, 3.0, 0.01) var shake_time := 0.6

@export_group("Fall")
## How far it tips over, in degrees, the way it falls.
@export_range(0.0, 120.0, 0.5) var fall_angle := 84.0
## Which way it falls: -1 left, 1 right.
@export_range(-1, 1, 2) var fall_way := 1
## Seconds it takes to fall.
@export_range(0.05, 3.0, 0.01) var fall_time := 0.7
## Seconds it lies still before it dissolves.
@export_range(0.0, 3.0, 0.05) var lie_time := 0.4
## Seconds it takes to dissolve.
@export_range(0.05, 3.0, 0.05) var fade_time := 0.8

@export_group("Leave")
## How far it backs away.
@export_range(0.0, 1500.0, 5.0) var leave_distance := 260.0
## Which way it goes: -1 left, 1 right. Left keeps it clear of the imp's wing.
@export_range(-1, 1, 2) var leave_way := -1
## Seconds it takes to back away, fading as it goes.
@export_range(0.05, 5.0, 0.05) var leave_time := 1.4

@export_group("Consequence")
## Seconds the stage holds once the doodle has answered.
@export_range(0.0, 5.0, 0.05) var after_hold := 0.6

## How the doodle answers an option.
const HOP := &"hop"
const SHAKE := &"shake"
const FALL := &"fall"
const LEAVE := &"leave"

const _DOODLE_KEY := "doodle"

var _doodle: InkDrawing


func setup(for_question: QuestionData) -> void:
	super.setup(for_question)
	slot.scale = Vector2.ONE * doodle_scale
	var id := str(for_question.stage.get(_DOODLE_KEY, ""))
	_doodle = DoodlesStage.make_doodle(id)
	if _doodle == null:
		push_warning("Vignette stage: no doodle '%s'." % id)
		return
	slot.add_child(_doodle)


func play_consequence(index: int) -> StringName:
	if _doodle == null or index < 0 or index >= question.options.size():
		return &""
	match StringName(str(question.options[index].outcome.get("doodle", HOP))):
		SHAKE:
			await _shake()
		FALL:
			await _fall()
		LEAVE:
			await _back_away()
		_:
			await _hop()
	await get_tree().create_timer(after_hold, false).timeout
	return &""


func _hop() -> void:
	var hop := create_tween()
	hop.tween_property(_doodle, ^"position:y", -hop_height, hop_time * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	hop.tween_property(_doodle, ^"position:y", 0.0, hop_time * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await hop.finished


func _shake() -> void:
	var shake := create_tween()
	var step := shake_time / (shakes * 2 + 1)
	for i in shakes:
		var size := shake_distance * (1.0 - float(i) / shakes)
		shake.tween_property(_doodle, ^"position:x", -size, step).set_trans(Tween.TRANS_SINE)
		shake.tween_property(_doodle, ^"position:x", size, step).set_trans(Tween.TRANS_SINE)
	shake.tween_property(_doodle, ^"position:x", 0.0, step).set_trans(Tween.TRANS_SINE)
	await shake.finished


## It tips over about its base, gathering speed, lies still a moment and dissolves.
func _fall() -> void:
	var fall := create_tween()
	fall.tween_property(_doodle, ^"rotation", deg_to_rad(fall_angle) * fall_way, fall_time) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await fall.finished
	await get_tree().create_timer(lie_time, false).timeout
	await _doodle.dissolve_away(fade_time).finished


## It backs away, fading as it goes.
func _back_away() -> void:
	var away := create_tween().set_parallel(true)
	away.tween_property(_doodle, ^"position:x", leave_distance * leave_way / doodle_scale, leave_time) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	away.tween_property(_doodle, ^"dissolve", 1.0, leave_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await away.finished
