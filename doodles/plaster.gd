@tool
class_name Plaster
extends InkDrawing
## A doodle: a sticking plaster, for never feeling physical pain again. A pink strip with rounded ends,
## set at a jaunty tilt, with a pad across its middle in a stronger pink wash and a few small holes
## dotted on each end. Its origin is the ground under its middle.

## Length and width of the strip.
@export var strip_size := Vector2(300.0, 92.0):
	set(value):
		strip_size = value
		queue_redraw()
## Radius of the strip's rounded corners.
@export_range(0.0, 60.0, 0.5) var corner_radius := 34.0:
	set(value):
		corner_radius = value
		queue_redraw()
## Length of the pad across its middle.
@export_range(10.0, 240.0, 0.5) var pad_length := 96.0:
	set(value):
		pad_length = value
		queue_redraw()
## Tilt of the strip, in degrees. Negative raises its right end.
@export_range(-90.0, 90.0, 0.5) var tilt := -24.0:
	set(value):
		tilt = value
		queue_redraw()
## How high its middle hangs, from the ground.
@export_range(0.0, 240.0, 0.5) var middle_height := 106.0:
	set(value):
		middle_height = value
		queue_redraw()
## Radius of each hole.
@export_range(0.5, 10.0, 0.1) var hole_radius := 3.4:
	set(value):
		hole_radius = value
		queue_redraw()
## Palette role of every line.
@export var role := &"pink":
	set(value):
		role = value
		queue_redraw()
## How strongly the strip's wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()
## How strongly the pad's wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var pad_wash := 0.7:
	set(value):
		pad_wash = value
		queue_redraw()

## How far the pad sits in from the strip's long edges.
const _PAD_INSET := 9.0
## Radius of the pad's rounded corners.
const _PAD_CORNER := 8.0
## The holes on each end of the strip, untilted: how far each sits in from the end, and how far off
## the strip's middle line.
const _HOLES := [Vector2(34.0, -14.0), Vector2(34.0, 14.0), Vector2(58.0, -14.0), Vector2(58.0, 14.0)]


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var half := strip_size * 0.5
	var lines: Array[InkLine] = []
	var strip := InkBrush.rounded_rect(Rect2(-half, strip_size), corner_radius, spacing)
	lines.append(_washed(_placed(strip), color, palette.paper.lerp(color, wash_strength)))
	var pad := Rect2(-pad_length * 0.5, -half.y + _PAD_INSET, pad_length, strip_size.y - _PAD_INSET * 2.0)
	lines.append(_washed(_placed(InkBrush.rounded_rect(pad, _PAD_CORNER, spacing)), color,
			palette.paper.lerp(color, pad_wash)))
	for side: float in [-1.0, 1.0]:
		for hole: Vector2 in _HOLES:
			lines.append(InkLine.dot(_place(Vector2((half.x - hole.x) * side, hole.y)), hole_radius, color))
	return lines


## [param point] of the untilted strip, tilted and lifted so the strip's middle hangs over the origin.
func _place(point: Vector2) -> Vector2:
	return point.rotated(deg_to_rad(tilt)) + Vector2(0.0, -middle_height)


func _placed(points: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point in points:
		out.append(_place(point))
	return out


## A closed line along [param path] with [param wash] inside.
static func _washed(path: PackedVector2Array, color: Color, wash: Color) -> InkLine:
	var line := InkLine.along(path, color, 1.0, true)
	line.fill = wash
	return line
