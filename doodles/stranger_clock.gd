@tool
class_name StrangerClock
extends InkDrawing
## A doodle: a stranger's years, skimmed into you. A small stick figure with dot eyes stands with its
## arms hanging beside a round clock on two short feet, whose hands point to ten past ten. Both are
## drawn in red, with a red wash in the clock's face. Its origin is the ground under its middle.

## Radius of the figure's head.
@export_range(4.0, 40.0, 0.5) var head_radius := 15.0:
	set(value):
		head_radius = value
		queue_redraw()
## Radius of each dot eye.
@export_range(0.5, 8.0, 0.1) var eye_radius := 2.7:
	set(value):
		eye_radius = value
		queue_redraw()
## Radius of the clock's face.
@export_range(10.0, 120.0, 0.5) var clock_radius := 76.0:
	set(value):
		clock_radius = value
		queue_redraw()
## Palette role of the figure and the clock.
@export var role := &"red":
	set(value):
		role = value
		queue_redraw()
## How strongly the clock face's wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()

## The figure at natural size, standing on the ground left of the clock.
const _HIPS := Vector2(-90.0, -68.0)
const _NECK := Vector2(-90.0, -132.0)
const _HEAD := Vector2(-90.0, -149.0)
const _EYES := [Vector2(-95.5, -151.0), Vector2(-84.5, -151.0)]
## Each arm hanging from the shoulder, through the elbow, to the hand.
const _ARMS := [[Vector2(-90.0, -121.0), Vector2(-102.0, -97.0), Vector2(-107.0, -71.0)],
		[Vector2(-90.0, -121.0), Vector2(-78.0, -97.0), Vector2(-73.0, -71.0)]]
## Each leg, from the hips through the knee to the foot.
const _LEGS := [[Vector2(-90.0, -68.0), Vector2(-98.0, -34.0), Vector2(-104.0, 0.0)],
		[Vector2(-90.0, -68.0), Vector2(-83.0, -34.0), Vector2(-76.0, 0.0)]]
## The middle of the clock's face, right of the origin and up from the ground.
const _CLOCK_MIDDLE := Vector2(30.0, -112.0)
## Where each of the clock's feet leaves its face, in degrees either side of straight down, and how
## far out from under the face it stands on the ground.
const _FOOT_ANGLE := 38.0
const _FOOT_SPLAY := 10.0
## The marks round the face, at twelve, three, six and nine: how far in from the rim each starts and
## ends, as fractions of the radius.
const _MARKS := 4
const _MARK_SPAN := Vector2(0.86, 0.7)
## Each hand of the clock: its angle clockwise from twelve in degrees, and its length as a fraction
## of the radius. The hour hand points at ten, the minute hand at two.
const _HANDS := [Vector2(-60.0, 0.46), Vector2(60.0, 0.68)]
## Radius of the pin the hands turn on.
const _PIN := 4.0


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var lines: Array[InkLine] = []
	lines.append(InkLine.along(InkBrush.ellipse(_HEAD, Vector2.ONE * head_radius, spacing, -PI * 0.75), color, 1.0, true))
	lines.append(InkLine.along(InkBrush.resample_polyline(PackedVector2Array([_NECK, _HIPS]), spacing), color))
	for limb: Array in _ARMS + _LEGS:
		lines.append(InkLine.along(InkBrush.resample_polyline(PackedVector2Array(limb), spacing), color))
	for eye: Vector2 in _EYES:
		lines.append(InkLine.dot(eye, eye_radius, palette.ink))
	# The feet go first, so the face hides where they meet it.
	for side: float in [-1.0, 1.0]:
		var top := _CLOCK_MIDDLE + Vector2.DOWN.rotated(deg_to_rad(_FOOT_ANGLE) * side) * clock_radius * 0.9
		var foot := Vector2(top.x - _FOOT_SPLAY * side, 0.0)
		lines.append(InkLine.along(InkBrush.resample_polyline(PackedVector2Array([top, foot]), spacing), color))
	var face := InkLine.along(InkBrush.ellipse(_CLOCK_MIDDLE, Vector2.ONE * clock_radius, spacing, -PI * 0.7), color, 1.0, true)
	face.fill = palette.paper.lerp(color, wash_strength)
	lines.append(face)
	for mark in _MARKS:
		var out := Vector2.UP.rotated(TAU * mark / _MARKS)
		var tick := PackedVector2Array([_CLOCK_MIDDLE + out * clock_radius * _MARK_SPAN.x,
				_CLOCK_MIDDLE + out * clock_radius * _MARK_SPAN.y])
		lines.append(InkLine.along(InkBrush.resample_polyline(tick, spacing), color, 0.8))
	for hand: Vector2 in _HANDS:
		var tip := _CLOCK_MIDDLE + Vector2.UP.rotated(deg_to_rad(hand.x)) * clock_radius * hand.y
		lines.append(InkLine.along(InkBrush.resample_polyline(PackedVector2Array([_CLOCK_MIDDLE, tip]), spacing), color))
	lines.append(InkLine.dot(_CLOCK_MIDDLE, _PIN, color))
	return lines
