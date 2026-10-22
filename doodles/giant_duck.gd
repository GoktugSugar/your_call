@tool
class_name GiantDuck
extends InkDrawing
## A doodle: one duck grown to the size of a horse, seen side on and facing right. One gold outline
## runs from its tail over its back, up its neck and round its head, with a gold wash inside; it has
## an orange bill, orange webbed feet and a single dot eye. Its origin is the ground under its middle.

## How big the duck is drawn, as a multiple of its natural size.
@export_range(0.2, 3.0, 0.01) var duck_scale := 1.0:
	set(value):
		duck_scale = value
		queue_redraw()
## Palette role of the body, neck and head.
@export var body_role := &"gold":
	set(value):
		body_role = value
		queue_redraw()
## Palette role of the bill and feet.
@export var bill_role := &"orange":
	set(value):
		bill_role = value
		queue_redraw()
## How strongly each wash takes its line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()
## Radius of the dot eye.
@export_range(0.5, 10.0, 0.1) var eye_radius := 3.6:
	set(value):
		eye_radius = value
		queue_redraw()

## The duck's outline at natural size, from the tip of its tail over its back and head, and back
## under its chin, down its chest and along its belly.
const _OUTLINE := [Vector2(-142.0, -110.0), Vector2(-104.0, -96.0), Vector2(-44.0, -104.0), Vector2(8.0, -106.0),
		Vector2(40.0, -116.0), Vector2(46.0, -142.0), Vector2(44.0, -166.0), Vector2(56.0, -190.0),
		Vector2(82.0, -200.0), Vector2(106.0, -190.0), Vector2(114.0, -170.0), Vector2(108.0, -150.0),
		Vector2(96.0, -136.0), Vector2(90.0, -116.0), Vector2(100.0, -92.0), Vector2(104.0, -64.0),
		Vector2(88.0, -36.0), Vector2(44.0, -22.0), Vector2(-20.0, -20.0), Vector2(-80.0, -32.0),
		Vector2(-118.0, -56.0), Vector2(-134.0, -86.0)]
## The bill, tucked into the front of the head.
const _BILL := [Vector2(106.0, -174.0), Vector2(136.0, -172.0), Vector2(150.0, -163.0), Vector2(138.0, -153.0),
		Vector2(104.0, -152.0)]
## The fold of the wing along its side.
const _WING := [Vector2(-66.0, -88.0), Vector2(-12.0, -92.0), Vector2(26.0, -80.0), Vector2(16.0, -62.0), Vector2(-34.0, -58.0)]
const _EYE := Vector2(86.0, -176.0)
const _LEGS := [[Vector2(-20.0, -22.0), Vector2(-22.0, -3.0)], [Vector2(24.0, -22.0), Vector2(26.0, -3.0)]]
## Each webbed foot, pointing forward from the bottom of its leg.
const _FEET := [[Vector2(-22.0, -5.0), Vector2(-30.0, 0.0), Vector2(0.0, 0.0)],
		[Vector2(26.0, -5.0), Vector2(18.0, 0.0), Vector2(48.0, 0.0)]]


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var body_color := palette.color(body_role)
	var bill_color := palette.color(bill_role)
	var lines: Array[InkLine] = []
	# The legs and feet come first, so the body's wash hides the tops of the legs.
	for leg: Array in _LEGS:
		lines.append(InkLine.along(InkBrush.resample_polyline(_scaled(leg), spacing), bill_color))
	for foot: Array in _FEET:
		var corners := _scaled(foot)
		corners.append(corners[0])
		lines.append(_washed(InkBrush.resample_polyline(corners, spacing), bill_color, palette))
	lines.append(_washed(InkBrush.resample_smooth(_scaled(_OUTLINE), true, spacing), body_color, palette))
	lines.append(InkLine.along(InkBrush.resample_smooth(_scaled(_WING), false, spacing), body_color, 0.8))
	lines.append(_washed(InkBrush.resample_smooth(_scaled(_BILL), true, spacing), bill_color, palette))
	lines.append(InkLine.dot(_EYE * duck_scale, eye_radius, palette.ink))
	return lines


## A closed line along [param path] with a wash of its own colour inside.
func _washed(path: PackedVector2Array, color: Color, palette: InkPalette) -> InkLine:
	var line := InkLine.along(path, color, 1.0, true)
	line.fill = palette.paper.lerp(color, wash_strength)
	return line


func _scaled(points: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point: Vector2 in points:
		out.append(point * duck_scale)
	return out
