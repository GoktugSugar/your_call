@tool
class_name FlexingFigure
extends InkDrawing
## A doodle: a soul with super strength. A stick figure with dot eyes planted wide, both arms up in a
## double biceps flex with a bulge on each upper arm, and three short strokes of effort at each fist.
## Its origin is the ground between its feet.

## Radius of its head.
@export_range(4.0, 40.0, 0.5) var head_radius := 15.0:
	set(value):
		head_radius = value
		queue_redraw()
## Radius of each dot eye.
@export_range(0.5, 8.0, 0.1) var eye_radius := 2.8:
	set(value):
		eye_radius = value
		queue_redraw()
## Radius of each fist.
@export_range(1.0, 20.0, 0.5) var fist_radius := 5.5:
	set(value):
		fist_radius = value
		queue_redraw()

const _HIPS := Vector2(0.0, -64.0)
const _NECK := Vector2(0.0, -124.0)
const _HEAD := Vector2(0.0, -142.0)
const _EYES := [Vector2(-5.0, -144.0), Vector2(5.0, -144.0)]
## The screen left arm, shoulder to elbow to fist; the right mirrors it.
const _ARM := [Vector2(0.0, -114.0), Vector2(-42.0, -112.0), Vector2(-44.0, -150.0)]
## The bulge over the screen left upper arm.
const _BICEPS := [Vector2(-12.0, -116.0), Vector2(-26.0, -127.0), Vector2(-38.0, -116.0)]
## The screen left leg, hip to knee to foot.
const _LEG := [Vector2(0.0, -64.0), Vector2(-16.0, -32.0), Vector2(-24.0, 0.0)]
## Strokes of effort around the screen left fist.
const _EFFORT := [[Vector2(-56.0, -162.0), Vector2(-63.0, -170.0)], [Vector2(-59.0, -150.0), Vector2(-68.0, -151.0)],
		[Vector2(-50.0, -168.0), Vector2(-52.0, -178.0)]]


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var ink := palette.ink
	var lines: Array[InkLine] = []
	lines.append(InkLine.along(InkBrush.ellipse(_HEAD, Vector2.ONE * head_radius, spacing, -PI * 0.75), ink, 1.0, true))
	lines.append(InkLine.along(InkBrush.resample_polyline(PackedVector2Array([_HIPS, _NECK]), spacing), ink))
	for side: float in [1.0, -1.0]:
		lines.append(InkLine.along(InkBrush.resample_polyline(_mirrored(_LEG, side), spacing), ink))
		lines.append(InkLine.along(InkBrush.resample_polyline(_mirrored(_ARM, side), spacing), ink))
		lines.append(InkLine.along(InkBrush.resample_smooth(_mirrored(_BICEPS, side), false, spacing), ink, 0.9))
		var fist: Vector2 = _ARM[2] * Vector2(side, 1.0)
		lines.append(InkLine.along(InkBrush.ellipse(fist, Vector2.ONE * fist_radius, spacing * 0.5), ink, 0.9, true))
		for stroke: Array in _EFFORT:
			lines.append(InkLine.along(InkBrush.resample_polyline(_mirrored(stroke, side), spacing), ink, 0.6))
	for eye: Vector2 in _EYES:
		lines.append(InkLine.dot(eye, eye_radius, ink))
	return lines


static func _mirrored(points: Array, side: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point: Vector2 in points:
		out.append(Vector2(point.x * side, point.y))
	return out
