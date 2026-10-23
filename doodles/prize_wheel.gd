@tool
class_name PrizeWheel
extends InkDrawing
## A doodle: the prize wheel. A game show wheel on a short stand, its face split into wedges that take
## turns between a gold wash (double) and plain paper (nothing), with a peg on its rim at the end of each
## line between them and a small hub in the middle. A pointer fixed over its top shows the wedge it has
## stopped on. Turning the wheel turns its face, its pegs and its hub, never the pointer or the stand.
## With no turn, wedge 0 sits under the pointer and the others follow it round clockwise, the even ones
## gold. Its line is ink. Its origin is the ground under its middle.

## How many wedges the face is split into.
@export_range(2, 24) var segments := 8:
	set(value):
		segments = value
		queue_redraw()
## How far the wheel has turned clockwise, in degrees.
@export_range(-3600.0, 3600.0, 0.1, "or_less", "or_greater") var turn := 0.0:
	set(value):
		turn = value
		queue_redraw()
## How big the wheel is drawn, as a multiple of its natural size.
@export_range(0.2, 3.0, 0.01) var wheel_scale := 1.0:
	set(value):
		wheel_scale = value
		queue_redraw()
## Radius of each peg on the rim, at natural size. Zero leaves the pegs off.
@export_range(0.0, 10.0, 0.1) var peg_radius := 3.6:
	set(value):
		peg_radius = value
		queue_redraw()

@export_group("Colour")
## Palette role of every line.
@export var role := &"ink":
	set(value):
		role = value
		queue_redraw()
## Palette role of the gold wedges.
@export var wedge_role := &"gold":
	set(value):
		wedge_role = value
		queue_redraw()
## Palette roles the other wedges, the nothings, take in turn. Empty leaves them plain paper.
@export var other_roles: Array[StringName] = []:
	set(value):
		other_roles = value
		queue_redraw()
## Palette role of the pointer.
@export var pointer_role := &"amber":
	set(value):
		pointer_role = value
		queue_redraw()
## Palette role of the stand and the hub.
@export var stand_role := &"secondary":
	set(value):
		stand_role = value
		queue_redraw()
## How strongly the wedges', the pointer's, the stand's and the hub's washes take their colours over
## the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.5:
	set(value):
		wash_strength = value
		queue_redraw()

## The wheel at natural size: how high its middle stands over the ground, its radius and its hub's
## radius, the radius of the axle's dot in the middle of the hub, and how far out from the rim's line
## the pegs stand.
const _AXLE := 116.0
const _RADIUS := 80.0
const _HUB_RADIUS := 13.0
const _AXLE_DOT := 3.0
const _PEG_OUT := 3.0
## The pointer at natural size, from the top of the rim: its top corners and its tip, which reaches down
## over the rim.
const _POINTER := [Vector2(-13.0, -24.0), Vector2(13.0, -24.0), Vector2(0.0, 10.0)]
## The stand at natural size: where the right leg comes down onto the bar along the ground (the left
## mirrors it), how wide the legs are, and the bar, with the radius of its rounded corners. The legs
## start from the wheel's middle, behind it.
const _FOOT := Vector2(46.0, -5.0)
const _LEG_WIDTH := 11.0
const _BAR := Rect2(-62.0, -10.0, 124.0, 10.0)
const _BAR_CORNER := 4.0
## Width of the lines between the wedges, as a multiple of the drawing's line width.
const _SPOKE_LINE := 0.8


## The turn, in degrees from 0 up to a whole turn, at which wedge [param segment] sits under the
## pointer. [param offset] lands the pointer off the wedge's middle, as a share of the wedge's width
## between -0.5 and 0.5. For a spin that ends there, add whole turns of 360.
func turn_to_show(segment: int, offset := 0.0) -> float:
	return fposmod(-(segment + offset) * 360.0 / segments, 360.0)


