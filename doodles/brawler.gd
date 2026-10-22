@tool
class_name Brawler
extends InkDrawing
## A doodle: an ordinary person squared up for a fight, a stick figure cousin of the souls with dot
## eyes. It faces the player in a wide stance with its knees a little bent, its elbows down and both
## fists up beside its chin in a boxing guard. The whole figure is drawn in one colour, which
## the game sets to tell the sides apart, with a wash of it inside each fist. Many of them stand in
## for a crowd. Its origin is the ground between its feet.

## Palette role of its line.
@export var role := &"blue":
	set(value):
		role = value
		queue_redraw()
## How strongly the wash inside each fist takes the line's colour over the paper.
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
## Radius of each fist.
@export_range(1.0, 20.0, 0.5) var fist_radius := 8.0:
	set(value):
		fist_radius = value
		queue_redraw()

const _HIPS := Vector2(0.0, -66.0)
const _NECK := Vector2(0.0, -134.0)
const _HEAD := Vector2(0.0, -156.0)
const _EYES := [Vector2(-5.5, -158.0), Vector2(5.5, -158.0)]
## Each arm, shoulder to elbow to fist, screen left first: the elbows down and the fists up under
## either side of the chin, the screen right one a little higher.
const _ARMS := [[Vector2(0.0, -124.0), Vector2(-33.0, -96.0), Vector2(-27.0, -130.0)],
		[Vector2(0.0, -124.0), Vector2(34.0, -99.0), Vector2(28.0, -134.0)]]
## Each leg, hip to knee to foot, screen left first: planted wide with the knees bent out.
const _LEGS := [[Vector2(0.0, -66.0), Vector2(-25.0, -34.0), Vector2(-34.0, 0.0)],
		[Vector2(0.0, -66.0), Vector2(24.0, -33.0), Vector2(34.0, 0.0)]]


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var lines: Array[InkLine] = []
	# Bare paper inside the head, so in a crowd the heads in front hide the figures behind them.
	var head := InkLine.along(InkBrush.ellipse(_HEAD, Vector2.ONE * head_radius, spacing, -PI * 0.75), color, 1.0, true)
	head.fill = palette.paper
	lines.append(head)
	lines.append(InkLine.along(InkBrush.resample_polyline(PackedVector2Array([_HIPS, _NECK]), spacing), color))
	for leg: Array in _LEGS:
		lines.append(InkLine.along(InkBrush.resample_polyline(PackedVector2Array(leg), spacing), color))
	for arm: Array in _ARMS:
		lines.append(InkLine.along(InkBrush.resample_polyline(PackedVector2Array(arm), spacing), color))
		var hand: Vector2 = arm[arm.size() - 1]
		var fist := InkLine.along(InkBrush.ellipse(hand, Vector2.ONE * fist_radius, spacing * 0.5), color, 0.9, true)
		fist.fill = palette.paper.lerp(color, wash_strength)
		lines.append(fist)
	for eye: Vector2 in _EYES:
		lines.append(InkLine.dot(eye, eye_radius, palette.ink))
	return lines
