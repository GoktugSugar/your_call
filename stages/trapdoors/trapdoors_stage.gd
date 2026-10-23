class_name TrapdoorsStage
extends StudioStage
## 6.02: two contestants, each standing on a trapdoor in the floor, the stage data's [code]left[/code]
## kind dancing a little on the boil and its [code]right[/code] kind beside it. The room keeps one, the
## first option keeping the left: the other's trapdoor swings open and they drop through the floor,
## fading as they go. When the right one stays, the run remembers the stage data's
## [code]remember_right[/code], so the final round knows who made it.
## Stage data: [code]{"type": "trapdoors", "random": 40, "line": 50, "left": "calm", "right": "elderly",
## "remember_right": "kept_old_soul"}[/code]. Outcomes [code]left[/code] or [code]right[/code]: who stayed.

## Where the two trapdoors are, left and right.
@export var spots := PackedVector2Array([Vector2(760.0, 0.0), Vector2(1160.0, 0.0)])
## How far a contestant drops through the floor.
@export_range(0.0, 800.0, 5.0) var drop := 300.0
## Seconds the drop takes.
@export_range(0.05, 3.0, 0.05) var drop_time := 0.6
## Seconds a trapdoor takes to swing open, and to shut again.
@export_range(0.05, 2.0, 0.05) var swing_time := 0.22
## How high the dancer hops, and how many hops a second.
@export_range(0.0, 60.0, 0.5) var dance_height := 12.0
@export_range(0.1, 6.0, 0.05) var dance_rate := 1.6
## Seconds the stage holds after the drop.
@export_range(0.0, 3.0, 0.05) var after_hold := 0.5

var _souls: Array[Soul] = []
var _dancing := true
var _clock := 0.0


func setup(for_question: QuestionData) -> void:
	super.setup(for_question)
	var data := question.stage
	var kinds := [StringName(str(data.get("left", "calm"))), StringName(str(data.get("right", "elderly")))]
	studio_floor.trapdoors = PackedFloat32Array([spots[0].x, spots[1].x])
	for i in 2:
		_souls.append(add_contestant(kinds[i], spots[i].x))


func _process(delta: float) -> void:
	_clock += delta
	if _dancing and not _souls.is_empty() and is_instance_valid(_souls[0]):
		_souls[0].position.y = floor_y - absf(sin(_clock * PI * dance_rate)) * dance_height


func play_consequence(_index: int) -> StringName:
	await count_votes()
	_dancing = false
	_souls[0].position.y = floor_y
	var stays := 0 if room_picks_first() else 1
	var goes := 1 - stays
	if stays == 1:
		var fact := str(question.stage.get("remember_right", ""))
		if fact != "":
			run.remember(StringName(fact))
	await _drop(goes)
	await get_tree().create_timer(after_hold, false).timeout
	return &"left" if stays == 0 else &"right"


## The trapdoor under [param index] swings open, they drop through and fade, and it shuts again.
func _drop(index: int) -> void:
	var soul := _souls[index]
	var open_by := func(amount: float) -> void: studio_floor.set_open(index, amount)
	var swing := create_tween()
	swing.tween_method(open_by, 0.0, 1.0, swing_time)
	await swing.finished
	var fall := create_tween().set_parallel(true)
	fall.tween_property(soul, ^"position:y", floor_y + drop, drop_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fall.tween_property(soul, ^"dissolve", 1.0, drop_time)
	await fall.finished
	soul.hide()
	var shut := create_tween()
	shut.tween_method(open_by, 1.0, 0.0, swing_time)
	await shut.finished
