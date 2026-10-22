class_name TrailerPointer
extends Node
## An unseen pointer that plays the trailer's stages the way a player would: it glides over the page,
## lighting what it passes over, and clicks. It works with synthetic pointer events that carry their
## own device, so the trailer can shut out every real mouse and key while it records and still let the
## pointer through. Positions are on the canvas, where a stage says its controls are.

## The device the pointer's events come from.
const DEVICE := 7381
## Offset into the waver's noise for its second axis, so the two waver independently.
const _WAVER_Y_OFFSET := 17.0

## Where the pointer is on the canvas. It starts below the page, out of the way.
@export var start := Vector2(960.0, 1400.0)

@export_group("Hand")
## How far the hand wavers off its path as it glides, in pixels.
@export_range(0.0, 40.0, 0.5) var waver := 4.0
## How quickly the hand wavers, in wavers a second.
@export_range(0.1, 20.0, 0.1) var waver_rate := 1.6
## Seconds between pressing and letting go of a click.
@export_range(0.0, 0.5, 0.01) var click_hold := 0.05

## Where the pointer is now, on the canvas.
var position := Vector2.ZERO

var _glide: Tween
var _time := 0.0


func _ready() -> void:
	position = start


func _process(delta: float) -> void:
	_time += delta


## Glides through [param points] to the last of them over [param seconds], easing off and in, with
## the hand wavering by [param waver_by] pixels (the pointer's own [member waver] when below zero).
func glide(points: Array[Vector2], seconds: float, waver_by := -1.0) -> void:
	if _glide != null and _glide.is_valid():
		_glide.kill()
	var path: Array[Vector2] = [position]
	path.append_array(points)
	if seconds <= 0.0:
		move_to(path[path.size() - 1])
		return
	var amount := waver if waver_by < 0.0 else waver_by
	_glide = create_tween()
	_glide.tween_method(_along.bind(path, amount), 0.0, 1.0, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await _glide.finished
	move_to(path[path.size() - 1])


## Puts the pointer at [param point] at once.
func move_to(point: Vector2) -> void:
	position = point
	var motion := InputEventMouseMotion.new()
	_place(motion)
	Input.parse_input_event(motion)


## Clicks where the pointer is: presses, holds for [member click_hold], lets go.
func click() -> void:
	for pressed: bool in [true, false]:
		var button := InputEventMouseButton.new()
		button.button_index = MOUSE_BUTTON_LEFT
		button.pressed = pressed
		_place(button)
		Input.parse_input_event(button)
		if pressed and click_hold > 0.0:
			await get_tree().create_timer(click_hold, false).timeout


## Whether [param event] came from the pointer rather than a real device.
static func made(event: InputEvent) -> bool:
	return event.device == DEVICE


## The point [param t] of the way along [param path], wavering by [param amount] pixels.
func _along(t: float, path: Array[Vector2], amount: float) -> void:
	var lengths := PackedFloat32Array([0.0])
	for i in range(1, path.size()):
		lengths.append(lengths[i - 1] + path[i - 1].distance_to(path[i]))
	var total := lengths[lengths.size() - 1]
	var point := path[path.size() - 1]
	var reach := t * total
	for i in range(1, path.size()):
		if reach <= lengths[i] or i == path.size() - 1:
			var span := maxf(lengths[i] - lengths[i - 1], 0.0001)
			point = path[i - 1].lerp(path[i], clampf((reach - lengths[i - 1]) / span, 0.0, 1.0))
			break
	# The waver fades out at both ends, so the glide starts and lands where it says.
	var settle := sin(t * PI)
	var wander := _time * waver_rate
	point += Vector2(InkBrush.noise(wander, DEVICE), InkBrush.noise(wander + _WAVER_Y_OFFSET, DEVICE)) * amount * settle
	move_to(point)


func _place(event: InputEventMouse) -> void:
	var at := get_viewport().get_screen_transform() * position
	event.device = DEVICE
	event.position = at
	event.global_position = at
