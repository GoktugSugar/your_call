@tool
class_name Wasp
extends InkDrawing
## A doodle: a wasp, side on and facing right, hovering a little above the ground. Orange outlines with
## a wash inside draw its round head, its thorax and its long pointed abdomen, which is banded with
## three bold strokes of ink and ends in a sting; two pale wings rise behind it, three legs dangle
## under it and two antennae curl forward from its head, which has a single dot eye. Many of them stand
## in for a swarm. Its origin is the ground under it.

## Palette role of its line.
@export var role := &"orange":
	set(value):
		role = value
		queue_redraw()
## How strongly the wash inside its body takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()
## How strongly the wash inside its wings takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wing_wash_strength := 0.15:
	set(value):
		wing_wash_strength = value
		queue_redraw()
## Palette role of the bands across its abdomen.
@export var stripe_role := &"ink":
	set(value):
		stripe_role = value
		queue_redraw()
## How high it hovers, from the ground to the tips of its legs.
@export_range(0.0, 120.0, 0.5) var hover := 40.0:
	set(value):
		hover = value
		queue_redraw()
## Radius of the dot eye.
@export_range(0.5, 10.0, 0.1) var eye_radius := 3.4:
	set(value):
		eye_radius = value
		queue_redraw()

## The wasp with the tips of its legs on the ground: it is lifted by [member hover] as it is drawn.
const _HEAD := Vector2(70.0, -62.0)
const _HEAD_RADIUS := 17.0
const _THORAX := Vector2(36.0, -58.0)
const _THORAX_RADII := Vector2(24.0, 19.0)
## The abdomen's outline, from the narrow waist back along its top to its point, and back along its
## underside.
const _ABDOMEN := [Vector2(12.0, -58.0), Vector2(-8.0, -74.0), Vector2(-34.0, -80.0), Vector2(-62.0, -72.0),
		Vector2(-84.0, -58.0), Vector2(-94.0, -50.0), Vector2(-84.0, -42.0), Vector2(-58.0, -34.0),
		Vector2(-32.0, -34.0), Vector2(-8.0, -42.0), Vector2(8.0, -52.0)]
## The bands across the abdomen, each from its top edge to its underside.
const _STRIPES := [[Vector2(-14.0, -71.0), Vector2(-18.0, -57.0), Vector2(-14.0, -45.0)],
		[Vector2(-38.0, -76.0), Vector2(-42.0, -57.0), Vector2(-38.0, -38.0)],
		[Vector2(-62.0, -68.0), Vector2(-66.0, -53.0), Vector2(-62.0, -40.0)]]
## Width of a band's line, as a multiple of the line's width.
const _STRIPE_WIDTH := 1.5
const _STING := [Vector2(-90.0, -50.0), Vector2(-104.0, -47.0)]
## Each wing's middle, its half length and half width, and the way it points from its root to its
## tip, in degrees: the far wing first.
const _WINGS := [[Vector2(0.0, -96.0), Vector2(37.0, 11.0), -144.0], [Vector2(16.0, -105.0), Vector2(36.0, 12.0), -127.0]]
## The legs, each from under the thorax to its tip.
const _LEGS := [[Vector2(26.0, -42.0), Vector2(18.0, -20.0), Vector2(24.0, -2.0)],
		[Vector2(38.0, -40.0), Vector2(38.0, -18.0), Vector2(46.0, 0.0)],
		[Vector2(48.0, -44.0), Vector2(58.0, -24.0), Vector2(66.0, -14.0)]]
## The antennae, each from the top of the head out to its tip.
const _ANTENNAE := [[Vector2(74.0, -76.0), Vector2(86.0, -98.0), Vector2(104.0, -104.0)],
		[Vector2(66.0, -77.0), Vector2(70.0, -102.0), Vector2(80.0, -116.0)]]
const _EYE := Vector2(76.0, -64.0)
## Width of the legs, antennae and sting, as a multiple of the line's width.
const _FINE_WIDTH := 0.7


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var wash := palette.paper.lerp(color, wash_strength)
	var up := Vector2(0.0, -hover)
	var lines: Array[InkLine] = []
	for wing: Array in _WINGS:
		var outline := _wing(wing[0] + up, wing[1], wing[2], spacing)
		lines.append(_washed(outline, color, palette.paper.lerp(color, wing_wash_strength)))
	for fine: Array in _LEGS + _ANTENNAE:
		lines.append(InkLine.along(InkBrush.resample_smooth(_lifted(fine, up), false, spacing), color, _FINE_WIDTH))
	lines.append(InkLine.along(InkBrush.resample_polyline(_lifted(_STING, up), spacing), color, _FINE_WIDTH))
	lines.append(_washed(InkBrush.resample_smooth(_lifted(_ABDOMEN, up), true, spacing), color, wash))
	var stripe_color := palette.color(stripe_role)
	for stripe: Array in _STRIPES:
		lines.append(InkLine.along(InkBrush.resample_smooth(_lifted(stripe, up), false, spacing), stripe_color, _STRIPE_WIDTH))
	lines.append(_washed(InkBrush.ellipse(_THORAX + up, _THORAX_RADII, spacing, PI), color, wash))
	lines.append(_washed(InkBrush.ellipse(_HEAD + up, Vector2.ONE * _HEAD_RADIUS, spacing, -PI * 0.75), color, wash))
	lines.append(InkLine.dot(_EYE + up, eye_radius, palette.ink))
	return lines


## A wing's outline: an ellipse round [param middle] with [param radii], its long axis turned to
## [param degrees].
static func _wing(middle: Vector2, radii: Vector2, degrees: float, spacing: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var turn := deg_to_rad(degrees)
	for point in InkBrush.ellipse(Vector2.ZERO, radii, spacing):
		out.append(middle + point.rotated(turn))
	return out


static func _lifted(points: Array, up: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point: Vector2 in points:
		out.append(point + up)
	return out


## A closed line along [param path] with [param wash] inside.
static func _washed(path: PackedVector2Array, color: Color, wash: Color) -> InkLine:
	var line := InkLine.along(path, color, 1.0, true)
	line.fill = wash
	return line
