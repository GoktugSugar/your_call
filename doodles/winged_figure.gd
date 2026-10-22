@tool
class_name WingedFigure
extends InkDrawing
## A doodle: a soul who can fly. An ink stick figure with dot eyes, floating a little off the ground
## with its arms held out and low, a pair of scalloped sky blue wings rising behind its shoulders,
## and two puffs of air beneath it. Its origin is the ground under it.

## How high it floats, from the ground to its feet.
@export_range(0.0, 120.0, 0.5) var lift := 30.0:
	set(value):
		lift = value
		queue_redraw()
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
## Palette role of the wings.
@export var wing_role := &"sky":
	set(value):
		wing_role = value
		queue_redraw()
## How strongly the wings' wash takes their colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()

## The figure at natural size, with its feet at the origin: it is lifted by [member lift] as it is drawn.
const _HIPS := Vector2(0.0, -65.0)
const _NECK := Vector2(0.0, -120.0)
const _HEAD := Vector2(0.0, -138.0)
const _SHOULDERS := Vector2(0.0, -112.0)
const _LEFT_LEG := [Vector2(0.0, -65.0), Vector2(-7.0, -32.0), Vector2(-12.0, 0.0)]
const _RIGHT_LEG := [Vector2(0.0, -65.0), Vector2(6.0, -33.0), Vector2(8.0, -1.0)]
const _LEFT_ARM := [Vector2(0.0, -112.0), Vector2(-26.0, -106.0), Vector2(-48.0, -94.0)]
const _RIGHT_ARM := [Vector2(0.0, -112.0), Vector2(26.0, -106.0), Vector2(48.0, -94.0)]
const _EYES := [Vector2(-5.0, -140.0), Vector2(5.0, -140.0)]
## The left wing, from the shoulder out to its tip and back along three scallops. The right mirrors it.
const _WING := [Vector2(-8.0, -112.0), Vector2(-34.0, -152.0), Vector2(-66.0, -176.0), Vector2(-74.0, -156.0),
		Vector2(-56.0, -152.0), Vector2(-64.0, -136.0), Vector2(-42.0, -132.0), Vector2(-46.0, -120.0)]
## Two puffs of air under its feet.
const _AIR := [[Vector2(-24.0, -14.0), Vector2(-14.0, -17.0), Vector2(-4.0, -14.0)],
		[Vector2(6.0, -8.0), Vector2(16.0, -11.0), Vector2(26.0, -8.0)]]


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var ink := palette.ink
	var up := Vector2(0.0, -lift)
	var lines: Array[InkLine] = []
	var wing_color := palette.color(wing_role)
	for side: float in [1.0, -1.0]:
		var wing := InkLine.along(InkBrush.resample_smooth(_placed(_WING, up, side), true, spacing), wing_color, 0.9, true)
		wing.fill = palette.paper.lerp(wing_color, wash_strength)
		lines.append(wing)
	lines.append(InkLine.along(InkBrush.ellipse(_HEAD + up, Vector2.ONE * head_radius, spacing, -PI * 0.75), ink, 1.0, true))
	lines.append(InkLine.along(InkBrush.resample_polyline(PackedVector2Array([_HIPS + up, _NECK + up]), spacing), ink))
	for limb: Array in [_LEFT_ARM, _RIGHT_ARM, _LEFT_LEG, _RIGHT_LEG]:
		lines.append(InkLine.along(InkBrush.resample_polyline(_placed(limb, up, 1.0), spacing), ink))
	for eye: Vector2 in _EYES:
		lines.append(InkLine.dot(eye + up, eye_radius, ink))
	for puff: Array in _AIR:
		lines.append(InkLine.along(InkBrush.resample_smooth(_placed(puff, Vector2.ZERO, 1.0), false, spacing), ink, 0.6))
	return lines


static func _placed(points: Array, offset: Vector2, side: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point: Vector2 in points:
		out.append(Vector2(point.x * side, point.y) + offset)
	return out
