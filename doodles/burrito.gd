@tool
class_name Burrito
extends InkDrawing
## A doodle: a burrito standing on its end, for free food for life. An orange tortilla rolled round and
## narrowing to its open top, with the edges of its last turns spiralling down it, a crumpled paper wrap
## in ink round its lower half with its torn edge running up on a slant, and the filling peeking up out
## of the top in a row of small bumps. Its origin is the ground under its middle.

## How big the burrito is drawn, as a multiple of its natural size.
@export_range(0.2, 3.0, 0.01) var burrito_scale := 1.0:
	set(value):
		burrito_scale = value
		queue_redraw()
## Palette role of the tortilla and the filling.
@export var role := &"orange":
	set(value):
		role = value
		queue_redraw()
## How strongly the tortilla's wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()
## How strongly the filling's wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var filling_wash := 0.6:
	set(value):
		filling_wash = value
		queue_redraw()
## How far each bump of the filling bulges, as a fraction of its width.
@export_range(0.0, 1.0, 0.01) var bump_bulge := 0.4:
	set(value):
		bump_bulge = value
		queue_redraw()

## The tortilla at natural size, from the left of its open top down round its bottom and up to the
## right of the opening, then back across the far side of the opening.
const _TORTILLA := [Vector2(-50.0, -182.0), Vector2(-60.0, -150.0), Vector2(-66.0, -110.0), Vector2(-66.0, -70.0),
		Vector2(-62.0, -30.0), Vector2(-40.0, -8.0), Vector2(0.0, -4.0), Vector2(40.0, -8.0), Vector2(62.0, -30.0),
		Vector2(66.0, -70.0), Vector2(66.0, -110.0), Vector2(60.0, -150.0), Vector2(50.0, -182.0), Vector2(26.0, -192.0),
		Vector2(0.0, -195.0), Vector2(-26.0, -192.0)]
## The dips between the bumps of the filling, left to right along the far side of the opening. A bump
## bulges up between each pair.
const _FILLING_DIPS := [Vector2(-50.0, -182.0), Vector2(-38.0, -193.0), Vector2(-20.0, -200.0), Vector2(-4.0, -198.0),
		Vector2(14.0, -202.0), Vector2(30.0, -198.0), Vector2(42.0, -192.0), Vector2(50.0, -182.0)]
## The middle the filling's bumps bulge away from.
const _FILLING_MIDDLE := Vector2(0.0, -182.0)
## The near side of the opening, right to left: the filling's bottom edge, and drawn again over it.
const _RIM := [Vector2(50.0, -182.0), Vector2(26.0, -172.0), Vector2(0.0, -169.0), Vector2(-26.0, -172.0),
		Vector2(-50.0, -182.0)]
## The edges of the tortilla's last two turns, spiralling down round the burrito from the opening.
const _TURNS := [[Vector2(22.0, -171.0), Vector2(0.0, -157.0), Vector2(-34.0, -138.0), Vector2(-62.0, -125.0)],
		[Vector2(59.0, -144.0), Vector2(34.0, -128.0), Vector2(0.0, -112.0), Vector2(-30.0, -100.0)]]
## The paper wrap round the lower half, in two pieces: its torn top edge, running up on a slant from
## left to right, then down its right side, round the bottom and up its left side.
const _WRAP_EDGE := [Vector2(-71.0, -82.0), Vector2(-50.0, -92.0), Vector2(-34.0, -88.0), Vector2(-10.0, -102.0),
		Vector2(10.0, -99.0), Vector2(34.0, -112.0), Vector2(50.0, -110.0), Vector2(71.0, -124.0)]
const _WRAP_BODY := [Vector2(71.0, -124.0), Vector2(72.0, -70.0), Vector2(68.0, -28.0), Vector2(52.0, -8.0),
		Vector2(24.0, -1.0), Vector2(-24.0, -1.0), Vector2(-52.0, -8.0), Vector2(-68.0, -28.0), Vector2(-72.0, -60.0),
		Vector2(-71.0, -82.0)]
## Creases in the paper, running down from its torn edge.
const _CREASES := [[Vector2(-34.0, -88.0), Vector2(-40.0, -62.0)], [Vector2(10.0, -99.0), Vector2(2.0, -70.0)],
		[Vector2(50.0, -110.0), Vector2(44.0, -84.0)]]


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var ink := palette.ink
	var lines: Array[InkLine] = []
	lines.append(_washed(InkBrush.resample_smooth(_scaled(_TORTILLA), true, spacing), color,
			palette.paper.lerp(color, wash_strength)))
	var rim := InkBrush.resample_smooth(_scaled(_RIM), false, spacing)
	var filling := _bumps(spacing)
	filling.append_array(rim.slice(1, -1))
	lines.append(_washed(filling, color, palette.paper.lerp(color, filling_wash)))
	lines.append(InkLine.along(rim, color))
	for turn: Array in _TURNS:
		lines.append(InkLine.along(InkBrush.resample_smooth(_scaled(turn), false, spacing), color, 0.8))
	var wrap := InkBrush.resample_polyline(_scaled(_WRAP_EDGE), spacing)
	wrap.append_array(InkBrush.resample_smooth(_scaled(_WRAP_BODY), false, spacing).slice(1, -1))
	lines.append(_washed(wrap, ink, palette.paper))
	for crease: Array in _CREASES:
		lines.append(InkLine.along(InkBrush.resample_polyline(_scaled(crease), spacing), ink, 0.6))
	return lines


## The bumpy top of the filling, left to right: a round bump bulging up between each pair of dips.
func _bumps(spacing: float) -> PackedVector2Array:
	var dips := _scaled(_FILLING_DIPS)
	var middle := _FILLING_MIDDLE * burrito_scale
	var path := PackedVector2Array([dips[0]])
	for i in range(1, dips.size()):
		var from := dips[i - 1]
		var to := dips[i]
		var out := (to - from).orthogonal().normalized()
		if out.dot((from + to) * 0.5 - middle) < 0.0:
			out = -out
		# A cubic curve whose handles stand out by this much peaks at the bump's bulge.
		var handle := out * from.distance_to(to) * bump_bulge * 4.0 / 3.0
		var steps := maxi(2, ceili(from.distance_to(to) * (1.0 + bump_bulge) / spacing))
		for k in range(1, steps + 1):
			path.append(from.bezier_interpolate(from + handle, to + handle, to, float(k) / steps))
	return path


## A closed line along [param path] with [param wash] inside.
static func _washed(path: PackedVector2Array, color: Color, wash: Color) -> InkLine:
	var line := InkLine.along(path, color, 1.0, true)
	line.fill = wash
	return line


func _scaled(points: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point: Vector2 in points:
		out.append(point * burrito_scale)
	return out
