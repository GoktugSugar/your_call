@tool
class_name Clover
extends InkDrawing
## A doodle: a four leaf clover, for good luck. Four heart shaped green leaves meet at its middle, each
## with a green wash inside and a vein down its middle, on a short stem that curves down to the ground.
## Its origin is the ground under it.

## How high the middle of the leaves hangs, from the ground.
@export_range(0.0, 240.0, 0.5) var middle_height := 136.0:
	set(value):
		middle_height = value
		queue_redraw()
## Length of each leaf, from the middle out to the dip between its lobes.
@export_range(10.0, 120.0, 0.5) var leaf_length := 82.0:
	set(value):
		leaf_length = value
		queue_redraw()
## Angle of the first leaf from straight up, in degrees. The others follow it round, a quarter turn apart.
@export_range(-90.0, 90.0, 0.5) var leaf_turn := 45.0:
	set(value):
		leaf_turn = value
		queue_redraw()
## Palette role of every line.
@export var role := &"green":
	set(value):
		role = value
		queue_redraw()
## How strongly each leaf's wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()

## How many leaves it has, evenly spaced round its middle.
const _LEAVES := 4
## One leaf's left half at a length of one, pointing straight up from its point at the middle: out
## round its lobe to the dip at its tip. The right half mirrors it.
const _LEAF_HALF := [Vector2(0.0, 0.0), Vector2(-0.3, -0.24), Vector2(-0.52, -0.52), Vector2(-0.56, -0.82),
		Vector2(-0.4, -1.0), Vector2(-0.16, -1.02), Vector2(0.0, -0.88)]
## How each leaf strays from the others, the way a hand drawing them would: its size as a fraction
## of [member leaf_length], and how many degrees it turns off its quarter.
const _LEAF_STRAYS := [Vector2(1.0, 0.0), Vector2(0.94, 5.0), Vector2(1.05, -4.0), Vector2(0.96, 3.0)]
## How far each vein runs out from the middle, as a fraction of its leaf.
const _VEIN := 0.62
## The stem from the middle down to the ground: each point's offset to the right in pixels, and how
## far down it is, as a fraction of the middle's height.
const _STEM := [Vector2(0.0, 0.0), Vector2(6.0, 0.4), Vector2(18.0, 0.76), Vector2(12.0, 1.0)]


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var middle := Vector2(0.0, -middle_height)
	var lines: Array[InkLine] = []
	var stem := PackedVector2Array()
	for point: Vector2 in _STEM:
		stem.append(middle + Vector2(point.x, middle_height * point.y))
	lines.append(InkLine.along(InkBrush.resample_smooth(stem, false, spacing), color))
	for leaf in _LEAVES:
		var outline := InkLine.along(_leaf(middle, _turn(leaf), _length(leaf), spacing), color, 1.0, true)
		outline.fill = palette.paper.lerp(color, wash_strength)
		lines.append(outline)
	for leaf in _LEAVES:
		var vein := PackedVector2Array([middle, middle + Vector2.UP.rotated(_turn(leaf)) * _length(leaf) * _VEIN])
		lines.append(InkLine.along(InkBrush.resample_polyline(vein, spacing), color, 0.7))
	return lines


## How far leaf number [param leaf] is turned from straight up, clockwise, in radians.
func _turn(leaf: int) -> float:
	var strays: Vector2 = _LEAF_STRAYS[leaf % _LEAF_STRAYS.size()]
	return deg_to_rad(leaf_turn + strays.y) + TAU * leaf / _LEAVES


## The length of leaf number [param leaf].
func _length(leaf: int) -> float:
	var strays: Vector2 = _LEAF_STRAYS[leaf % _LEAF_STRAYS.size()]
	return leaf_length * strays.x


## One heart shaped leaf [param length] long with its point at [param middle], turned [param turn]
## radians clockwise from straight up: its left half out to the dip, then the mirrored right half back,
## each a smooth curve of its own so the point and the dip stay sharp.
func _leaf(middle: Vector2, turn: float, length: float, spacing: float) -> PackedVector2Array:
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for point: Vector2 in _LEAF_HALF:
		left.append(middle + (point * length).rotated(turn))
		right.append(middle + (Vector2(-point.x, point.y) * length).rotated(turn))
	right.reverse()
	var path := InkBrush.resample_smooth(left, false, spacing)
	path.append_array(InkBrush.resample_smooth(right, false, spacing).slice(1))
	return path
