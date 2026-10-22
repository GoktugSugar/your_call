@tool
class_name BardLute
extends InkDrawing
## A doodle: the bard. A lute leant back at a slant with its neck up to the right: a round pear shaped
## body with a dark sound hole and a small bridge, a neck running up from it, and at its end the pegbox
## bent sharply back, with three round pegs knobbing out of its bend. Three strings run from the bridge over the
## sound hole and up the neck. Its line is orange, with an orange wash in the body and a stronger one in
## the neck and the pegbox. The whole of it is set so it sits centred over its origin, the ground under
## its middle.

## How big the lute is drawn, as a multiple of its natural size.
@export_range(0.2, 3.0, 0.01) var lute_scale := 1.0:
	set(value):
		lute_scale = value
		queue_redraw()
## How far the lute leans back from standing upright, in degrees. Positive tips its neck to the right.
@export_range(-90.0, 90.0, 0.5) var tilt := 30.0:
	set(value):
		tilt = value
		queue_redraw()
## Gap between the ground and the lute's lowest point.
@export_range(0.0, 120.0, 0.5) var lift := 0.0:
	set(value):
		lift = value
		queue_redraw()
## How many strings run up the lute.
@export_range(0, 8) var string_count := 3:
	set(value):
		string_count = value
		queue_redraw()
## Palette role of the lute's line.
@export var role := &"orange":
	set(value):
		role = value
		queue_redraw()
## How strongly the body's wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()
## How strongly the neck's and the pegbox's wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var neck_wash := 0.65:
	set(value):
		neck_wash = value
		queue_redraw()
## How dark the sound hole is, as a share of the way from the paper to the ink.
@export_range(0.0, 1.0, 0.01) var hole_darkness := 0.7:
	set(value):
		hole_darkness = value
		queue_redraw()

## The body at natural size, round from the bottom of its bowl, where the strings end, up its right side
## to where the neck joins it and back down its left. The lute's shapes are drawn standing upright with
## the bottom of the body on the origin, and leant by [member tilt] after.
const _BODY := [Vector2(0.0, 0.0), Vector2(30.0, -6.0), Vector2(48.0, -24.0), Vector2(54.0, -52.0),
		Vector2(48.0, -84.0), Vector2(34.0, -110.0), Vector2(16.0, -132.0), Vector2(0.0, -137.0),
		Vector2(-16.0, -132.0), Vector2(-34.0, -110.0), Vector2(-48.0, -84.0), Vector2(-54.0, -52.0),
		Vector2(-48.0, -24.0), Vector2(-30.0, -6.0)]
