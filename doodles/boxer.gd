@tool
class_name Boxer
extends InkDrawing
## A doodle: a professional fighter. A stick figure cousin of the souls with dot eyes and a
## headband, its two tails flying out to the side, and big round boxing gloves up in front of its
## chin. It is light on its feet, caught mid bounce with both feet just off the ground and a puff of
## air under each. The whole figure is drawn in one colour, with a wash of it inside each glove.
## Its origin is the ground between its feet.

## Palette role of its line.
@export var role := &"red":
	set(value):
		role = value
		queue_redraw()
## How strongly the wash inside each glove takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()
## Radius of its head.
@export_range(4.0, 40.0, 0.5) var head_radius := 18.0:
	set(value):
		head_radius = value
		queue_redraw()
## Radius of each dot eye.
@export_range(0.5, 8.0, 0.1) var eye_radius := 3.2:
	set(value):
		eye_radius = value
		queue_redraw()
## Radius of each boxing glove.
@export_range(2.0, 30.0, 0.5) var glove_radius := 13.0:
	set(value):
		glove_radius = value
		queue_redraw()

## The figure mid bounce, its feet a little off the ground.
const _HIPS := Vector2(0.0, -80.0)
const _NECK := Vector2(0.0, -144.0)
const _HEAD := Vector2(0.0, -166.0)
const _EYES := [Vector2(-5.5, -165.0), Vector2(5.5, -165.0)]
## Each arm, shoulder to elbow to glove, screen left first: the elbows down and the gloves up in front
## of the chin.
const _ARMS := [[Vector2(0.0, -134.0), Vector2(-28.0, -110.0), Vector2(-15.0, -142.0)],
		[Vector2(0.0, -134.0), Vector2(29.0, -108.0), Vector2(16.0, -145.0)]]
## Each leg, hip to knee to foot, screen left first: knees bent and feet off the ground.
const _LEGS := [[Vector2(0.0, -80.0), Vector2(-25.0, -48.0), Vector2(-21.0, -12.0)],
		[Vector2(0.0, -80.0), Vector2(26.0, -49.0), Vector2(20.0, -10.0)]]
## The headband across the forehead, bowing a little round the head.
const _BAND := [Vector2(-17.0, -173.0), Vector2(0.0, -170.0), Vector2(17.0, -173.0)]
## The headband's two tails, flying out from its knot at the screen left of the head.
const _TAILS := [[Vector2(-17.0, -173.0), Vector2(-25.0, -181.0), Vector2(-33.0, -178.0), Vector2(-39.0, -186.0)],
		[Vector2(-17.0, -172.0), Vector2(-25.0, -167.0), Vector2(-32.0, -170.0), Vector2(-38.0, -163.0)]]
## A puff of air under each foot, where it bounced off the ground.
const _BOUNCES := [[Vector2(-32.0, -1.0), Vector2(-22.0, -5.0), Vector2(-12.0, -1.0)],
		[Vector2(10.0, -1.0), Vector2(20.0, -5.0), Vector2(30.0, -1.0)]]


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var lines: Array[InkLine] = []
	lines.append(InkLine.along(InkBrush.ellipse(_HEAD, Vector2.ONE * head_radius, spacing, -PI * 0.75), color, 1.0, true))
	lines.append(InkLine.along(InkBrush.resample_smooth(PackedVector2Array(_BAND), false, spacing), color, 1.1))
	for tail: Array in _TAILS:
		lines.append(InkLine.along(InkBrush.resample_smooth(PackedVector2Array(tail), false, spacing), color, 0.8))
	lines.append(InkLine.along(InkBrush.resample_polyline(PackedVector2Array([_HIPS, _NECK]), spacing), color))
	for leg: Array in _LEGS:
		lines.append(InkLine.along(InkBrush.resample_polyline(PackedVector2Array(leg), spacing), color))
	for bounce: Array in _BOUNCES:
		lines.append(InkLine.along(InkBrush.resample_smooth(PackedVector2Array(bounce), false, spacing), color, 0.6))
	for arm: Array in _ARMS:
		lines.append(InkLine.along(InkBrush.resample_polyline(PackedVector2Array(arm), spacing), color))
		var hand: Vector2 = arm[arm.size() - 1]
		var glove := InkLine.along(InkBrush.ellipse(hand, Vector2.ONE * glove_radius, spacing, -PI * 0.75), color, 1.0, true)
		glove.fill = palette.paper.lerp(color, wash_strength)
		lines.append(glove)
	for eye: Vector2 in _EYES:
		lines.append(InkLine.dot(eye, eye_radius, palette.ink))
	return lines
