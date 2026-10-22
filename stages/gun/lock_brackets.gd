@tool
class_name LockBrackets
extends InkDrawing
## The aim's lock: four amber corner brackets that close in round whatever the sight is on, and nothing
## else. [method lock_onto] tightens them onto a rect from a little further out; [method release] lets
## them go.

## Emitted when the brackets have closed in on a rect.
signal locked

## How long each arm of a bracket is.
@export_range(4.0, 120.0, 0.5) var arm := 26.0:
	set(value):
		arm = value
		queue_redraw()
## How far outside the rect the brackets sit once locked.
@export_range(0.0, 80.0, 0.5) var margin := 14.0:
	set(value):
		margin = value
		queue_redraw()
## How far further out they start, before they close in.
@export_range(0.0, 200.0, 0.5) var reach := 46.0
## Seconds they take to close in.
@export_range(0.01, 1.0, 0.01) var close_time := 0.14
## Seconds they take to fade when let go.
@export_range(0.01, 1.0, 0.01) var release_time := 0.12
## Width of the brackets, as a multiple of the style's line width.
@export_range(0.2, 4.0, 0.05) var bracket_width := 1.15:
	set(value):
		bracket_width = value
		queue_redraw()
## Palette role of the brackets.
@export var role := &"amber":
	set(value):
		role = value
		queue_redraw()

## The rect the brackets sit round, in this node's space.
var rect := Rect2():
	set(value):
		rect = value
		queue_redraw()
## How much further out than [member margin] they sit right now: [member reach] as they start to close.
var _slack := 0.0:
	set(value):
		_slack = value
		queue_redraw()
var _tween: Tween


func _ready() -> void:
	super._ready()
	if not Engine.is_editor_hint():
		modulate.a = 0.0


## Closes the brackets in on [param target], a rect in this node's space. Locking again onto the rect
## they are on only follows it, as it moves.
func lock_onto(target: Rect2) -> void:
	var fresh := modulate.a < 1.0 or not target.grow(margin).intersects(rect.grow(margin))
	rect = target
	if not fresh:
		return
	_kill()
	_slack = reach
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, ^"modulate:a", 1.0, close_time * 0.5)
	_tween.tween_property(self, ^"_slack", 0.0, close_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.chain().tween_callback(locked.emit)


## Lets the brackets go: they fade.
func release() -> void:
	if modulate.a <= 0.0:
		return
	_kill()
	_tween = create_tween()
	_tween.tween_property(self, ^"modulate:a", 0.0, release_time)


## Whether the brackets are on something.
func is_locked() -> bool:
	return modulate.a > 0.0 and (_tween == null or not _tween.is_running() or _slack <= 0.0)


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var color := palette.color(role)
	var box := rect.grow(margin + _slack)
	var lines: Array[InkLine] = []
	var corners := [[box.position, Vector2.RIGHT, Vector2.DOWN], [Vector2(box.end.x, box.position.y), Vector2.LEFT, Vector2.DOWN],
			[box.end, Vector2.LEFT, Vector2.UP], [Vector2(box.position.x, box.end.y), Vector2.RIGHT, Vector2.UP]]
	for corner: Array in corners:
		var at: Vector2 = corner[0]
		var path := PackedVector2Array([at + (corner[1] as Vector2) * arm, at, at + (corner[2] as Vector2) * arm])
		lines.append(InkLine.along(InkBrush.resample_polyline(path, style.sample_spacing), color, bracket_width))
	return lines


func _kill() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
