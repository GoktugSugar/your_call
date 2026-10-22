@tool
class_name Snowflake
extends InkDrawing
## A doodle: a snowflake, for always being a little too cold. Six sky blue arms spring from a small
## hexagon with a sky wash inside, and each arm carries two pairs of branches, the inner pair longer.
## It hangs a little off the ground with one arm pointing straight down. Its origin is the ground under it.

## How high its middle hangs, from the ground.
@export_range(0.0, 240.0, 0.5) var middle_height := 100.0:
	set(value):
		middle_height = value
		queue_redraw()
## Length of each arm, from the middle to its tip.
@export_range(10.0, 120.0, 0.5) var arm_length := 86.0:
	set(value):
		arm_length = value
		queue_redraw()
## Palette role of the line.
@export var line_role := &"sky":
	set(value):
		line_role = value
		queue_redraw()
## How strongly the hexagon's wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()

## How many arms it has, evenly spaced, the first pointing straight up.
const _ARMS := 6
## Radius of the hexagon in the middle, as a fraction of an arm.
const _HUB := 0.2
## Each pair of branches on an arm: where it springs from, as a fraction of the arm from the middle,
## and how long its branches are, as a fraction of the arm.
const _BRANCHES := [[0.5, 0.32], [0.76, 0.2]]
## The angle between each branch and its arm, in degrees.
const _BRANCH_ANGLE := 50.0


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(line_role)
	var middle := Vector2(0.0, -middle_height)
	var spread := deg_to_rad(_BRANCH_ANGLE)
	var lines: Array[InkLine] = []
	var corners := PackedVector2Array()
	for arm in _ARMS:
		corners.append(middle + _out(arm) * arm_length * _HUB)
	corners.append(corners[0])
	var hub := InkLine.along(InkBrush.resample_polyline(corners, spacing), color, 0.9, true)
	hub.fill = palette.paper.lerp(color, wash_strength)
	lines.append(hub)
	for arm in _ARMS:
		var out := _out(arm)
		var spine := PackedVector2Array([corners[arm], middle + out * arm_length])
		lines.append(InkLine.along(InkBrush.resample_polyline(spine, spacing), color))
		for branch: Array in _BRANCHES:
			var root: Vector2 = middle + out * arm_length * float(branch[0])
			var reach: float = arm_length * float(branch[1])
			var pair := PackedVector2Array([root + out.rotated(-spread) * reach, root, root + out.rotated(spread) * reach])
			lines.append(InkLine.along(InkBrush.resample_polyline(pair, spacing), color, 0.8))
	return lines


## The direction arm number [param arm] points, counting clockwise from straight up.
static func _out(arm: int) -> Vector2:
	return Vector2.UP.rotated(TAU * arm / _ARMS)
