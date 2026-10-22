@tool
class_name Trophy
extends InkDrawing
## A doodle: glory. A two handled trophy cup standing on a base, seen a little from above: a block with
## a blank plaque on its front and a narrower step on top, a short stem flaring out at its foot with a
## ring round it, and a deep cup whose open mouth shows its shadowed inside, a looping handle either
## side. Its line is orange, with an orange wash in the trophy, a stronger one inside the cup and a pale
## one on the plaque. Its origin is the ground under its middle.

## How big the trophy is drawn, as a multiple of its natural size.
@export_range(0.2, 3.0, 0.01) var trophy_scale := 1.0:
	set(value):
		trophy_scale = value
		queue_redraw()
## Palette role of every line.
@export var role := &"orange":
	set(value):
		role = value
		queue_redraw()
## How strongly the trophy's wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()
## How strongly the wash inside the cup takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var inside_wash := 0.75:
	set(value):
		inside_wash = value
		queue_redraw()
## How strongly the plaque's wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var plaque_wash := 0.12:
	set(value):
		plaque_wash = value
		queue_redraw()
## Width of each handle's band, at natural size.
@export_range(2.0, 40.0, 0.5) var handle_width := 13.0:
	set(value):
		handle_width = value
		queue_redraw()

## The base at natural size: the block on the ground, the step on top of it, whose foot the block hides,
## and the plaque on the block's front; with the radius of each one's rounded corners.
const _BLOCK := Rect2(-62.0, -34.0, 124.0, 34.0)
const _STEP := Rect2(-46.0, -50.0, 92.0, 22.0)
const _PLAQUE := Rect2(-26.0, -25.0, 52.0, 15.0)
const _BASE_CORNERS := Vector3(5.0, 4.0, 3.0)
## The stem, from under the cup down to its flared foot on the step, and back up.
const _STEM := [Vector2(-8.0, -100.0), Vector2(8.0, -100.0), Vector2(8.0, -72.0), Vector2(13.0, -60.0),
		Vector2(22.0, -48.0), Vector2(-22.0, -48.0), Vector2(-13.0, -60.0), Vector2(-8.0, -72.0)]
## The ring round the stem: its middle and its half width and height.
const _RING := [Vector2(0.0, -76.0), Vector2(14.0, 6.0)]
## The cup's mouth: the middle of its ellipse and its half width and height.
const _MOUTH := [Vector2(0.0, -196.0), Vector2(66.0, 10.0)]
## The cup's side, from the right end of its mouth down round its bottom to the left end.
const _CUP := [Vector2(66.0, -196.0), Vector2(64.0, -164.0), Vector2(54.0, -128.0), Vector2(34.0, -103.0),
		Vector2(12.0, -93.0), Vector2(-12.0, -93.0), Vector2(-34.0, -103.0), Vector2(-54.0, -128.0),
		Vector2(-64.0, -164.0), Vector2(-66.0, -196.0)]
## How far under the mouth's back edge the cup's own top edge runs, so the mouth's wash covers it.
const _MOUTH_TUCK := 4.0
## The middle of the right handle's band, from inside the cup near its mouth out round its loop and back
## into the cup lower down. The left handle mirrors it.
const _HANDLE := [Vector2(56.0, -182.0), Vector2(86.0, -186.0), Vector2(102.0, -168.0), Vector2(98.0, -144.0),
		Vector2(76.0, -128.0), Vector2(44.0, -120.0)]


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var wash := palette.paper.lerp(color, wash_strength)
	var lines: Array[InkLine] = []
	# Back to front: the handles, whose ends the cup hides; the stem, whose ends the step and the cup
	# hide; the step, whose foot the block hides; then the block, the ring, the cup and its mouth.
	for side: float in [1.0, -1.0]:
		var spine := InkBrush.resample_smooth(_placed(_HANDLE, side), false, spacing)
		lines.append(_washed(_band(spine, handle_width * trophy_scale), color, wash))
	lines.append(_washed(InkBrush.resample_smooth(_placed(_STEM), true, spacing), color, wash))
	lines.append(_washed(InkBrush.rounded_rect(_scaled_rect(_STEP), _BASE_CORNERS.y * trophy_scale, spacing), color, wash))
	lines.append(_washed(InkBrush.rounded_rect(_scaled_rect(_BLOCK), _BASE_CORNERS.x * trophy_scale, spacing), color, wash))
	var plaque := InkBrush.rounded_rect(_scaled_rect(_PLAQUE), _BASE_CORNERS.z * trophy_scale, spacing * 0.5)
	lines.append(_washed(plaque, color, palette.paper.lerp(color, plaque_wash), 0.7))
	var ring_middle: Vector2 = _RING[0]
	var ring_radii: Vector2 = _RING[1]
	lines.append(_washed(InkBrush.ellipse(ring_middle * trophy_scale, ring_radii * trophy_scale, spacing, PI), color, wash))
	var mouth_middle: Vector2 = _MOUTH[0]
	var mouth_radii: Vector2 = _MOUTH[1]
	var cup := InkBrush.resample_smooth(_placed(_CUP), false, spacing)
	var tucked := (mouth_radii - Vector2(0.0, _MOUTH_TUCK)) * trophy_scale
	cup.append_array(_back(mouth_middle * trophy_scale, tucked, spacing).slice(1, -1))
	lines.append(_washed(cup, color, wash))
	var mouth := InkBrush.ellipse(mouth_middle * trophy_scale, mouth_radii * trophy_scale, spacing, PI)
	lines.append(_washed(mouth, color, palette.paper.lerp(color, inside_wash)))
	return lines


## The back half of the ellipse round [param middle] with [param radii], from its left end over the top
## to its right end.
static func _back(middle: Vector2, radii: Vector2, spacing: float) -> PackedVector2Array:
	var steps := maxi(2, ceili(PI * sqrt((radii.x * radii.x + radii.y * radii.y) * 0.5) / spacing))
	var out := PackedVector2Array()
	for k in steps + 1:
		var angle := PI + PI * k / steps
		out.append(middle + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	return out


## A closed outline round [param spine], [param width] wide all along it: out along one side and back
## along the other, square across both ends.
static func _band(spine: PackedVector2Array, width: float) -> PackedVector2Array:
	var count := spine.size()
	var near := PackedVector2Array()
	var far := PackedVector2Array()
	for i in count:
		var along := spine[mini(i + 1, count - 1)] - spine[maxi(i - 1, 0)]
		var across := along.normalized().orthogonal() * width * 0.5
		near.append(spine[i] + across)
		far.append(spine[i] - across)
	far.reverse()
	near.append_array(far)
	return near


## [param points] at natural size, with x mirrored by [param side], drawn [member trophy_scale] times as big.
func _placed(points: Array, side := 1.0) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point: Vector2 in points:
		out.append(Vector2(point.x * side, point.y) * trophy_scale)
	return out


func _scaled_rect(rect: Rect2) -> Rect2:
	return Rect2(rect.position * trophy_scale, rect.size * trophy_scale)


## A closed line along [param path] with [param wash] inside it, [param width] times the drawing's
## line width.
static func _washed(path: PackedVector2Array, color: Color, wash: Color, width := 1.0) -> InkLine:
	var line := InkLine.along(path, color, width, true)
	line.fill = wash
	return line
