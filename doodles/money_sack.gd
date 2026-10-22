@tool
class_name MoneySack
extends InkDrawing
## A doodle: one enormous win, once. A fat gold money sack sits on the ground, cinched at the neck by
## a tie whose two ends hang loose, with the cloth above the tie flaring out in three points. A dollar
## sign is drawn on its belly in strokes. A gold wash fills the cloth. Its origin is the ground under
## its middle.

## How big the sack is drawn, as a multiple of its natural size.
@export_range(0.2, 3.0, 0.01) var sack_scale := 1.0:
	set(value):
		sack_scale = value
		queue_redraw()
## Palette role of the line.
@export var line_role := &"gold":
	set(value):
		line_role = value
		queue_redraw()
## How strongly each wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()
## Width of the dollar sign's strokes, as a multiple of the drawing's line width.
@export_range(0.2, 3.0, 0.05) var sign_width := 1.2:
	set(value):
		sign_width = value
		queue_redraw()

## The sack's belly at natural size, from the left of its neck down round its bottom and up to the
## right of its neck. The tie hides its top.
const _BELLY := [Vector2(-22.0, -146.0), Vector2(-50.0, -126.0), Vector2(-80.0, -88.0), Vector2(-86.0, -50.0),
		Vector2(-74.0, -14.0), Vector2(-40.0, 0.0), Vector2(40.0, 0.0), Vector2(74.0, -14.0), Vector2(86.0, -50.0),
		Vector2(80.0, -88.0), Vector2(50.0, -126.0), Vector2(22.0, -146.0), Vector2(0.0, -150.0)]
## The cloth above the tie, in smooth runs that meet in its three sharp points: from the left of the
## tie out to the left point, dipping to the middle point and the right one, and back down to the tie.
const _FLARE := [
	[Vector2(22.0, -152.0), Vector2(-4.0, -150.0), Vector2(-24.0, -154.0)],
	[Vector2(-24.0, -154.0), Vector2(-36.0, -170.0), Vector2(-54.0, -190.0)],
	[Vector2(-54.0, -190.0), Vector2(-30.0, -184.0), Vector2(-4.0, -206.0)],
	[Vector2(-4.0, -206.0), Vector2(14.0, -186.0), Vector2(48.0, -194.0)],
	[Vector2(48.0, -194.0), Vector2(34.0, -172.0), Vector2(22.0, -152.0)],
]
## The tie round the neck: a narrow band, from its left end along the top and back along the bottom.
const _TIE := [Vector2(-28.0, -160.0), Vector2(0.0, -156.0), Vector2(28.0, -160.0), Vector2(30.0, -147.0),
		Vector2(0.0, -142.0), Vector2(-30.0, -147.0)]
## The tie's two loose ends, hanging from its knot on the right.
const _TIE_ENDS := [[Vector2(18.0, -146.0), Vector2(30.0, -132.0), Vector2(28.0, -114.0)],
		[Vector2(22.0, -146.0), Vector2(40.0, -136.0), Vector2(46.0, -120.0)]]
## The dollar sign's S, from its top right end round to its bottom left end.
const _SIGN_S := [Vector2(18.0, -94.0), Vector2(4.0, -100.0), Vector2(-14.0, -96.0), Vector2(-18.0, -84.0),
		Vector2(-6.0, -75.0), Vector2(10.0, -68.0), Vector2(18.0, -57.0), Vector2(12.0, -45.0), Vector2(-6.0, -42.0),
		Vector2(-20.0, -48.0)]
## The dollar sign's bar, top to bottom.
const _SIGN_BAR := [Vector2(0.0, -110.0), Vector2(0.0, -32.0)]


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(line_role)
	var wash := palette.paper.lerp(color, wash_strength)
	var lines: Array[InkLine] = []
	lines.append(_washed(InkBrush.resample_smooth(_scaled(_BELLY), true, spacing), color, wash))
	var flare := PackedVector2Array()
	for run: Array in _FLARE:
		var part := InkBrush.resample_smooth(_scaled(run), false, spacing)
		flare.append_array(part if flare.is_empty() else part.slice(1))
	lines.append(_washed(flare, color, wash))
	for end: Array in _TIE_ENDS:
		lines.append(InkLine.along(InkBrush.resample_smooth(_scaled(end), false, spacing), color, 0.8))
	lines.append(_washed(InkBrush.resample_smooth(_scaled(_TIE), true, spacing), color, wash))
	lines.append(InkLine.along(InkBrush.resample_smooth(_scaled(_SIGN_S), false, spacing), color, sign_width))
	lines.append(InkLine.along(InkBrush.resample_polyline(_scaled(_SIGN_BAR), spacing), color, sign_width))
	return lines


## A closed line along [param path] with [param wash] inside it.
static func _washed(path: PackedVector2Array, color: Color, wash: Color) -> InkLine:
	var line := InkLine.along(path, color, 1.0, true)
	line.fill = wash
	return line


func _scaled(points: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point: Vector2 in points:
		out.append(point * sack_scale)
	return out
