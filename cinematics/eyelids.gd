class_name Eyelids
extends ColorRect
## The dark of shut eyes, over everything. The eyes open the way heavy eyes do: the dark clears in
## uneven blotches from the middle out, a first open, a heavy blink, then the rest of the way, the
## blotches drifting and sharpening as the eyes focus. They close the same way backwards, with their
## own timing: they droop, flutter back up once and shut, losing focus as they go. The rect's colour
## is the dark, and [code]eyelids.gdshader[/code] clears it. Once open, the lids hide.

## Emitted when the eyes come to rest, open or shut, or are stopped on the way.
signal settled

@export_group("Opening")
## How far the eyes first open, as a share of fully open.
@export_range(0.0, 1.0, 0.01) var first_open := 0.5
## Seconds the eyes take to first open.
@export_range(0.05, 5.0, 0.05) var first_open_time := 0.9
## How far the eyes sink back in the heavy blink.
@export_range(0.0, 1.0, 0.01) var blink_close := 0.3
## Seconds the heavy blink takes.
@export_range(0.05, 5.0, 0.05) var blink_time := 0.3
## Seconds the eyes take to open the rest of the way.
@export_range(0.05, 5.0, 0.05) var full_open_time := 1.1

@export_group("Closing")
## Seconds the eyes take to droop from open down to [member blink_close]. Closing runs the opening
## backwards, through the same two stops.
@export_range(0.05, 5.0, 0.05) var droop_time := 1.2
## Seconds the eyes take to flutter back up to [member first_open].
@export_range(0.05, 5.0, 0.05) var flutter_time := 0.35
## Seconds the eyes take to shut from there.
@export_range(0.05, 5.0, 0.05) var shut_time := 0.8

@export_group("Focus")
## How far the blotches drift out of focus, across and up and down, in pixels. The drift settles to
## nothing as the eyes focus, and grows again as they lose it.
@export var drift_strength := Vector2(80.0, 40.0)
## Sways a second of the blotches' drift, across and up and down.
@export var drift_rate := Vector2(0.8, 0.56)
## How blurred the blotch edges are out of focus, and how sharp in focus.
@export var focus_softness := Vector2(0.32, 0.03)

var _material: ShaderMaterial
var _clearing: Tween
var _focusing: Tween
var _sway_from := 0.0
var _moving := false


func _ready() -> void:
	_material = material as ShaderMaterial
	color = InkPalette.get_default().ink


## Seconds the eyes take to open.
func opening_time() -> float:
	return first_open_time + blink_time + full_open_time


## Seconds the eyes take to close.
func closing_time() -> float:
	return droop_time + flutter_time + shut_time


## Opens the eyes from shut: a first open, a heavy blink, then the rest of the way, focusing as they
## go. [param sway_from] is how far into their sway the blotches start, in seconds, so a cinematic can
## sway them on its own clock. Returns once the eyes are open or stopped.
func open(sway_from := 0.0) -> void:
	_start(0.0, sway_from, opening_time(), false)
	_clearing.tween_method(_set_clear, 0.0, first_open, first_open_time) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_clearing.tween_method(_set_clear, first_open, blink_close, blink_time) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_clearing.tween_method(_set_clear, blink_close, 1.0, full_open_time) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_clearing.tween_callback(hide)
	await settled


## Closes the eyes on whatever is behind them: the opening run backwards, the blotches closing in from
## the edges and blurring as the eyes lose focus. [param sway_from] is as for [method open]. Returns
## once the eyes are shut or stopped.
func close(sway_from := 0.0) -> void:
	_start(1.0, sway_from, closing_time(), true)
	_clearing.tween_method(_set_clear, 1.0, blink_close, droop_time) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_clearing.tween_method(_set_clear, blink_close, first_open, flutter_time) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_clearing.tween_method(_set_clear, first_open, 0.0, shut_time) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await settled


## Stops the eyes where they are. Whoever is waiting on [method open] or [method close] carries on.
func stop() -> void:
	for tween: Tween in [_clearing, _focusing]:
		if tween != null and tween.is_valid():
			tween.kill()
	if _moving:
		_settle()


## Sets the eyes going from [param clear] (0 shut, 1 open) and focuses them over [param duration].
## The caller adds the steps of the clearing.
func _start(clear: float, sway_from: float, duration: float, closing: bool) -> void:
	stop()
	_sway_from = sway_from
	_set_clear(clear)
	_focus(0.0, duration, closing)
	show()
	_moving = true
	_clearing = create_tween()
	_clearing.finished.connect(_settle)
	_focusing = create_tween()
	_focusing.tween_method(_focus.bind(duration, closing), 0.0, duration, duration)


func _settle() -> void:
	_moving = false
	settled.emit()


func _set_clear(value: float) -> void:
	_material.set_shader_parameter(&"clear", value)


## Drifts the blotches in a sway that settles as the eyes focus, and sharpens their edges. Closing
## runs it backwards: the sway grows and the edges blur as the eyes lose focus.
func _focus(elapsed: float, duration: float, closing: bool) -> void:
	var focus := elapsed / duration
	if closing:
		focus = 1.0 - focus
	var sway := (_sway_from + elapsed) * drift_rate * TAU
	_material.set_shader_parameter(&"drift", Vector2(sin(sway.x), cos(sway.y)) * drift_strength * (1.0 - focus))
	_material.set_shader_parameter(&"softness", lerpf(focus_softness.x, focus_softness.y, focus))
