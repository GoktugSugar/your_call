@tool
class_name Sneaker
extends InkDrawing
## A doodle: shoes that never hurt. One orange sneaker seen side on with its toe to the right: a thick
## pale sole with a line along it, a toe cap, a heel counter and a plain side panel along the eyestay,
## no marks of any brand, and its laces crossing over the tongue. An orange wash fills the upper and a
## paler one the sole. Its origin is the ground under its middle.

## How big the sneaker is drawn, as a multiple of its natural size.
@export_range(0.2, 3.0, 0.01) var shoe_scale := 1.08:
	set(value):
		shoe_scale = value
		queue_redraw()
## Palette role of the line.
@export var line_role := &"orange":
	set(value):
		line_role = value
		queue_redraw()
## How strongly the upper's wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()
## How strongly the sole's wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var sole_wash := 0.12:
	set(value):
		sole_wash = value
		queue_redraw()
## How many laces cross over the tongue.
@export_range(1, 8) var lace_count := 4:
	set(value):
		lace_count = value
		queue_redraw()
## Half the height of each lace's cross, at natural size: it hangs this far and as far again under the
## top of the shoe.
@export_range(1.0, 30.0, 0.5) var lace_reach := 11.0:
	set(value):
		lace_reach = value
		queue_redraw()

## The upper at natural size, in smooth runs that meet in its corners: up the back of the heel, along
## the collar round the ankle, up and over the tongue, down the laced top of the foot round the toe, and
## back along the top of the sole, which hides that last edge.
const _UPPER := [
	[Vector2(-130.0, -34.0), Vector2(-142.0, -70.0), Vector2(-138.0, -110.0), Vector2(-126.0, -126.0)],
	[Vector2(-126.0, -126.0), Vector2(-102.0, -116.0), Vector2(-78.0, -114.0), Vector2(-62.0, -124.0)],
	[Vector2(-62.0, -124.0), Vector2(-64.0, -146.0), Vector2(-50.0, -156.0), Vector2(-36.0, -146.0), Vector2(-32.0, -130.0)],
	[Vector2(-32.0, -130.0), Vector2(0.0, -110.0), Vector2(40.0, -88.0), Vector2(84.0, -70.0), Vector2(118.0, -60.0),
			Vector2(136.0, -48.0), Vector2(140.0, -34.0)],
	[Vector2(140.0, -34.0), Vector2(-130.0, -34.0)],
]
## The laced top of the foot, from the tongue down toward the toe. The laces cross the band under it,
## evenly spaced.
const _LACING := [Vector2(-32.0, -130.0), Vector2(0.0, -110.0), Vector2(40.0, -88.0), Vector2(60.0, -79.0)]
## How far along the laced top the laces start and end, as fractions of it.
const _LACES_FROM := 0.06
const _LACES_TO := 1.0
## How wide each lace's cross is, as a fraction of its height.
const _LACE_SPREAD := 0.7
## The side panel's edge along the eyestay, under the laces, from the collar down to the toe cap.
const _PANEL := [Vector2(-70.0, -112.0), Vector2(-32.0, -107.0), Vector2(6.0, -87.0), Vector2(50.0, -68.0),
		Vector2(92.0, -56.0)]
## The toe cap's edge, from the sole up over the toe.
const _TOE_CAP := [Vector2(94.0, -35.0), Vector2(92.0, -52.0), Vector2(104.0, -63.0)]
## The heel counter's edge, from the sole up toward the collar.
const _HEEL := [Vector2(-104.0, -35.0), Vector2(-100.0, -74.0), Vector2(-114.0, -116.0)]
## The sole, from the heel along its top to the toe, round the toe and back along the ground.
const _SOLE := [Vector2(-140.0, -38.0), Vector2(-60.0, -35.0), Vector2(40.0, -35.0), Vector2(120.0, -37.0),
		Vector2(146.0, -40.0), Vector2(154.0, -26.0), Vector2(146.0, -8.0), Vector2(124.0, -1.0), Vector2(-128.0, -1.0),
		Vector2(-148.0, -5.0), Vector2(-152.0, -21.0)]
## The line along the sole.
const _SOLE_LINE := [Vector2(-136.0, -16.0), Vector2(0.0, -15.0), Vector2(136.0, -17.0)]


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(line_role)
	var lines: Array[InkLine] = []
	var upper := PackedVector2Array()
	for run: Array in _UPPER:
		var part := InkBrush.resample_smooth(_scaled(run), false, spacing)
		upper.append_array(part if upper.is_empty() else part.slice(1))
	lines.append(_washed(upper, color, palette.paper.lerp(color, wash_strength)))
	for edge: Array in [_PANEL, _TOE_CAP, _HEEL]:
		lines.append(InkLine.along(InkBrush.resample_smooth(_scaled(edge), false, spacing), color, 0.8))
	lines.append(_washed(InkBrush.resample_smooth(_scaled(_SOLE), true, spacing), color, palette.paper.lerp(color, sole_wash)))
	lines.append(InkLine.along(InkBrush.resample_smooth(_scaled(_SOLE_LINE), false, spacing), color, 0.7))
	var lacing := InkBrush.resample_smooth(_scaled(_LACING), false, spacing)
	var reach := lace_reach * shoe_scale
	for lace in lace_count:
		var share := lerpf(_LACES_FROM, _LACES_TO, (lace + 0.5) / lace_count)
		var at := mini(roundi(share * (lacing.size() - 1)), lacing.size() - 2)
		var along := (lacing[at + 1] - lacing[at]).normalized()
		# Each cross hangs from the top of the shoe into the band under it.
		var inward := -along.orthogonal() * reach
		var middle := lacing[at] + inward
		for slant: float in [1.0, -1.0]:
			var tilt := along * reach * _LACE_SPREAD * slant
			var stroke := PackedVector2Array([middle - inward - tilt, middle + inward + tilt])
			lines.append(InkLine.along(InkBrush.resample_polyline(stroke, spacing), color, 0.8))
	return lines


## A closed line along [param path] with [param wash] inside it.
static func _washed(path: PackedVector2Array, color: Color, wash: Color) -> InkLine:
	var line := InkLine.along(path, color, 1.0, true)
	line.fill = wash
	return line


func _scaled(points: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point: Vector2 in points:
		out.append(point * shoe_scale)
	return out
