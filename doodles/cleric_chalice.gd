@tool
class_name ClericChalice
extends InkDrawing
## A doodle: the cleric. A chalice standing on the ground, seen a little from above: a wide domed foot, a
## slender stem with a round knop halfway up, and a wide cup with a band round it, whose open mouth shows
## as an ellipse with its shadowed inside. A few short rays of glow fan out over it. Its line is gold,
## with a gold wash in the chalice and a stronger one inside the cup. Its origin is the ground under its
## middle.

## How big the chalice is drawn, as a multiple of its natural size.
@export_range(0.2, 3.0, 0.01) var chalice_scale := 1.0:
	set(value):
		chalice_scale = value
		queue_redraw()
## Palette role of every line.
@export var role := &"gold":
	set(value):
		role = value
		queue_redraw()
## How strongly the chalice's wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()
## How strongly the wash inside the cup takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var inside_wash := 0.8:
	set(value):
		inside_wash = value
		queue_redraw()
## How many rays of glow fan out over the cup.
@export_range(0, 9) var ray_count := 5:
	set(value):
		ray_count = value
		queue_redraw()
## How wide the fan of glow spreads, in degrees, from its leftmost ray to its rightmost.
@export_range(0.0, 180.0, 1.0) var ray_spread := 110.0:
	set(value):
		ray_spread = value
		queue_redraw()

## The foot at natural size, from the left of its edge on the ground up over its dome to the stem and
## down to the right, and back along the ground.
const _FOOT := [Vector2(-58.0, -4.0), Vector2(-50.0, -13.0), Vector2(-30.0, -21.0), Vector2(-14.0, -28.0),
		Vector2(-9.0, -38.0), Vector2(9.0, -38.0), Vector2(14.0, -28.0), Vector2(30.0, -21.0), Vector2(50.0, -13.0),
		Vector2(58.0, -4.0), Vector2(36.0, 0.0), Vector2(-36.0, 0.0)]
## The stem, from where the foot hides its bottom up to where the cup hides its top, and the radius of
## its rounded corners.
const _STEM := Rect2(-8.0, -98.0, 16.0, 66.0)
const _STEM_CORNER := 4.0
## The knop halfway up the stem: its middle and its half width and height.
const _KNOP := [Vector2(0.0, -64.0), Vector2(19.0, 9.0)]
## The cup's mouth: the middle of its ellipse and its half width and height.
const _MOUTH := [Vector2(0.0, -180.0), Vector2(80.0, 11.0)]
## The cup's side, from the right end of its mouth down round its bottom to the left end.
const _CUP := [Vector2(80.0, -180.0), Vector2(76.0, -150.0), Vector2(62.0, -122.0), Vector2(38.0, -102.0),
		Vector2(12.0, -94.0), Vector2(-12.0, -94.0), Vector2(-38.0, -102.0), Vector2(-62.0, -122.0),
		Vector2(-76.0, -150.0), Vector2(-80.0, -180.0)]
## How far under the mouth's back edge the cup's own top edge runs, so the mouth's wash covers it.
const _MOUTH_TUCK := 4.0
## The band round the cup, from its left end on the cup's side to its right.
const _BAND := [Vector2(-77.0, -156.0), Vector2(-40.0, -148.0), Vector2(0.0, -146.0), Vector2(40.0, -148.0),
		Vector2(77.0, -156.0)]
## Where the glow's rays fan out from, and how far out from there each ray starts and ends.
const _GLOW_MIDDLE := Vector2(0.0, -180.0)
const _GLOW_REACH := Vector2(32.0, 48.0)
## Widths of the band and the rays, as multiples of the drawing's line width.
const _BAND_LINE := 0.7
const _RAY_LINE := 0.7


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var wash := palette.paper.lerp(color, wash_strength)
	var lines: Array[InkLine] = []
	# The stem stands behind the foot and the cup, the knop in front of it.
	lines.append(_washed(InkBrush.rounded_rect(_scaled_rect(_STEM), _STEM_CORNER * chalice_scale, spacing), color, wash))
	lines.append(_washed(InkBrush.resample_smooth(_scaled(_FOOT), true, spacing), color, wash))
	var knop_middle: Vector2 = _KNOP[0]
	var knop_radii: Vector2 = _KNOP[1]
	lines.append(_washed(InkBrush.ellipse(knop_middle * chalice_scale, knop_radii * chalice_scale, spacing, PI), color, wash))
	# The cup's side, closed along a curve just under the back edge of its mouth, which covers it.
	var mouth_middle: Vector2 = _MOUTH[0]
	var mouth_radii: Vector2 = _MOUTH[1]
	var cup := InkBrush.resample_smooth(_scaled(_CUP), false, spacing)
	var tucked := mouth_radii - Vector2(0.0, _MOUTH_TUCK)
	cup.append_array(_back(mouth_middle * chalice_scale, tucked * chalice_scale, spacing).slice(1, -1))
	lines.append(_washed(cup, color, wash))
	lines.append(InkLine.along(InkBrush.resample_smooth(_scaled(_BAND), false, spacing), color, _BAND_LINE))
	var mouth := InkBrush.ellipse(mouth_middle * chalice_scale, mouth_radii * chalice_scale, spacing, PI)
	lines.append(_washed(mouth, color, palette.paper.lerp(color, inside_wash)))
	var reach := _GLOW_REACH * chalice_scale
	for ray in ray_count:
		var share := 0.0 if ray_count == 1 else float(ray) / (ray_count - 1) - 0.5
		var way := Vector2.UP.rotated(deg_to_rad(ray_spread * share))
		var middle := _GLOW_MIDDLE * chalice_scale
		var stroke := PackedVector2Array([middle + way * reach.x, middle + way * reach.y])
		lines.append(InkLine.along(InkBrush.resample_polyline(stroke, spacing), color, _RAY_LINE))
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


func _scaled(points: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point: Vector2 in points:
		out.append(point * chalice_scale)
	return out


func _scaled_rect(rect: Rect2) -> Rect2:
	return Rect2(rect.position * chalice_scale, rect.size * chalice_scale)


## A closed line along [param path] with [param wash] inside it.
static func _washed(path: PackedVector2Array, color: Color, wash: Color) -> InkLine:
	var line := InkLine.along(path, color, 1.0, true)
	line.fill = wash
	return line
