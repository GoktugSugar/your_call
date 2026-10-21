@tool
class_name Lever
extends InkDrawing
## The lever in ink: an amber handle on a small base. While it is live, pointing at it lifts it,
## and clicking it pulls it. Its origin is the handle's pivot, on top of the base.

## Emitted when the pointer moves onto or off the lever while it is live.
signal hover_changed(hovered: bool)
## Emitted when the player clicks the lever while it is live.
signal pulled

## Angle of the handle at rest, in degrees from upright. Negative leans left.
@export_range(-90.0, 90.0, 0.5) var rest_angle := -28.0:
	set(value):
		rest_angle = value
		angle = value
## Angle of the handle once thrown.
@export_range(-90.0, 90.0, 0.5) var thrown_angle := 30.0
## Length of the handle, pivot to knob.
@export_range(10.0, 200.0, 0.5) var handle_length := 62.0:
	set(value):
		handle_length = value
		queue_redraw()
## Radius of the knob on the end of the handle.
@export_range(1.0, 30.0, 0.5) var knob_radius := 7.0:
	set(value):
		knob_radius = value
		queue_redraw()
## Width and height of the base under the pivot.
@export var base_size := Vector2(46.0, 14.0):
	set(value):
		base_size = value
		queue_redraw()
## The area that catches the pointer, in this node's space.
@export var hit_area := Rect2(-48.0, -82.0, 96.0, 100.0)
## Seconds a throw takes.
@export_range(0.05, 2.0, 0.01) var throw_duration := 0.24
## Width of the handle while it is pointed at or highlighted, as a multiple of its resting width.
@export_range(1.0, 3.0, 0.05) var lifted_width := 1.5
## How far the handle leans toward the throw while it is pointed at, in degrees.
@export_range(0.0, 20.0, 0.5) var lifted_lean := 4.0
## Palette role of the handle and knob.
@export var handle_role := &"amber"

## The handle's angle now, in degrees.
var angle := -28.0:
	set(value):
		angle = value
		queue_redraw()
## Whether the lever answers the pointer.
var live := false:
	set(value):
		live = value
		if not live:
			_set_hovered(false)
## Whether the lever shows as lifted because its option is pointed at elsewhere.
var highlighted := false:
	set(value):
		highlighted = value
		queue_redraw()

var _hovered := false


func _unhandled_input(event: InputEvent) -> void:
	if not live or not event is InputEventMouse:
		return
	var over := hit_area.has_point((make_input_local(event) as InputEventMouse).position)
	if event is InputEventMouseMotion:
		_set_hovered(over)
	elif over and event.is_action_pressed(&"pick"):
		get_viewport().set_input_as_handled()
		pulled.emit()


## The middle of the handle on the canvas, where a pointer would grab it.
func grip_point() -> Vector2:
	return get_global_transform_with_canvas() * (Vector2.UP.rotated(deg_to_rad(angle)) * handle_length * 0.6)


## Throws the handle over.
func throw() -> void:
	live = false
	var tween := create_tween()
	tween.tween_property(self, ^"angle", thrown_angle, throw_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished


## Puts the handle back at rest.
func reset() -> void:
	angle = rest_angle
	highlighted = false


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var lifted := _hovered or highlighted
	var lean := lifted_lean * signf(thrown_angle - rest_angle) if lifted else 0.0
	var knob := Vector2.UP.rotated(deg_to_rad(angle + lean)) * handle_length
	var handle_color := palette.color(handle_role)
	var lines: Array[InkLine] = []
	var half := base_size.x * 0.5
	var base := PackedVector2Array([Vector2(-half, 0.0), Vector2(half, 0.0), Vector2(half, base_size.y),
			Vector2(-half, base_size.y), Vector2(-half, 0.0)])
	lines.append(InkLine.along(InkBrush.resample_polyline(base, spacing), palette.ink, 1.0, true))
	var width := lifted_width if lifted else 1.0
	lines.append(InkLine.along(InkBrush.resample_polyline(PackedVector2Array([Vector2.ZERO, knob]), spacing), handle_color, width))
	lines.append(InkLine.along(InkBrush.ellipse(knob, Vector2.ONE * knob_radius, spacing * 0.5), handle_color, width, true))
	return lines


func _set_hovered(hovered: bool) -> void:
	if hovered == _hovered:
		return
	_hovered = hovered
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if hovered else Input.CURSOR_ARROW)
	queue_redraw()
	hover_changed.emit(hovered)
