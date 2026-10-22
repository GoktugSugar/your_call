class_name CrashCinematic
extends CanvasLayer
## The opening: a brief, fragmentary ink flash of the judge's death over black, then waking in the void.
## Headlights bear down on a night road, flickering like a bad memory; the view swerves; the hit lands
## with a flash and a shake; then black. The black clears in uneven blotches, blinking, drifting and
## sharpening as the eyes focus, onto the plain page. No text, no body. An advance press skips to the end.

## Emitted at the moment of the hit, for the sound of it.
signal hit
## Emitted when the cinematic has finished or been skipped.
signal finished

## The road and the headlights.
@export var view: CrashView
## The black behind the memory.
@export var night: ColorRect
## The white of the hit.
@export var flash: ColorRect
## The darkness that clears as the eyes open.
@export var waking: ColorRect

@export_group("Approach")
## Seconds the headlights take to arrive.
@export_range(0.1, 10.0, 0.05) var approach_duration := 1.7
## Frames a second the memory flickers at.
@export_range(1.0, 60.0, 0.5) var memory_fps := 9.0
## Chance that a memory frame is lost to black.
@export_range(0.0, 1.0, 0.01) var dropout_chance := 0.12
## Dashes of the centre line that stream by each second.
@export_range(0.0, 40.0, 0.1) var dash_rate := 9.0
## Seed for the flicker. Zero picks a new one every time.
@export var flicker_seed := 0

@export_group("Swerve")
## When the swerve starts, as a share of the approach.
@export_range(0.0, 1.0, 0.01) var swerve_at := 0.7
## Seconds the swerve takes.
@export_range(0.05, 3.0, 0.01) var swerve_duration := 0.3
## How far the view twists in the swerve, in degrees.
@export_range(-90.0, 90.0, 0.5) var swerve_angle := -14.0
## How far the view lurches in the swerve, in pixels.
@export var swerve_shift := Vector2(-240.0, 30.0)

@export_group("Hit")
## Seconds the flash of the hit takes to fade.
@export_range(0.0, 3.0, 0.01) var flash_fade := 0.3
## Seconds the shake lasts.
@export_range(0.0, 3.0, 0.01) var shake_duration := 0.4
## How far the shake throws the view at first, in pixels.
@export_range(0.0, 200.0, 0.5) var shake_strength := 36.0
## Seconds of black before waking.
@export_range(0.0, 5.0, 0.05) var black_hold := 0.6

@export_group("Waking")
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
## How far the blotches drift while the eyes focus, across and up and down, in pixels. The drift settles to nothing.
@export var drift_strength := Vector2(80.0, 40.0)
## Sways a second of the blotches' drift, across and up and down.
@export var drift_rate := Vector2(0.8, 0.56)
## How blurred the blotch edges start, and how sharp they end.
@export var focus_softness := Vector2(0.32, 0.03)

@export_group("Skipping")
## Seconds after it starts before a press can skip it, so a click that only brings the window
## into focus does not throw the opening away.
@export_range(0.0, 5.0, 0.05) var skip_grace := 0.6

var _running := false
var _sequence: Tween
var _focus: Tween
var _rng := RandomNumberGenerator.new()
var _approach := 0.0
var _swerve := 0.0
var _clock := 0.0
var _since_frame := 0.0
var _flickering := false


func _ready() -> void:
	var palette := InkPalette.get_default()
	night.color = palette.ink
	waking.color = palette.ink
	flash.color = palette.paper
	visible = false
	set_process(false)


func _process(delta: float) -> void:
	_clock += delta
	_since_frame += delta
	if not _flickering or _since_frame < 1.0 / memory_fps:
		return
	_since_frame = 0.0
	view.dropout = _rng.randf() < dropout_chance and _approach < 1.0
	view.approach = _approach
	view.dash_phase = _clock * dash_rate
	view.rotation = deg_to_rad(swerve_angle) * _swerve
	view.position = _center() + swerve_shift * _swerve


