@tool
class_name InsultingCat
extends InkDrawing
## A doodle: a cat that only insults you. A purple cat sits facing out, its tail curled round its
## front paws. Its pointed ears are bumps of its head's own outline, laid back a touch, and its head is
## tipped up and a little aside, so its dot eyes sit high over three whiskers a side and it looks down
## its nose at you. A purple wash fills it. Its origin is the ground under its middle.

## How big the cat is drawn, as a multiple of its natural size.
@export_range(0.2, 3.0, 0.01) var cat_scale := 1.0:
	set(value):
		cat_scale = value
		queue_redraw()
## How far its head tips over, in degrees, clockwise.
@export_range(-30.0, 30.0, 0.5) var head_tilt := -12.0:
	set(value):
		head_tilt = value
		queue_redraw()
## Palette role of the line.
@export var line_role := &"purple":
	set(value):
		line_role = value
		queue_redraw()
## How strongly each wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()
## Radius of each dot eye.
@export_range(0.5, 10.0, 0.1) var eye_radius := 3.4:
	set(value):
		eye_radius = value
		queue_redraw()
## Thickness of its tail where it leaves the body, at natural size.
@export_range(2.0, 40.0, 0.5) var tail_width := 16.0:
	set(value):
		tail_width = value
		queue_redraw()

## The body at natural size, from the left of its neck down round its haunches and up to the right of
## its neck. The head hides its top.
const _BODY := [Vector2(-26.0, -118.0), Vector2(-42.0, -94.0), Vector2(-54.0, -60.0), Vector2(-64.0, -28.0),
		Vector2(-60.0, -6.0), Vector2(-32.0, 0.0), Vector2(32.0, 0.0), Vector2(60.0, -6.0), Vector2(64.0, -28.0),
		Vector2(54.0, -60.0), Vector2(42.0, -94.0), Vector2(26.0, -118.0), Vector2(0.0, -124.0)]
## The middle of the head, which it tips about.
const _HEAD_MIDDLE := Vector2(0.0, -150.0)
## The head's outline from its middle, in two smooth runs that meet in the sharp tips of its ears: from
## the left tip down round its cheeks and chin to the right tip, then back over its crown.
const _HEAD := [
	[Vector2(-56.0, -64.0), Vector2(-48.0, -30.0), Vector2(-52.0, -6.0), Vector2(-46.0, 16.0), Vector2(-28.0, 30.0),
			Vector2(0.0, 36.0), Vector2(28.0, 30.0), Vector2(46.0, 16.0), Vector2(52.0, -6.0), Vector2(48.0, -30.0),
			Vector2(56.0, -64.0)],
	[Vector2(56.0, -64.0), Vector2(20.0, -40.0), Vector2(0.0, -42.0), Vector2(-20.0, -40.0), Vector2(-56.0, -64.0)],
]
## How far its face is turned aside and up, from the middle of the head: the eyes and whiskers move by this.
const _FACE_TURN := Vector2(-14.0, -8.0)
## The dot eyes from the middle of the head, set high, for its chin is up.
const _EYES := [Vector2(-13.0, -11.0), Vector2(13.0, -11.0)]
## The left whiskers from the middle of the head, each from its root on the cheek out past the head,
## fanned a little upward; the right mirror them.
const _WHISKERS := [[Vector2(-12.0, 6.0), Vector2(-68.0, -14.0)], [Vector2(-12.0, 12.0), Vector2(-72.0, 4.0)],
		[Vector2(-10.0, 18.0), Vector2(-66.0, 20.0)]]
## The outer edge of the left front leg, chest to paw; the right mirrors it.
const _LEG := [Vector2(-24.0, -88.0), Vector2(-30.0, -52.0), Vector2(-30.0, -26.0)]
## The parting between the two front legs.
const _PARTING := [Vector2(0.0, -54.0), Vector2(0.0, -26.0)]
## The middle of the left front paw; the right mirrors it.
const _PAW := Vector2(-16.0, -21.0)
## The radii of each front paw.
const _PAW_RADII := Vector2(16.0, 9.0)
## The middle of the tail, from where it comes out from behind the right haunch, down and round in
## front of the paws to its tip curling up on the left.
const _TAIL := [Vector2(60.0, -37.0), Vector2(71.0, -31.0), Vector2(74.0, -19.0), Vector2(64.0, -9.0),
		Vector2(40.0, -9.0), Vector2(0.0, -9.0), Vector2(-44.0, -10.0), Vector2(-64.0, -17.0), Vector2(-70.0, -31.0)]
