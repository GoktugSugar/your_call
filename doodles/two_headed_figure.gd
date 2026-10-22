@tool
class_name TwoHeadedFigure
extends InkDrawing
## A doodle: a soul with a second head. An ink stick figure whose one neck carries two heads side by
## side, each tilted a little away from the other and each with its own open dot eyes, both wide
## awake. Its arms hang at its sides. Its origin is the ground between its feet.

## Radius of each head.
@export_range(4.0, 40.0, 0.5) var head_radius := 15.0:
	set(value):
		head_radius = value
		queue_redraw()
## Radius of each dot eye.
@export_range(0.5, 8.0, 0.1) var eye_radius := 2.8:
	set(value):
		eye_radius = value
		queue_redraw()
## How far each head tilts away from the other, about the top of the neck, in degrees.
@export_range(0.0, 45.0, 0.5) var head_tilt := 15.0:
	set(value):
		head_tilt = value
		queue_redraw()

const _HIPS := Vector2(0.0, -64.0)
## The top of the one neck, where both heads sit.
const _NECK := Vector2(0.0, -130.0)
## The middle of the screen left head before it tilts, from the top of the neck; the right mirrors it.
const _HEAD := Vector2(-14.0, -11.5)
## The eyes of the screen left head, from its middle before it tilts; the right head's mirror them.
const _EYES := [Vector2(-5.0, -2.0), Vector2(5.0, -2.0)]
## The screen left arm, shoulder to elbow to hand, hanging at its side; the right mirrors it.
const _ARM := [Vector2(0.0, -114.0), Vector2(-12.0, -90.0), Vector2(-24.0, -66.0)]
## The screen left leg, hip to knee to foot; the right mirrors it.
const _LEG := [Vector2(0.0, -64.0), Vector2(-11.0, -32.0), Vector2(-17.0, 0.0)]


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var ink := palette.ink
	var lines: Array[InkLine] = []
	var eyes := PackedVector2Array()
	for side: float in [1.0, -1.0]:
		var tilt := -deg_to_rad(head_tilt) * side
		var head := _NECK + Vector2(_HEAD.x * side, _HEAD.y).rotated(tilt)
		lines.append(InkLine.along(InkBrush.ellipse(head, Vector2.ONE * head_radius, spacing, -PI * 0.75), ink, 1.0, true))
		for eye: Vector2 in _mirrored(_EYES, side):
			eyes.append(head + eye.rotated(tilt))
	lines.append(InkLine.along(InkBrush.resample_polyline(PackedVector2Array([_HIPS, _NECK]), spacing), ink))
	for side: float in [1.0, -1.0]:
		lines.append(InkLine.along(InkBrush.resample_polyline(_mirrored(_LEG, side), spacing), ink))
		lines.append(InkLine.along(InkBrush.resample_polyline(_mirrored(_ARM, side), spacing), ink))
	for eye in eyes:
		lines.append(InkLine.dot(eye, eye_radius, ink))
	return lines


static func _mirrored(points: Array, side: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point: Vector2 in points:
		out.append(Vector2(point.x * side, point.y))
	return out
