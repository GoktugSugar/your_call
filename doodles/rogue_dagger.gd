@tool
class_name RogueDagger
extends InkDrawing
## A doodle: the rogue. A dagger held at a slant with its point down and to the left: a round pommel, a
## grip wrapped round in slanting turns, a small crossguard and a straight double edged blade with a
## groove down its middle. Its line is green, with a green wash in the hilt and a pale one in the blade,
## and a little ink glint twinkles over the blade near its point. The whole of it is set so it hangs
## centred over its origin, the ground under its middle, with its point just off the ground.

## How big the dagger is drawn, as a multiple of its natural size.
@export_range(0.2, 3.0, 0.01) var dagger_scale := 1.12:
	set(value):
		dagger_scale = value
		queue_redraw()
## How far the dagger leans from pointing straight down, in degrees. Positive swings its point to the left.
@export_range(-90.0, 90.0, 0.5) var tilt := 40.0:
	set(value):
		tilt = value
		queue_redraw()
## Gap between the ground and the dagger's lowest point.
@export_range(0.0, 120.0, 0.5) var lift := 6.0:
	set(value):
		lift = value
		queue_redraw()
## How many turns of wrapping cross the grip.
@export_range(0, 10) var wrap_count := 3:
	set(value):
		wrap_count = value
		queue_redraw()
## Palette role of the dagger's line.
@export var role := &"green":
	set(value):
		role = value
		queue_redraw()
## Palette role of the glint.
@export var glint_role := &"ink":
	set(value):
		glint_role = value
		queue_redraw()
## How strongly the hilt's wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()
## How strongly the blade's wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var blade_wash := 0.15:
	set(value):
		blade_wash = value
		queue_redraw()

## The blade at natural size, from its left shoulder under the crossguard across, down to its point and
## back up. The dagger's shapes are drawn hanging straight down from the pommel at the top, with x across
## it and y running down it, and leant by [member tilt] after.
const _BLADE := [Vector2(-17.0, 74.0), Vector2(17.0, 74.0), Vector2(13.0, 182.0), Vector2(0.0, 236.0),
		Vector2(-13.0, 182.0)]
## The groove down the middle of the blade.
const _FULLER := [Vector2(0.0, 90.0), Vector2(0.0, 174.0)]
## The grip and the crossguard under it, and the radius of each one's rounded corners.
const _GRIP := Rect2(-10.0, 14.0, 20.0, 50.0)
const _GRIP_CORNER := 6.0
const _GUARD := Rect2(-37.0, 62.0, 74.0, 15.0)
const _GUARD_CORNER := 7.0
## The middle of the pommel and its radius.
const _POMMEL := Vector2(0.0, 8.0)
const _POMMEL_RADIUS := 11.0
## How far in from the grip's ends the wrapping starts and stops, and how far each turn climbs as it
## crosses the grip.
const _WRAP_INSET := 5.0
const _WRAP_SLANT := 10.0
## Where the glint sits beside the blade, near its point. The glint stays upright however the dagger
## leans: four rays out from its middle, the upright pair longer, each starting a little way out.
const _GLINT := Vector2(-36.0, 160.0)
const _GLINT_RAYS := Vector2(13.0, 9.0)
const _GLINT_GAP := 3.0
## Widths of the blade's groove, the wrapping and the glint, as multiples of the drawing's line width.
const _FULLER_LINE := 0.6
const _WRAP_LINE := 0.7
const _GLINT_LINE := 0.6


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var wash := palette.paper.lerp(color, wash_strength)
	var lines: Array[InkLine] = []
	# The pommel goes under the grip's top, and the crossguard over the grip's foot and the blade's top.
	lines.append(_washed(InkBrush.resample_polyline(_closed(_scaled(_BLADE)), spacing), color,
			palette.paper.lerp(color, blade_wash)))
	lines.append(InkLine.along(InkBrush.resample_polyline(_scaled(_FULLER), spacing), color, _FULLER_LINE))
	var pommel := InkBrush.ellipse(_POMMEL * dagger_scale, Vector2.ONE * _POMMEL_RADIUS * dagger_scale, spacing, -PI * 0.5)
	lines.append(_washed(pommel, color, wash))
	var grip := _scaled_rect(_GRIP)
	lines.append(_washed(InkBrush.rounded_rect(grip, _GRIP_CORNER * dagger_scale, spacing), color, wash))
	var inset := _WRAP_INSET * dagger_scale
	var slant := _WRAP_SLANT * dagger_scale
	for turn in wrap_count:
		var y := lerpf(grip.position.y + inset + slant, grip.end.y - inset, (turn + 0.5) / wrap_count)
		var wrap := PackedVector2Array([Vector2(grip.position.x, y), Vector2(grip.end.x, y - slant)])
		lines.append(InkLine.along(InkBrush.resample_polyline(wrap, spacing), color, _WRAP_LINE))
	lines.append(_washed(InkBrush.rounded_rect(_scaled_rect(_GUARD), _GUARD_CORNER * dagger_scale, spacing), color, wash))
	var lean := Transform2D(deg_to_rad(tilt), Vector2.ZERO)
	for line in lines:
		line.path = lean * line.path
	var glint := lean * (_GLINT * dagger_scale)
	var glint_color := palette.color(glint_role)
	for way: Vector2 in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
		var reach := _GLINT_RAYS.x if way.x == 0.0 else _GLINT_RAYS.y
		var stroke := PackedVector2Array([glint + way * _GLINT_GAP * dagger_scale, glint + way * reach * dagger_scale])
		lines.append(InkLine.along(InkBrush.resample_polyline(stroke, spacing * 0.5), glint_color, _GLINT_LINE))
	# Set the whole of it centred over the origin, its lowest point lifted off the ground.
	var box := Rect2(lines[0].path[0], Vector2.ZERO)
	for line in lines:
		for point in line.path:
			box = box.expand(point)
	var place := Transform2D(0.0, Vector2(-box.get_center().x, -lift - box.end.y))
	for line in lines:
		line.path = place * line.path
	return lines


func _scaled(points: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point: Vector2 in points:
		out.append(point * dagger_scale)
	return out


func _scaled_rect(rect: Rect2) -> Rect2:
	return Rect2(rect.position * dagger_scale, rect.size * dagger_scale)


## A closed line along [param path] with [param wash] inside it.
static func _washed(path: PackedVector2Array, color: Color, wash: Color) -> InkLine:
	var line := InkLine.along(path, color, 1.0, true)
	line.fill = wash
	return line


## [param corners] with the first repeated at the end, to draw them as a closed polyline.
static func _closed(corners: PackedVector2Array) -> PackedVector2Array:
	var out := corners.duplicate()
	out.append(corners[0])
	return out
