@tool
class_name Chicken
extends InkDrawing
## A doodle: a chicken, side on and facing right. One orange outline runs from the tip of its raised
## tail round its plump belly, up its breast and neck and over its head, with a wash inside; it has a
## comb of three bumps, a beak and a wattle, a fold of wing along its side, two stick legs with
## splayed toes and a single dot eye. Many of them stand in for a flock.
## Its origin is the ground under its middle.

## Palette role of its line.
@export var role := &"orange":
	set(value):
		role = value
		queue_redraw()
## How strongly each wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()
## Radius of the dot eye.
@export_range(0.5, 10.0, 0.1) var eye_radius := 3.4:
	set(value):
		eye_radius = value
		queue_redraw()

## The outline, from the tip of the tail down its back edge, round the belly, up the breast and the
## neck, over the head and down the back of the neck, and along the back to the tail.
const _OUTLINE := [Vector2(-86.0, -156.0), Vector2(-100.0, -134.0), Vector2(-104.0, -106.0), Vector2(-94.0, -78.0),
		Vector2(-70.0, -54.0), Vector2(-30.0, -42.0), Vector2(14.0, -42.0), Vector2(52.0, -54.0), Vector2(76.0, -78.0),
		Vector2(84.0, -104.0), Vector2(88.0, -126.0), Vector2(96.0, -140.0), Vector2(100.0, -154.0),
		Vector2(92.0, -168.0), Vector2(76.0, -172.0), Vector2(62.0, -162.0), Vector2(56.0, -144.0),
		Vector2(52.0, -124.0), Vector2(32.0, -110.0), Vector2(-10.0, -106.0), Vector2(-46.0, -112.0),
		Vector2(-66.0, -130.0)]
## The comb, three bumps standing up from the top of the head. Its base hides behind the head.
const _COMB := [Vector2(64.0, -164.0), Vector2(60.0, -180.0), Vector2(66.0, -190.0), Vector2(74.0, -182.0),
		Vector2(82.0, -196.0), Vector2(90.0, -184.0), Vector2(98.0, -188.0), Vector2(102.0, -174.0),
		Vector2(96.0, -162.0)]
## The beak's three corners. Its base hides behind the head.
const _BEAK := [Vector2(94.0, -154.0), Vector2(116.0, -147.0), Vector2(94.0, -138.0)]
## The wattle hanging under the beak. Its top hides behind the head.
const _WATTLE := [Vector2(96.0, -142.0), Vector2(106.0, -134.0), Vector2(104.0, -122.0), Vector2(96.0, -124.0),
		Vector2(92.0, -134.0)]
## The fold of the wing along its side.
const _WING := [Vector2(-44.0, -98.0), Vector2(-4.0, -98.0), Vector2(30.0, -84.0), Vector2(16.0, -64.0),
		Vector2(-26.0, -64.0)]
const _EYE := Vector2(84.0, -156.0)
const _LEGS := [[Vector2(-14.0, -44.0), Vector2(-16.0, -6.0)], [Vector2(16.0, -44.0), Vector2(18.0, -6.0)]]
## Each foot, from its back toe up to the bottom of its leg and down to its front toe.
const _FEET := [[Vector2(-26.0, 0.0), Vector2(-16.0, -6.0), Vector2(0.0, 0.0)],
		[Vector2(8.0, 0.0), Vector2(18.0, -6.0), Vector2(34.0, 0.0)]]


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var wash := palette.paper.lerp(color, wash_strength)
	var lines: Array[InkLine] = []
	# The legs, comb, beak and wattle come first, so the body's wash hides where they join it.
	for leg: Array in _LEGS:
		lines.append(InkLine.along(InkBrush.resample_polyline(PackedVector2Array(leg), spacing), color, 0.9))
	for foot: Array in _FEET:
		lines.append(InkLine.along(InkBrush.resample_polyline(PackedVector2Array(foot), spacing), color, 0.8))
	lines.append(_washed(InkBrush.resample_smooth(PackedVector2Array(_COMB), true, spacing), color, wash))
	lines.append(_washed(InkBrush.resample_smooth(PackedVector2Array(_WATTLE), true, spacing), color, wash))
	var beak := PackedVector2Array(_BEAK)
	beak.append(beak[0])
	lines.append(_washed(InkBrush.resample_polyline(beak, spacing), color, wash))
	lines.append(_washed(InkBrush.resample_smooth(PackedVector2Array(_OUTLINE), true, spacing), color, wash))
	lines.append(InkLine.along(InkBrush.resample_smooth(PackedVector2Array(_WING), false, spacing), color, 0.8))
	lines.append(InkLine.dot(_EYE, eye_radius, palette.ink))
	return lines


## A closed line along [param path] with [param wash] inside.
static func _washed(path: PackedVector2Array, color: Color, wash: Color) -> InkLine:
	var line := InkLine.along(path, color, 1.0, true)
	line.fill = wash
	return line
