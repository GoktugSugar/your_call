@tool
class_name KnightShield
extends InkDrawing
## A doodle: the knight. A heraldic shield stands in front of a sword planted point down, so the sword's
## grip, crossguard and round pommel rise over the shield's top edge and its point shows under the
## shield's own point. The shield is a heater with a band of rim round its edge and a chevron across its
## pale field, the device that makes it heraldry. All of it is steel blue: the hilt and the rim in a blue
## wash, the chevron in a stronger one, the field and the sword's blade in a pale one. Its origin is the
## ground under the sword's point.

## How big the shield and sword are drawn, as a multiple of their natural size.
@export_range(0.2, 3.0, 0.01) var shield_scale := 1.0:
	set(value):
		shield_scale = value
		queue_redraw()
## Palette role of every line.
@export var role := &"blue":
	set(value):
		role = value
		queue_redraw()
## How strongly the sword's hilt and the shield's rim take the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()
## How strongly the shield's field takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var field_wash := 0.12:
	set(value):
		field_wash = value
		queue_redraw()
## How strongly the chevron takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var device_wash := 0.6:
	set(value):
		device_wash = value
		queue_redraw()
## How strongly the sword's blade takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var blade_wash := 0.15:
	set(value):
		blade_wash = value
		queue_redraw()
## How far in from the shield's edge the rim's inner line runs, at natural size.
@export_range(0.0, 40.0, 0.5) var rim_width := 11.0:
	set(value):
		rim_width = value
		queue_redraw()

## The shield at natural size, in smooth runs that meet in its three corners: along its top edge from
## the left corner to the right, down its right side to its point, and back up its left side.
const _SHIELD := [
	[Vector2(-78.0, -166.0), Vector2(78.0, -166.0)],
	[Vector2(78.0, -166.0), Vector2(78.0, -128.0), Vector2(71.0, -88.0), Vector2(48.0, -55.0), Vector2(0.0, -30.0)],
	[Vector2(0.0, -30.0), Vector2(-48.0, -55.0), Vector2(-71.0, -88.0), Vector2(-78.0, -128.0), Vector2(-78.0, -166.0)],
]
## The chevron: the height of the peak of its upper edge, how far its arms fall for every pixel they run
## out from the middle, and how deep its band is, from the upper edge down to the lower one.
const _CHEVRON_PEAK := -128.0
const _CHEVRON_FALL := 0.62
const _CHEVRON_DEPTH := 28.0
## How far out either side the chevron runs before the rim cuts it off: past the widest the shield gets.
const _CHEVRON_REACH := 200.0
## The sword's blade, from its left shoulder under the crossguard across, down to its point on the
## ground and back up.
const _BLADE := [Vector2(-11.0, -177.0), Vector2(11.0, -177.0), Vector2(11.0, -30.0), Vector2(0.0, -2.0),
		Vector2(-11.0, -30.0)]