## The wedge under the pointer at the wheel's turn now.
func segment_under_pointer() -> int:
	return posmod(roundi(-turn * segments / 360.0), segments)


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var stand_wash := palette.paper.lerp(palette.color(stand_role), wash_strength)
	var middle := Vector2(0.0, -_AXLE * wheel_scale)
	var radius := _RADIUS * wheel_scale
	var hub := _HUB_RADIUS * wheel_scale
	var wedge := TAU / segments
	var turned := deg_to_rad(turn)
	var lines: Array[InkLine] = []
	# Back to front: the stand, whose top the wheel hides; the face, paper with the gold wedges washed
	# over it and no line of its own; the lines between the wedges, then the rim over their ends; the
	# pegs and the hub; and the pointer over it all.
	for side: float in [-1.0, 1.0]:
		var foot := Vector2(_FOOT.x * side, _FOOT.y) * wheel_scale
		lines.append(_washed(_strip(middle, foot, _LEG_WIDTH * wheel_scale, spacing), color, stand_wash))
	lines.append(_washed(InkBrush.rounded_rect(_scaled_rect(_BAR), _BAR_CORNER * wheel_scale, spacing), color, stand_wash))
	lines.append(_washed(InkBrush.ellipse(middle, Vector2.ONE * radius, spacing), Color.TRANSPARENT, palette.paper))
	var gold := palette.paper.lerp(palette.color(wedge_role), wash_strength)
	for k in range(0, segments, 2):
		var face := _wedge(middle, radius, _edge_angle(k, wedge, turned), wedge, spacing)
		lines.append(_washed(face, Color.TRANSPARENT, gold))
	if not other_roles.is_empty():
		for k in range(1, segments, 2):
			var other := palette.paper.lerp(palette.color(other_roles[floori(k / 2.0) % other_roles.size()]), wash_strength)
			lines.append(_washed(_wedge(middle, radius, _edge_angle(k, wedge, turned), wedge, spacing), Color.TRANSPARENT, other))
	for k in segments:
		var out := Vector2.from_angle(_edge_angle(k, wedge, turned))
		var spoke := PackedVector2Array([middle + out * hub, middle + out * radius])
		lines.append(InkLine.along(InkBrush.resample_polyline(spoke, spacing), color, _SPOKE_LINE))
	lines.append(InkLine.along(InkBrush.ellipse(middle, Vector2.ONE * radius, spacing, turned), color, 1.0, true))
	if peg_radius > 0.0:
		for k in segments:
			var peg := middle + Vector2.from_angle(_edge_angle(k, wedge, turned)) * (radius + _PEG_OUT * wheel_scale)
			lines.append(InkLine.dot(peg, peg_radius * wheel_scale, color))
	lines.append(_washed(InkBrush.ellipse(middle, Vector2.ONE * hub, spacing, turned), color, stand_wash))
	lines.append(InkLine.dot(middle, _AXLE_DOT * wheel_scale, color))
	var top := middle + Vector2(0.0, -radius)
	var pointer := PackedVector2Array()
	for point: Vector2 in _POINTER:
		pointer.append(top + point * wheel_scale)
	pointer.append(pointer[0])
	var pointer_wash := palette.paper.lerp(palette.color(pointer_role), wash_strength)
	lines.append(_washed(InkBrush.resample_polyline(pointer, spacing), color, pointer_wash))
	return lines


## The angle, in radians, of the line between wedge [param k] and the one before it, each wedge
## [param wedge] radians wide, on a wheel turned [param turned] radians: wedge 0 is centred straight up
## at no turn.
static func _edge_angle(k: int, wedge: float, turned: float) -> float:
	return -PI * 0.5 + (k - 0.5) * wedge + turned


## A wedge of the circle round [param middle] with [param radius]: out from the middle along the angle
## [param from] (radians), round [param sweep] radians of the rim, and back in.
static func _wedge(middle: Vector2, radius: float, from: float, sweep: float, spacing: float) -> PackedVector2Array:
	var steps := maxi(2, ceili(radius * sweep / spacing))
	var out := PackedVector2Array([middle])
	for i in steps + 1:
		out.append(middle + Vector2.from_angle(from + sweep * i / steps) * radius)
	return out


## A closed outline [param width] wide round the straight line from [param from] to [param to], square
## across both ends.
static func _strip(from: Vector2, to: Vector2, width: float, spacing: float) -> PackedVector2Array:
	var across := (to - from).normalized().orthogonal() * width * 0.5
	var corners := PackedVector2Array([from + across, to + across, to - across, from - across, from + across])
	return InkBrush.resample_polyline(corners, spacing)


func _scaled_rect(rect: Rect2) -> Rect2:
	return Rect2(rect.position * wheel_scale, rect.size * wheel_scale)


## A closed line along [param path] with [param wash] inside it. A transparent [param color] leaves the
## wash with no line of its own.
static func _washed(path: PackedVector2Array, color: Color, wash: Color) -> InkLine:
	var line := InkLine.along(path, color, 1.0, true)
	line.fill = wash
	return line
