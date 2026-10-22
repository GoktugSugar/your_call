@tool
class_name WalkingHouse
extends InkDrawing
## A doodle: a house that gets up and walks off whenever it likes a different street. A little orange
## house, its walls with a faint wash, a pitched roof, a chimney and a door with a stronger one, and one
## window with a cross, up on two ink stick legs mid stride to the right, leaning a little into the walk.
## Its origin is the ground under its middle.

## How big the house is drawn, as a multiple of its natural size.
@export_range(0.2, 3.0, 0.01) var house_scale := 1.1:
	set(value):
		house_scale = value
		queue_redraw()
## Palette role of the house's line.
@export var role := &"orange":
	set(value):
		role = value
		queue_redraw()
## How strongly the washes in the roof, the chimney and the door take the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()
## How strongly the walls' wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wall_wash := 0.15:
	set(value):
		wall_wash = value
		queue_redraw()
## How far the house leans into its stride, in degrees. Its feet stay where they are.
@export_range(-30.0, 30.0, 0.5) var lean := 4.0:
	set(value):
		lean = value
		queue_redraw()

## The walls at natural size, standing upright on their legs.
const _WALLS := Rect2(-56.0, -150.0, 112.0, 80.0)
## The roof's eaves and peak.
const _ROOF := [Vector2(-72.0, -144.0), Vector2(0.0, -212.0), Vector2(72.0, -144.0)]
## The chimney's corners, its foot hidden inside the roof.
const _CHIMNEY := [Vector2(24.0, -172.0), Vector2(24.0, -204.0), Vector2(42.0, -204.0), Vector2(42.0, -160.0)]
## The door: the foot of its left side, the middle of its arched top and the arch's radius.
const _DOOR_FOOT := Vector2(-38.0, -70.0)
const _DOOR_ARCH := Vector2(-26.0, -100.0)
const _DOOR_RADIUS := 12.0
## Points round the door's arch.
const _ARCH_POINTS := 7
const _WINDOW := Rect2(4.0, -128.0, 32.0, 28.0)
## The point the house leans about: the middle of the bottom of its walls.
const _PIVOT := Vector2(0.0, -70.0)
## Each leg, back leg first: its hip, which leans with the house, then its knee, its ankle and its toe.
## The back foot pushes off from its toe; the front one lands on its heel.
const _LEGS := [[Vector2(-16.0, -74.0), Vector2(-26.0, -42.0), Vector2(-42.0, -10.0), Vector2(-30.0, -1.0)],
		[Vector2(16.0, -74.0), Vector2(30.0, -42.0), Vector2(38.0, -4.0), Vector2(52.0, -6.0)]]


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var wash := palette.paper.lerp(color, wash_strength)
	var lines: Array[InkLine] = []
	# The legs come first, so the walls' wash hides the tops of them.
	for leg: Array in _LEGS:
		var joints := _on_ground(leg)
		joints[0] = _on_house([leg[0]])[0]
		lines.append(InkLine.along(InkBrush.resample_polyline(joints, spacing), palette.ink))
	lines.append(_washed(_on_house(_CHIMNEY), color, wash, spacing, 0.9))
	lines.append(_washed(_on_house(_corners(_WALLS)), color, palette.paper.lerp(color, wall_wash), spacing))
	lines.append(_washed(_on_house(_ROOF), color, wash, spacing))
	var door := [_DOOR_FOOT]
	for i in _ARCH_POINTS:
		door.append(_DOOR_ARCH + Vector2.LEFT.rotated(PI * i / (_ARCH_POINTS - 1)) * _DOOR_RADIUS)
	door.append(Vector2(_DOOR_ARCH.x * 2.0 - _DOOR_FOOT.x, _DOOR_FOOT.y))
	lines.append(_washed(_on_house(door), color, wash, spacing, 0.9))
	lines.append(_washed(_on_house(_corners(_WINDOW)), color, palette.paper, spacing, 0.9))
	var middle := _WINDOW.get_center()
	for bar: Array in [[Vector2(middle.x, _WINDOW.position.y), Vector2(middle.x, _WINDOW.end.y)],
			[Vector2(_WINDOW.position.x, middle.y), Vector2(_WINDOW.end.x, middle.y)]]:
		lines.append(InkLine.along(InkBrush.resample_polyline(_on_house(bar), spacing), color, 0.7))
	return lines


## A closed polyline round [param corners] with [param wash] inside.
static func _washed(corners: PackedVector2Array, color: Color, wash: Color, spacing: float, width := 1.0) -> InkLine:
	var loop := corners.duplicate()
	loop.append(corners[0])
	var line := InkLine.along(InkBrush.resample_polyline(loop, spacing), color, width, true)
	line.fill = wash
	return line


static func _corners(rect: Rect2) -> Array:
	return [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]


## [param points] of the upright house at natural size, leaned by [member lean] about [constant _PIVOT]
## and drawn [member house_scale] times as big.
func _on_house(points: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point: Vector2 in points:
		out.append((_PIVOT + (point - _PIVOT).rotated(deg_to_rad(lean))) * house_scale)
	return out


## [param points] that stay put on the ground as the house leans, drawn [member house_scale] times as big.
func _on_ground(points: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point: Vector2 in points:
		out.append(point * house_scale)
	return out