## How thick the tail is at its tip, as a fraction of [member tail_width].
const _TAIL_TIP := 0.7


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(line_role)
	var wash := palette.paper.lerp(color, wash_strength)
	var lines: Array[InkLine] = []
	lines.append(_washed(InkBrush.resample_smooth(_scaled(_BODY, 1.0), true, spacing), color, wash, true))
	for side: float in [1.0, -1.0]:
		lines.append(InkLine.along(InkBrush.resample_smooth(_scaled(_LEG, side), false, spacing), color, 0.8))
	lines.append(InkLine.along(InkBrush.resample_polyline(_scaled(_PARTING, 1.0), spacing), color, 0.8))
	for side: float in [1.0, -1.0]:
		var paw := InkBrush.ellipse(Vector2(_PAW.x * side, _PAW.y) * cat_scale, _PAW_RADII * cat_scale, spacing)
		lines.append(_washed(paw, color, wash, true))
	lines.append(_washed(_band(_scaled(_TAIL, 1.0), tail_width * cat_scale, _TAIL_TIP, spacing), color, wash, false))
	var head := PackedVector2Array()
	for run: Array in _HEAD:
		var part := InkBrush.resample_smooth(_tipped(run, 1.0, Vector2.ZERO), false, spacing)
		head.append_array(part if head.is_empty() else part.slice(1))
	lines.append(_washed(head, color, wash, true))
	for side: float in [1.0, -1.0]:
		for whisker: Array in _WHISKERS:
			lines.append(InkLine.along(InkBrush.resample_polyline(_tipped(whisker, side, _FACE_TURN), spacing), color, 0.6))
	for eye: Vector2 in _tipped(_EYES, 1.0, _FACE_TURN):
		lines.append(InkLine.dot(eye, eye_radius, palette.ink))
	return lines


## A line along [param path] with [param wash] inside it.
static func _washed(path: PackedVector2Array, color: Color, wash: Color, closed: bool) -> InkLine:
	var line := InkLine.along(path, color, 1.0, closed)
	line.fill = wash
	return line


## The outline of a band [param width] wide along the smooth [param spine], narrowing to
## [param tip_share] of that at its far end, which is capped round: out along one side, round the tip
## and back along the other. Its near end is left open.
static func _band(spine: PackedVector2Array, width: float, tip_share: float, spacing: float) -> PackedVector2Array:
	var middle := InkBrush.resample_smooth(spine, false, spacing)
	var n := middle.size()
	var near_side := PackedVector2Array()
	var far_side := PackedVector2Array()
	var tangent := Vector2.RIGHT
	var half := width * 0.5
	for i in n:
		tangent = (middle[mini(i + 1, n - 1)] - middle[maxi(i - 1, 0)]).normalized()
		half = width * 0.5 * lerpf(1.0, tip_share, float(i) / (n - 1))
		near_side.append(middle[i] + tangent.orthogonal() * half)
		far_side.append(middle[i] - tangent.orthogonal() * half)
	var cap_steps := maxi(2, ceili(PI * half / spacing))
	for k in range(1, cap_steps):
		var angle := PI * k / cap_steps
		near_side.append(middle[n - 1] + (tangent.orthogonal() * cos(angle) + tangent * sin(angle)) * half)
	far_side.reverse()
	near_side.append_array(far_side)
	return near_side


## [param points] of the body at natural size, mirrored about the middle when [param side] is
## [code]-1[/code], and scaled.
func _scaled(points: Array, side: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point: Vector2 in points:
		out.append(Vector2(point.x * side, point.y) * cat_scale)
	return out


## [param points] of the head, from its middle: mirrored about the face when [param side] is
## [code]-1[/code], moved by [param turn], tipped by [member head_tilt] and scaled.
func _tipped(points: Array, side: float, turn: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	var tilt := deg_to_rad(head_tilt)
	for point: Vector2 in points:
		out.append((_HEAD_MIDDLE + (Vector2(point.x * side, point.y) + turn).rotated(tilt)) * cat_scale)
	return out
