@tool
class_name SheetGhost
extends InkDrawing
## A doodle: a ghost flatmate that means well and ruins everything. A sheet ghost floating just above
## the ground, facing out: one purple outline runs over its round head, out along both sheet arms, raised
## in a friendly wave, and down its sides to a wavy hem, with a purple wash inside. Two dot eyes, two
## folds in the sheet, a stroke of motion either side of the waving arm's end, and two puffs of air
## beneath it. Its origin is the ground under it.

## Palette role of its line.
@export var role := &"purple":
	set(value):
		role = value
		queue_redraw()
## How strongly the wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()
## Radius of each dot eye.
@export_range(0.5, 10.0, 0.1) var eye_radius := 3.6:
	set(value):
		eye_radius = value
		queue_redraw()

## The sheet's outline at natural size, clockwise from the top of its head: out along its waving screen
## right arm, down its side, back along its wavy hem, up its other side and out along its other arm.
const _OUTLINE := [Vector2(0.0, -206.0), Vector2(30.0, -198.0), Vector2(46.0, -176.0), Vector2(54.0, -154.0),
		Vector2(68.0, -162.0), Vector2(82.0, -180.0), Vector2(92.0, -186.0), Vector2(98.0, -176.0),
		Vector2(86.0, -154.0), Vector2(66.0, -134.0), Vector2(60.0, -108.0), Vector2(64.0, -74.0),
		Vector2(74.0, -40.0), Vector2(60.0, -28.0), Vector2(46.0, -40.0), Vector2(30.0, -26.0), Vector2(14.0, -38.0),
		Vector2(-2.0, -26.0), Vector2(-18.0, -38.0), Vector2(-34.0, -26.0), Vector2(-50.0, -38.0), Vector2(-64.0, -28.0),
		Vector2(-76.0, -40.0), Vector2(-66.0, -74.0), Vector2(-60.0, -108.0), Vector2(-68.0, -130.0),
		Vector2(-86.0, -146.0), Vector2(-96.0, -158.0), Vector2(-90.0, -168.0), Vector2(-74.0, -162.0),
		Vector2(-54.0, -154.0), Vector2(-46.0, -176.0), Vector2(-30.0, -198.0)]
const _EYES := [Vector2(-13.0, -172.0), Vector2(13.0, -172.0)]
## Two folds rising from the hem.
const _FOLDS := [[Vector2(-22.0, -40.0), Vector2(-24.0, -60.0), Vector2(-20.0, -78.0)],
		[Vector2(26.0, -38.0), Vector2(28.0, -56.0), Vector2(24.0, -70.0)]]
## The end of the waving arm, and the way the arm points there.
const _WAVE_HAND := Vector2(92.0, -180.0)
const _WAVE_REACH := Vector2(0.6, -0.8)
## A curved stroke of motion either side of the waving arm's end: where each starts and ends, in degrees
## round it from the way the arm points, outward positive.
const _WAVE := [[40.0, 100.0], [-40.0, -100.0]]
## Gap between the end of the arm and its strokes of motion.
const _WAVE_GAP := 16.0
## Points per stroke of motion, before it is smoothed.
const _WAVE_POINTS := 5
## Two puffs of air under the hem.
const _AIR := [[Vector2(-30.0, -10.0), Vector2(-18.0, -14.0), Vector2(-6.0, -10.0)],
		[Vector2(8.0, -4.0), Vector2(20.0, -8.0), Vector2(32.0, -4.0)]]


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var ink := palette.ink
	var lines: Array[InkLine] = []
	var sheet := InkLine.along(InkBrush.resample_smooth(PackedVector2Array(_OUTLINE), true, spacing), color, 1.0, true)
	sheet.fill = palette.paper.lerp(color, wash_strength)
	lines.append(sheet)
	for fold: Array in _FOLDS:
		lines.append(InkLine.along(InkBrush.resample_smooth(PackedVector2Array(fold), false, spacing), color, 0.7))
	var reach := _WAVE_REACH.normalized() * _WAVE_GAP
	for swing: Array in _WAVE:
		var arc := PackedVector2Array()
		for i in _WAVE_POINTS:
			arc.append(_WAVE_HAND + reach.rotated(deg_to_rad(lerpf(swing[0], swing[1], float(i) / (_WAVE_POINTS - 1)))))
		lines.append(InkLine.along(InkBrush.resample_smooth(arc, false, spacing), ink, 0.7))
	for eye: Vector2 in _EYES:
		lines.append(InkLine.dot(eye, eye_radius, ink))
	for puff: Array in _AIR:
		lines.append(InkLine.along(InkBrush.resample_smooth(PackedVector2Array(puff), false, spacing), ink, 0.6))
	return lines