func _unhandled_input(event: InputEvent) -> void:
	if _running and _clock >= skip_grace and event.is_action_pressed(&"advance"):
		get_viewport().set_input_as_handled()
		_finish()


## Plays the whole cinematic. Returns when it ends or is skipped.
func play() -> void:
	if flicker_seed != 0:
		_rng.seed = flicker_seed
	else:
		_rng.randomize()
	_reset()
	visible = true
	_running = true
	_flickering = true
	set_process(true)
	var waking_material := waking.material as ShaderMaterial
	_sequence = create_tween()
	_sequence.tween_method(_set_approach, 0.0, 1.0, approach_duration)
	_sequence.parallel().tween_method(_set_swerve, 0.0, 1.0, swerve_duration) \
			.set_delay(approach_duration * swerve_at).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_sequence.tween_callback(_impact)
	_sequence.tween_property(flash, ^"modulate:a", 0.0, flash_fade).set_ease(Tween.EASE_IN)
	_sequence.parallel().tween_method(_shake, 1.0, 0.0, shake_duration)
	_sequence.tween_callback(_cut_to_black)
	_sequence.tween_interval(black_hold)
	_sequence.tween_callback(_begin_waking)
	_sequence.tween_method(_set_clear.bind(waking_material), 0.0, first_open, first_open_time) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_sequence.tween_method(_set_clear.bind(waking_material), first_open, blink_close, blink_time) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_sequence.tween_method(_set_clear.bind(waking_material), blink_close, 1.0, full_open_time) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_sequence.tween_callback(_finish)
	await finished


func _reset() -> void:
	offset = Vector2.ZERO
	night.visible = true
	view.visible = true
	view.dropout = false
	view.approach = 0.0
	view.rotation = 0.0
	view.position = _center()
	flash.visible = true
	flash.modulate.a = 0.0
	waking.visible = false
	_approach = 0.0
	_swerve = 0.0
	_clock = 0.0
	_since_frame = 0.0


## The middle of the canvas, where the view is centred.
func _center() -> Vector2:
	return get_viewport().get_visible_rect().get_center()


func _set_approach(value: float) -> void:
	_approach = value


func _set_swerve(value: float) -> void:
	_swerve = value


func _impact() -> void:
	_flickering = false
	view.dropout = false
	view.approach = 1.0
	flash.modulate.a = 1.0
	hit.emit()


func _shake(strength: float) -> void:
	offset = Vector2(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0)) * shake_strength * strength


func _cut_to_black() -> void:
	offset = Vector2.ZERO
	view.visible = false
	flash.visible = false


func _begin_waking() -> void:
	var material := waking.material as ShaderMaterial
	material.set_shader_parameter(&"clear", 0.0)
	material.set_shader_parameter(&"softness", focus_softness.x)
	waking.visible = true
	night.visible = false
	var focus_time := first_open_time + blink_time + full_open_time
	_focus = create_tween()
	_focus.tween_method(_focus_step.bind(material), 0.0, 1.0, focus_time)


## Drifts the blotches in a sway that settles, and sharpens their edges, as the eyes focus.
func _focus_step(progress: float, material: ShaderMaterial) -> void:
	var sway := _clock * drift_rate * TAU
	material.set_shader_parameter(&"drift", Vector2(sin(sway.x), cos(sway.y)) * drift_strength * (1.0 - progress))
	material.set_shader_parameter(&"softness", lerpf(focus_softness.x, focus_softness.y, progress))


func _set_clear(value: float, material: ShaderMaterial) -> void:
	material.set_shader_parameter(&"clear", value)


func _finish() -> void:
	if not _running:
		return
	_running = false
	_flickering = false
	for tween: Tween in [_sequence, _focus]:
		if tween != null and tween.is_valid():
			tween.kill()
	set_process(false)
	offset = Vector2.ZERO
	visible = false
	finished.emit()
