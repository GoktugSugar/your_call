@tool
class_name ThirdArmFigure
extends InkDrawing
## A doodle: a soul with a fully working third arm. An ink stick figure with dot eyes, its two
## ordinary arms hanging at its sides, and a third arm growing from the middle of its chest, raised
## and waving, with a stroke of motion either side of its hand. It stands a little left of its origin,
## so that it and its third arm together are centred on it. Its origin is the ground under it.

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
## Radius of the waving hand.
@export_range(1.0, 20.0, 0.5) var hand_radius := 5.5:
	set(value):
		hand_radius = value
		queue_redraw()

## The figure with its spine on the origin and its feet on the ground: it is moved over by
## [constant _SHIFT] as it is drawn.
const _HIPS := Vector2(0.0, -64.0)
const _NECK := Vector2(0.0, -124.0)
const _HEAD := Vector2(0.0, -142.0)
const _EYES := [Vector2(-5.0, -144.0), Vector2(5.0, -144.0)]
## The screen left arm, shoulder to elbow to hand, hanging at its side; the right mirrors it.
const _ARM := [Vector2(0.0, -114.0), Vector2(-12.0, -90.0), Vector2(-24.0, -66.0)]
## The screen left leg, hip to knee to foot; the right mirrors it.
const _LEG := [Vector2(0.0, -64.0), Vector2(-11.0, -32.0), Vector2(-17.0, 0.0)]
## The third arm, from the middle of the chest out to its elbow and up to its hand. It crosses in
## front of the screen right arm close to the chest, so it plainly grows from there.
const _THIRD_ARM := [Vector2(0.0, -93.0), Vector2(42.0, -102.0), Vector2(54.0, -146.0)]
## A curved stroke of motion either side of the waving hand: where each starts and ends, in degrees
## round the hand from the way its forearm points, outward positive.
const _WAVE := [[35.0, 105.0], [-35.0, -105.0]]
## Gap between the hand and its strokes of motion.
const _WAVE_GAP := 9.0
## Points per stroke of motion, before it is smoothed.
const _WAVE_POINTS := 5
## How far the whole figure is moved, so that it and its third arm are centred on the origin.
const _SHIFT := Vector2(-22.0, 0.0)


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var ink := palette.ink
	var lines: Array[InkLine] = []
	lines.append(InkLine.along(InkBrush.ellipse(_HEAD + _SHIFT, Vector2.ONE * head_radius, spacing, -PI * 0.75), ink, 1.0, true))
	lines.append(InkLine.along(InkBrush.resample_polyline(_placed([_HIPS, _NECK], 1.0), spacing), ink))
	for side: float in [1.0, -1.0]:
		lines.append(InkLine.along(InkBrush.resample_polyline(_placed(_LEG, side), spacing), ink))
		lines.append(InkLine.along(InkBrush.resample_polyline(_placed(_ARM, side), spacing), ink))
	lines.append(InkLine.along(InkBrush.resample_polyline(_placed(_THIRD_ARM, 1.0), spacing), ink))
	var elbow: Vector2 = _THIRD_ARM[1]
	var hand: Vector2 = _THIRD_ARM[2]
	lines.append(InkLine.along(InkBrush.ellipse(hand + _SHIFT, Vector2.ONE * hand_radius, spacing * 0.5), ink, 0.9, true))
	var reach := (hand - elbow).normalized() * (hand_radius + _WAVE_GAP)
	for swing: Array in _WAVE:
		var arc: Array[Vector2] = []
		for i in _WAVE_POINTS:
			arc.append(hand + reach.rotated(deg_to_rad(lerpf(swing[0], swing[1], float(i) / (_WAVE_POINTS - 1)))))
		lines.append(InkLine.along(InkBrush.resample_smooth(_placed(arc, 1.0), false, spacing), ink, 0.8))
	for eye: Vector2 in _EYES:
		lines.append(InkLine.dot(eye + _SHIFT, eye_radius, ink))
	return lines


## [param points] mirrored about the spine when [param side] is [code]-1[/code], then moved by [constant _SHIFT].
static func _placed(points: Array, side: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point: Vector2 in points:
		out.append(Vector2(point.x * side, point.y) + _SHIFT)
	return out
