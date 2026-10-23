class_name ImpMotion
extends Node
## How the imp gets about. He never stands on the page: he floats a little off it, bobbing slowly, and
## gets from spot to spot without touching it. A short way he drifts, gliding there eased and leaning
## into it, his legs trailing; further off he warps, soaking into the paper where he is while his lines
## draw themselves back on where he is going, so he is never quite gone, and they pop shut. [Imp] says
## where to and when, and reads the float, the lean and the swing of his legs off this as he sets his
## pose.

## Emitted when a drift or a warp gets where it was going.
signal arrived
## Emitted when the move under way ends, true when it got there and false when it was stopped short.
signal _ended(got_there: bool)

## The imp it moves.
@export var body: Node2D
## His drawing, which soaks away and inks itself back on as he warps.
@export var drawing: InkDrawing

@export_group("Floating")
## How high he floats over the spot he is at, in pixels.
@export_range(0.0, 200.0, 0.5) var float_height := 24.0
## How far he bobs up and down as he floats, in pixels.
@export_range(0.0, 40.0, 0.1) var float_bob := 4.0
## Seconds per bob.
@export_range(0.1, 10.0, 0.05) var float_period := 2.6
## How far his hanging legs sway as he bobs, in degrees.
@export_range(0.0, 30.0, 0.1) var leg_sway := 3.0

@export_group("Drifting")
## How fast he drifts, in pixels a second.
@export_range(10.0, 3000.0, 1.0) var drift_speed := 260.0
## The shortest and the longest a drift takes, in seconds, however near or far it goes.
@export var drift_time := Vector2(0.5, 1.2)
## How far he leans into a drift, in degrees.
@export_range(0.0, 30.0, 0.1) var drift_lean := 7.0
## How far his hanging legs trail behind a drift, in degrees.
@export_range(0.0, 45.0, 0.1) var leg_trail := 12.0
## The share of a drift spent leaning into it; the rest eases him back upright as he slows.
@export_range(0.05, 0.95, 0.01) var lean_share := 0.4

@export_group("Warping")
## Seconds he takes to soak into the paper where he was.
@export_range(0.01, 2.0, 0.01) var soak_time := 0.3
## Seconds his lines take to draw themselves back on where he goes.
@export_range(0.01, 2.0, 0.01) var ink_time := 0.32
## How much of the soak he spends already inking himself back on: 0 waits until he is gone, 1 starts
## both at once.
@export_range(0.0, 1.0, 0.01) var overlap := 0.5
## Scale he pops to as his lines close.
@export_range(1.0, 1.5, 0.01) var pop_scale := 1.06
## The share of the inking on that the pop takes to swell, at its end.
@export_range(0.05, 1.0, 0.01) var pop_share := 0.35
## Seconds the pop takes to settle.
@export_range(0.0, 1.0, 0.01) var pop_settle := 0.18

## What the move under way adds to his lean, in degrees. Tweened by name.
var lean := 0.0
## How far his hanging legs trail behind the move under way, in degrees. Tweened by name.
var trail := 0.0

var _move: Tween
## The still copy of him a warp leaves soaking away where he was.
var _ghost: InkDrawing


## How far above the spot he is at he floats at [param time] seconds, in pixels.
func lift(time: float) -> float:
	return float_height + sin(time * TAU / float_period) * float_bob


## How far his hanging legs swing at [param time] seconds, in degrees: a sway with the bob, and a trail
## behind a drift.
func leg_swing(time: float) -> float:
	return cos(time * TAU / float_period) * leg_sway + trail


## Whether he is drifting or warping.
func is_moving() -> bool:
	return _move != null and _move.is_valid()


## Drifts to [param target], eased, leaning into the way he goes. Returns once he is there, or once the
## drift is stopped short. Emits [signal arrived] if he got there.
func drift_to(target: Vector2) -> void:
	stop()
	var start := body.position
	var seconds := clampf(start.distance_to(target) / drift_speed, drift_time.x, drift_time.y)
	var heading := signf(target.x - start.x)
	_move = create_tween()
	_move.tween_property(body, ^"position", target, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for leaning: Array in [[^"lean", drift_lean * heading], [^"trail", -leg_trail * heading]]:
		_move.parallel().tween_property(self, leaning[0], leaning[1], seconds * lean_share).set_trans(Tween.TRANS_SINE)
		_move.parallel().tween_property(self, leaning[0], 0.0, seconds * (1.0 - lean_share)) \
				.set_delay(seconds * lean_share).set_trans(Tween.TRANS_SINE)
	await _run()


## Warps to [param target]: he soaks into the paper where he is while his lines draw themselves back on
## there, and they pop shut. Returns once he is whole there, or once the warp is stopped short. Emits
## [signal arrived] if he got there.
func warp_to(target: Vector2) -> void:
	stop()
	_ghost = drawing.ghost()
	body.add_sibling(_ghost)
	_ghost.global_transform = drawing.global_transform
	drawing.reveal = 0.0
	body.position = target
	var inks_at := soak_time * (1.0 - overlap)
	var closes_at := inks_at + ink_time
	_move = create_tween()
	_move.tween_property(_ghost, ^"dissolve", 1.0, soak_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_move.parallel().tween_callback(_free_ghost).set_delay(soak_time)
	_move.parallel().tween_property(drawing, ^"reveal", 1.0, ink_time).set_delay(inks_at) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_move.parallel().tween_property(body, ^"scale", Vector2.ONE * pop_scale, ink_time * pop_share) \
			.set_delay(closes_at - ink_time * pop_share).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_move.parallel().tween_property(body, ^"scale", Vector2.ONE, pop_settle).set_delay(closes_at) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await _run()


## Stops the move under way where it is. A warp stopped short finishes at once: his lines all on, the
## copy he left gone. Whoever waited on the move is let go.
func stop() -> void:
	if _move == null:
		return
	if _move.is_valid():
		_move.kill()
	_move = null
	_free_ghost()
	drawing.reveal = 1.0
	body.scale = Vector2.ONE
	lean = 0.0
	trail = 0.0
	_ended.emit(false)


## Waits for the move just started to end, and says whether he arrived.
func _run() -> void:
	_move.finished.connect(_on_finished.bind(_move))
	if await _ended:
		arrived.emit()


func _on_finished(move: Tween) -> void:
	if move != _move:
		return
	_move = null
	_ended.emit(true)


func _free_ghost() -> void:
	if _ghost != null and is_instance_valid(_ghost):
		_ghost.queue_free()
	_ghost = null
