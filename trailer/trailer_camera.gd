class_name TrailerCamera
extends Camera2D
## The trailer's camera, moving over the page the way a camera moves over a drawing on a desk. A framing
## is a zoom and the point of the page at the middle of the view. It frames the world, the stage and the
## imp; when a shot asks, it frames the words layer too (the dialogue box, the choice row and the crowd
## reveal), such as to bring the crowd reveal closer. Lines are drawn on the page, so they thicken as
## the camera comes in, as ink would.

## The words layer, framed only when a shot asks.
@export var words: CanvasLayer
## The middle of the page: where an unmoved camera looks, and where the words layer sits unmoved.
@export var page_middle := Vector2(960.0, 540.0)

## How far the words layer is brought in: 1 leaves it as the game shows it.
var words_zoom := 1.0:
	set(value):
		words_zoom = value
		_frame_words()
## The point of the words layer at the middle of the view.
var words_at := Vector2(960.0, 540.0):
	set(value):
		words_at = value
		_frame_words()

var _move: Tween


func _ready() -> void:
	anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	position = page_middle
	words_at = page_middle
	make_current()


## Frames the world at once: [param at] at the middle of the view, brought in by [param zoom_by].
func frame(zoom_by: float, at: Vector2) -> void:
	_stop()
	zoom = Vector2.ONE * zoom_by
	position = at


## Frames the words layer at once, as [method frame] does the world.
func frame_words(zoom_by: float, at: Vector2) -> void:
	words_zoom = zoom_by
	words_at = at


## Moves to a new framing over [param seconds], eased in and out. [param to] may hold
## [code]zoom[/code] and [code]at[/code] for the world and [code]words_zoom[/code] and
## [code]words_at[/code] for the words layer; what it leaves out stays as it is.
func move_to(to: Dictionary, seconds: float) -> void:
	_stop()
	if seconds <= 0.0:
		_apply(to)
		return
	_move = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if to.has("zoom"):
		_move.tween_property(self, ^"zoom", Vector2.ONE * float(to["zoom"]), seconds)
	if to.has("at"):
		_move.tween_property(self, ^"position", to["at"] as Vector2, seconds)
	if to.has("words_zoom"):
		_move.tween_property(self, ^"words_zoom", float(to["words_zoom"]), seconds)
	if to.has("words_at"):
		_move.tween_property(self, ^"words_at", to["words_at"] as Vector2, seconds)
	if not _move.has_tweeners():
		_move.kill()
		return
	await _move.finished


func _apply(to: Dictionary) -> void:
	if to.has("zoom"):
		zoom = Vector2.ONE * float(to["zoom"])
	if to.has("at"):
		position = to["at"] as Vector2
	if to.has("words_zoom"):
		words_zoom = float(to["words_zoom"])
	if to.has("words_at"):
		words_at = to["words_at"] as Vector2


func _stop() -> void:
	if _move != null and _move.is_valid():
		_move.kill()


## Brings the words layer in round [member words_at], keeping that point at the middle of the view.
func _frame_words() -> void:
	if words == null:
		return
	words.transform = Transform2D(0.0, Vector2.ONE * words_zoom, 0.0, page_middle - words_at * words_zoom)