## The crossguard and the grip above it, and the radius of each one's rounded corners.
const _GUARD := Rect2(-44.0, -189.0, 88.0, 13.0)
const _GUARD_CORNER := 6.0
const _GRIP := Rect2(-8.0, -212.0, 16.0, 25.0)
const _GRIP_CORNER := 4.0
## The middle of the round pommel on top of the grip, and its radius.
const _POMMEL := Vector2(0.0, -218.0)
const _POMMEL_RADIUS := 8.5
## Width of the rim's inner line and of the chevron's edges, as multiples of the drawing's line width.
const _RIM_LINE := 0.7
const _EDGE_LINE := 0.8


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var wash := palette.paper.lerp(color, wash_strength)
	var lines: Array[InkLine] = []
	# The sword stands behind the shield, which hides most of its blade. The grip hides the foot of the
	# pommel, and the crossguard the foot of the grip.
	lines.append(_washed(InkBrush.resample_polyline(_closed(_scaled(_BLADE)), spacing), color,
			palette.paper.lerp(color, blade_wash)))
	var pommel := InkBrush.ellipse(_POMMEL * shield_scale, Vector2.ONE * _POMMEL_RADIUS * shield_scale, spacing, -PI * 0.5)
	lines.append(_washed(pommel, color, wash))
	lines.append(_washed(InkBrush.rounded_rect(_scaled_rect(_GRIP), _GRIP_CORNER * shield_scale, spacing), color, wash))
	lines.append(_washed(InkBrush.rounded_rect(_scaled_rect(_GUARD), _GUARD_CORNER * shield_scale, spacing), color, wash))
	var shield := _runs(_SHIELD, spacing)
	lines.append(_washed(shield, color, wash))
	var field := _inset(shield, rim_width * shield_scale, spacing)
	if field.size() < 4:
		return lines
	# The field and the chevron are washes with no line of their own: the chevron's two edges and the
	# rim's inner line, drawn over them, draw their edges.
	lines.append(_wash_only(field, palette.paper.lerp(color, field_wash)))
	var inside := field.slice(0, -1)
	var upper := _chevron_edge(0.0)
	var lower := _chevron_edge(_CHEVRON_DEPTH)
	var band := lower.duplicate()
	band.reverse()
	band = upper + band
	for part: PackedVector2Array in Geometry2D.intersect_polygons(inside, band):
		lines.append(_wash_only(part, palette.paper.lerp(color, device_wash)))
	for edge: PackedVector2Array in [upper, lower]:
		for part: PackedVector2Array in Geometry2D.intersect_polyline_with_polygon(edge, inside):
			lines.append(InkLine.along(InkBrush.resample_polyline(part, spacing), color, _EDGE_LINE))
	lines.append(InkLine.along(field, color, _RIM_LINE, true))
	return lines


## One edge of the chevron, [param depth] under its upper edge, from far out on the left up to its peak
## and down far out on the right.
func _chevron_edge(depth: float) -> PackedVector2Array:
	var peak := Vector2(0.0, _CHEVRON_PEAK + depth) * shield_scale
	var reach := Vector2(_CHEVRON_REACH, _CHEVRON_REACH * _CHEVRON_FALL) * shield_scale
	return PackedVector2Array([peak + Vector2(-reach.x, reach.y), peak, peak + reach])


## The closed outline through [param runs] at natural size: smooth runs that meet in sharp corners,
## each starting where the one before it ends.
func _runs(runs: Array, spacing: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for run: Array in runs:
		var part := InkBrush.resample_smooth(_scaled(run), false, spacing)
		out.append_array(part if out.is_empty() else part.slice(1))
	return out


func _scaled(points: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point: Vector2 in points:
		out.append(point * shield_scale)
	return out


func _scaled_rect(rect: Rect2) -> Rect2:
	return Rect2(rect.position * shield_scale, rect.size * shield_scale)


## The closed [param outline] pulled in [param inset] all round, keeping its corners sharp, as points
## about [param spacing] apart ending back on the first. Empty when the outline is too small to pull in
## that far.
static func _inset(outline: PackedVector2Array, inset: float, spacing: float) -> PackedVector2Array:
	var polygon := outline
	if polygon.size() > 1 and polygon[0].is_equal_approx(polygon[polygon.size() - 1]):
		polygon = polygon.slice(0, -1)
	var shrunk := Geometry2D.offset_polygon(polygon, -inset, Geometry2D.JOIN_MITER)
	if shrunk.is_empty():
		return PackedVector2Array()
	var loop: PackedVector2Array = shrunk[0]
	return InkBrush.resample_polyline(_closed(loop), spacing)


## A closed line along [param path] with [param wash] inside it.
static func _washed(path: PackedVector2Array, color: Color, wash: Color) -> InkLine:
	var line := InkLine.along(path, color, 1.0, true)
	line.fill = wash
	return line


## A wash inside the closed [param path] with no line of its own.
static func _wash_only(path: PackedVector2Array, wash: Color) -> InkLine:
	var line := InkLine.along(path, Color.TRANSPARENT, 1.0, true)
	line.fill = wash
	return line


## [param corners] with the first repeated at the end, to draw them as a closed polyline.
static func _closed(corners: PackedVector2Array) -> PackedVector2Array:
	var out := corners.duplicate()
	out.append(corners[0])
	return out
