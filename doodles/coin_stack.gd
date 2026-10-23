@tool
class_name CoinStack
extends InkDrawing
## A doodle: gold, for the taking or as a promised reward. A small stack of gold coins seen side on and
## a little from above, each coin a short disc set slightly off the one under it, as a hand would stack
## them, with the top coin's face showing a ring. One more coin leans on its edge against the stack's
## side, face out. Its line is gold, with a stronger gold wash on the coins' edges than on their faces.
## The whole of it is set so it stands centred over its origin, the ground under its middle.

## How big the coins are drawn, as a multiple of their natural size.
@export_range(0.2, 3.0, 0.01) var stack_scale := 1.0:
	set(value):
		stack_scale = value
		queue_redraw()
## How many coins are stacked.
@export_range(1, 12) var coin_count := 10:
	set(value):
		coin_count = value
		queue_redraw()
## How far the leaning coin tips against the stack, in degrees.
@export_range(0.0, 45.0, 0.5) var lean := 16.0:
	set(value):
		lean = value
		queue_redraw()
## Palette role of every line.
@export var role := &"gold":
	set(value):
		role = value
		queue_redraw()
## How strongly the coins' edges take the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.55:
	set(value):
		wash_strength = value
		queue_redraw()
## How strongly the coins' faces take the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var face_wash := 0.3:
	set(value):
		face_wash = value
		queue_redraw()

## A stacked coin at natural size: its half width, the half height of its face seen from a little
## above, and how thick it is.
const _COIN_RADII := Vector2(56.0, 14.0)
const _COIN_THICKNESS := 16.0
## How far each coin up the stack sits to the right of the stack's middle, cycling up a tall stack.
const _STRAYS := [0.0, 5.0, -2.0, 4.0, -4.0, 3.0, -1.0, 5.0, 1.0, -3.0, 4.0, -2.0]
## How far the middle of a coin's top edge runs up under the coin above it, so that coin's wash covers it.
const _TUCK := 4.0
## The leaning coin: how far its middle sits right of the stack's middle and up from the ground before
## it leans, the half width and height of its face, and how far its rim shows to the right of the face.
const _LEANER := Vector2(80.0, -42.0)
const _LEANER_RADII := Vector2(36.0, 42.0)
const _LEANER_RIM := 7.0
## The ring on a coin's face, as a fraction of the face.
const _RING := 0.68
## Width of the rings' lines, as a multiple of the drawing's line width.
const _RING_LINE := 0.6


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var edge_wash := palette.paper.lerp(color, wash_strength)
	var wash := palette.paper.lerp(color, face_wash)
	var radii := _COIN_RADII * stack_scale
	var thickness := _COIN_THICKNESS * stack_scale
	var tuck := _TUCK * stack_scale
	var lines: Array[InkLine] = []
	# Each coin's edge from the bottom up, its top bowing less than its bottom, so it runs up under the
	# next coin, which hides it.
	var bottom := Vector2(0.0, -radii.y)
	for coin in coin_count:
		var stray: float = _STRAYS[coin % _STRAYS.size()]
		bottom.x = stray * stack_scale
		var top := bottom + Vector2(0.0, -thickness)
		var edge := _front(bottom, radii, spacing)
		edge.reverse()
		edge.append_array(_front(top, radii - Vector2(0.0, tuck), spacing))
		lines.append(_washed(edge, color, edge_wash))
		bottom = top
	lines.append(_washed(InkBrush.ellipse(bottom, radii, spacing, PI), color, wash))
	lines.append(InkLine.along(InkBrush.ellipse(bottom, radii * _RING, spacing * 0.5, PI), color, _RING_LINE, true))
	# The leaning coin: its rim behind, then its face.
	var turn := Transform2D(deg_to_rad(-lean), _LEANER * stack_scale)
	var leaner_radii := _LEANER_RADII * stack_scale
	var rim := InkBrush.ellipse(Vector2(_LEANER_RIM * stack_scale, 0.0), leaner_radii, spacing, PI)
	lines.append(_washed(turn * rim, color, edge_wash))
	lines.append(_washed(turn * InkBrush.ellipse(Vector2.ZERO, leaner_radii, spacing, PI), color, wash))
	var ring := InkBrush.ellipse(Vector2.ZERO, leaner_radii * _RING, spacing * 0.5, PI)
	lines.append(InkLine.along(turn * ring, color, _RING_LINE, true))
	# Set the whole of it centred over the origin, standing on the ground.
	var box := Rect2(lines[0].path[0], Vector2.ZERO)
	for line in lines:
		for point in line.path:
			box = box.expand(point)
	var place := Transform2D(0.0, Vector2(-box.get_center().x, -box.end.y))
	for line in lines:
		line.path = place * line.path
	return lines


## The front half of the ellipse round [param middle] with [param radii], from its right end round
## under the middle to its left end.
static func _front(middle: Vector2, radii: Vector2, spacing: float) -> PackedVector2Array:
	var steps := maxi(2, ceili(PI * sqrt((radii.x * radii.x + radii.y * radii.y) * 0.5) / spacing))
	var out := PackedVector2Array()
	for k in steps + 1:
		var angle := PI * k / steps
		out.append(middle + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	return out


## A closed line along [param path] with [param wash] inside it.
static func _washed(path: PackedVector2Array, color: Color, wash: Color) -> InkLine:
	var line := InkLine.along(path, color, 1.0, true)
	line.fill = wash
	return line
