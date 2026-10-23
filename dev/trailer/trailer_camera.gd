class_name TrailerCamera
extends Camera2D
## The trailers' camera, moving over the page the way a camera moves over a drawing on a desk. A framing
## is how far it is brought in and the point of the page at the middle of the view. Lines are drawn on
## the page, so they thicken as the camera comes in, as ink would. Development only.

## The middle of the page: where an unmoved camera looks.
@export var page_middle := Vector2(960.0, 540.0)

## How far in the camera is, as the log of its zoom, so a move in or out feels even all the way.
var zoom_level := 0.0:
	set(value):
		zoom_level = value
		zoom = Vector2.ONE * exp(value)

var _move: Tween


func _ready() -> void:
	anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	position = page_middle
	make_current()


## Frames the page at once: [param at] at the middle of the view, brought in by [param zoom_by].
func frame(zoom_by: float, at: Vector2) -> void:
	_stop()
	zoom_level = log(zoom_by)
	position = at


## Moves to a framing over [param seconds], eased in and out. Returns once it is there.
func move_to(zoom_by: float, at: Vector2, seconds: float) -> void:
	_stop()
	if seconds <= 0.0:
		frame(zoom_by, at)
		return
	_move = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_move.tween_property(self, ^"zoom_level", log(zoom_by), seconds)
	_move.tween_property(self, ^"position", at, seconds)
	await _move.finished


func _stop() -> void:
	if _move != null and _move.is_valid():
		_move.kill()
