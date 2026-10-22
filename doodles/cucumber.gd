@tool
class_name Cucumber
extends InkDrawing
## A doodle: a cucumber that costs one hundred dollars. A long, slightly curved green cucumber lying
## at a slight tilt, with a green wash inside, a few small bumps dotted along its skin and a stub of
## stalk at its right end. Its origin is the ground under its middle.

## How big the cucumber is drawn, as a multiple of its natural size.
@export_range(0.2, 3.0, 0.01) var cucumber_scale := 1.1:
	set(value):
		cucumber_scale = value
		queue_redraw()
## Tilt of the cucumber, in degrees. Negative raises its right end.
@export_range(-90.0, 90.0, 0.5) var tilt := -20.0:
	set(value):
		tilt = value
		queue_redraw()
## How high its middle sits, from the ground.
@export_range(0.0, 240.0, 0.5) var middle_height := 80.0:
	set(value):
		middle_height = value
		queue_redraw()
## Radius of each bump on its skin.
@export_range(0.5, 10.0, 0.1) var bump_radius := 3.4:
	set(value):
		bump_radius = value
		queue_redraw()
## Palette role of every line.
@export var role := &"green":
	set(value):
		role = value
		queue_redraw()
## How strongly the wash inside takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()

## The cucumber's outline at natural size and untilted, lying along its middle: from its round left
## end along its top to the stalk end, and back along its underside.
const _OUTLINE := [Vector2(-167.0, 2.0), Vector2(-157.0, -26.0), Vector2(-117.0, -45.0), Vector2(-57.0, -56.0),
		Vector2(3.0, -58.0), Vector2(63.0, -52.0), Vector2(113.0, -39.0), Vector2(143.0, -22.0),
		Vector2(151.0, -2.0), Vector2(143.0, 18.0), Vector2(113.0, 31.0), Vector2(63.0, 35.0),
		Vector2(3.0, 33.0), Vector2(-57.0, 29.0), Vector2(-117.0, 22.0), Vector2(-155.0, 18.0)]
## The stub of stalk at the right end, untilted, its root tucked behind the cucumber.
const _STALK := Rect2(137.0, -11.0, 32.0, 18.0)
## Radius of the stalk's rounded corners.
const _STALK_CORNER := 6.0
## The bumps on its skin, untilted.
const _BUMPS := [Vector2(-125.0, -14.0), Vector2(-89.0, 8.0), Vector2(-51.0, -32.0), Vector2(-19.0, 4.0),
		Vector2(19.0, -30.0), Vector2(55.0, 12.0), Vector2(93.0, -18.0), Vector2(-9.0, -42.0)]


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var wash := palette.paper.lerp(color, wash_strength)
	var lines: Array[InkLine] = []
	var stalk := Rect2(_STALK.position * cucumber_scale, _STALK.size * cucumber_scale)
	lines.append(_washed(_placed(InkBrush.rounded_rect(stalk, _STALK_CORNER * cucumber_scale, spacing)), color, wash))
	var outline := PackedVector2Array()
	for point: Vector2 in _OUTLINE:
		outline.append(point * cucumber_scale)
	lines.append(_washed(_placed(InkBrush.resample_smooth(outline, true, spacing)), color, wash))
	for bump: Vector2 in _BUMPS:
		lines.append(InkLine.dot(_place(bump * cucumber_scale), bump_radius, color))
	return lines


## [param point] of the untilted cucumber, tilted and lifted so its middle sits over the origin.
func _place(point: Vector2) -> Vector2:
	return point.rotated(deg_to_rad(tilt)) + Vector2(0.0, -middle_height)


func _placed(points: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point in points:
		out.append(_place(point))
	return out


## A closed line along [param path] with [param wash] inside.
static func _washed(path: PackedVector2Array, color: Color, wash: Color) -> InkLine:
	var line := InkLine.along(path, color, 1.0, true)
	line.fill = wash
	return line