## The middle of the sound hole and its radius.
const _HOLE := Vector2(0.0, -82.0)
const _HOLE_RADIUS := 16.0
## The bridge the strings are tied to, and the radius of its rounded corners.
const _BRIDGE := Rect2(-20.0, -34.0, 40.0, 9.0)
const _BRIDGE_CORNER := 4.0
## The neck, from where it overlaps the body up to the nut, and the radius of its rounded corners.
const _NECK := Rect2(-13.0, -204.0, 26.0, 86.0)
const _NECK_CORNER := 5.0
## Where the pegbox bends back from the top of the neck, the way it runs, in degrees clockwise from
## straight up, its length, and its width at the neck and at its end.
const _PEGBOX_ROOT := Vector2(0.0, -198.0)
const _PEGBOX_TURN := 100.0
const _PEGBOX_LENGTH := 50.0
const _PEGBOX_WIDTHS := Vector2(22.0, 14.0)
## How many pegs stand out of the outside of the pegbox's bend, each a short stem out to a round knob:
## how far the knob's middle stands off the pegbox's edge, and its radius.
const _PEGS := 3
const _PEG_REACH := 9.0
const _PEG_RADIUS := 4.5
## Where the strings run: their spread at the bridge and at the nut, from the outermost to the outermost.
const _STRING_FROM := -29.0
const _STRING_TO := -200.0
const _STRING_SPREADS := Vector2(22.0, 14.0)
## Widths of the strings and the pegs, as multiples of the drawing's line width.
const _STRING_LINE := 0.45
const _PEG_LINE := 0.7


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var wash := palette.paper.lerp(color, wash_strength)
	var dark_wash := palette.paper.lerp(color, neck_wash)
	var lines: Array[InkLine] = []
	# The pegs stand behind the pegbox, the pegbox behind the top of the neck, and the neck over the
	# top of the body.
	var root := _PEGBOX_ROOT * lute_scale
	var way := Vector2.UP.rotated(deg_to_rad(_PEGBOX_TURN))
	var across := way.orthogonal()
	var length := _PEGBOX_LENGTH * lute_scale
	var widths := _PEGBOX_WIDTHS * lute_scale * 0.5
	for peg in _PEGS:
		var share := (peg + 1.0) / (_PEGS + 1.0)
		var at := root + way * length * share
		var tip := at + across * (lerpf(widths.x, widths.y, share) + _PEG_REACH * lute_scale)
		lines.append(InkLine.along(InkBrush.resample_polyline(PackedVector2Array([at, tip]), spacing * 0.5), color, _PEG_LINE))
		var knob := InkBrush.ellipse(tip, Vector2.ONE * _PEG_RADIUS * lute_scale, spacing * 0.5, -PI * 0.5)
		lines.append(_washed(knob, color, dark_wash, _PEG_LINE))
	var pegbox := PackedVector2Array([root + across * widths.x, root + way * length + across * widths.y,
			root + way * length - across * widths.y, root - across * widths.x, root + across * widths.x])
	lines.append(_washed(InkBrush.resample_polyline(pegbox, spacing), color, dark_wash))
	lines.append(_washed(InkBrush.resample_smooth(_scaled(_BODY), true, spacing), color, wash))
	var hole := InkBrush.ellipse(_HOLE * lute_scale, Vector2.ONE * _HOLE_RADIUS * lute_scale, spacing, -PI * 0.5)
	lines.append(_washed(hole, color, palette.paper.lerp(palette.ink, hole_darkness)))
	lines.append(_washed(InkBrush.rounded_rect(_scaled_rect(_BRIDGE), _BRIDGE_CORNER * lute_scale, spacing), color, dark_wash))
	lines.append(_washed(InkBrush.rounded_rect(_scaled_rect(_NECK), _NECK_CORNER * lute_scale, spacing), color, dark_wash))
	for strand in string_count:
		var share := 0.0 if string_count == 1 else float(strand) / (string_count - 1) - 0.5
		var run := PackedVector2Array([Vector2(_STRING_SPREADS.x * share, _STRING_FROM),
				Vector2(_STRING_SPREADS.y * share, _STRING_TO)])
		lines.append(InkLine.along(InkBrush.resample_polyline(_scaled(run), spacing), color, _STRING_LINE))
	# Lean it back, then set the whole of it centred over the origin on the ground.
	var lean := Transform2D(deg_to_rad(tilt), Vector2.ZERO)
	var box := Rect2(lean * lines[0].path[0], Vector2.ZERO)
	for line in lines:
		line.path = lean * line.path
		for point in line.path:
			box = box.expand(point)
	var place := Transform2D(0.0, Vector2(-box.get_center().x, -lift - box.end.y))
	for line in lines:
		line.path = place * line.path
	return lines


func _scaled(points: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point: Vector2 in points:
		out.append(point * lute_scale)
	return out


func _scaled_rect(rect: Rect2) -> Rect2:
	return Rect2(rect.position * lute_scale, rect.size * lute_scale)


## A closed line along [param path] with [param wash] inside it, [param width] times the drawing's
## line width.
static func _washed(path: PackedVector2Array, color: Color, wash: Color, width := 1.0) -> InkLine:
	var line := InkLine.along(path, color, width, true)
	line.fill = wash
	return line
