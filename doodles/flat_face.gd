@tool
class_name FlatFace
extends InkDrawing
## A doodle: feeling nothing. A round face seen from the front, in quiet grey with a grey wash, with two
## dot eyes and one flat, straight line of a mouth. It is the one doodle face with a mouth, since here the
## face is the thing bought. It hangs a little off the ground. Its origin is the ground under it.

## How high its middle hangs, from the ground.
@export_range(0.0, 240.0, 0.5) var middle_height := 102.0:
	set(value):
		middle_height = value
		queue_redraw()
## Radius of the face.
@export_range(10.0, 120.0, 0.5) var face_radius := 78.0:
	set(value):
		face_radius = value
		queue_redraw()
## Palette role of the face's outline.
@export var role := &"secondary":
	set(value):
		role = value
		queue_redraw()
## How strongly the face's wash takes its colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()
## Radius of each dot eye.
@export_range(0.5, 12.0, 0.1) var eye_radius := 6.0:
	set(value):
		eye_radius = value
		queue_redraw()
## Length of the mouth, end to end.
@export_range(2.0, 160.0, 0.5) var mouth_length := 56.0:
	set(value):
		mouth_length = value
		queue_redraw()

## The screen left eye, from the face's middle, as a fraction of its radius; the right mirrors it.
const _EYE := Vector2(-0.33, -0.16)
## How far below the face's middle the mouth sits, as a fraction of its radius.
const _MOUTH_DROP := 0.4


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var middle := Vector2(0.0, -middle_height)
	var lines: Array[InkLine] = []
	var face := InkLine.along(InkBrush.ellipse(middle, Vector2.ONE * face_radius, spacing, -PI * 0.75), color, 1.0, true)
	face.fill = palette.paper.lerp(color, wash_strength)
	lines.append(face)
	var mouth := middle + Vector2(0.0, face_radius * _MOUTH_DROP)
	var ends := PackedVector2Array([mouth + Vector2.LEFT * mouth_length * 0.5, mouth + Vector2.RIGHT * mouth_length * 0.5])
	lines.append(InkLine.along(InkBrush.resample_polyline(ends, spacing), palette.ink))
	for side: float in [-1.0, 1.0]:
		lines.append(InkLine.dot(middle + Vector2(_EYE.x * side, _EYE.y) * face_radius, eye_radius, palette.ink))
	return lines
