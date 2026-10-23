@tool
class_name Signpost
extends InkDrawing
## A doodle: a crossroads, or nowhere else to be. A wooden signpost: a plank post with a shallow point
## on top and two blank arms nailed across it, the upper one pointing right and the lower one pointing
## left, each with a pointed end tipped a little up. A thin grain line runs along each arm and up the
## post, and an ink nail holds each arm on. Its line is muted grey, with a muted wash inside. Its origin
## is the ground under the post.

## How big the signpost is drawn, as a multiple of its natural size.
@export_range(0.2, 3.0, 0.01) var post_scale := 1.0:
	set(value):
		post_scale = value
		queue_redraw()
## Palette role of the signpost's line.
@export var role := &"muted":
	set(value):
		role = value
		queue_redraw()
## Palette role of the nails.
@export var nail_role := &"ink":
	set(value):
		nail_role = value
		queue_redraw()
## How strongly the wash inside takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()
## Radius of each nail.
@export_range(0.5, 10.0, 0.1) var nail_radius := 3.2:
	set(value):
		nail_radius = value
		queue_redraw()

## The post at natural size, from its left foot up to the point on top and down to its right foot.
const _POST := [Vector2(-11.0, 0.0), Vector2(-11.0, -201.0), Vector2(0.0, -211.0), Vector2(11.0, -201.0),
		Vector2(11.0, 0.0)]
## The grain up the post, under the arms.
const _POST_GRAIN := [Vector2(-3.0, -18.0), Vector2(-1.0, -56.0), Vector2(-3.0, -94.0)]
## Each arm: which way it points (1 to the right, -1 to the left), how high its middle crosses the post,
## and how far it tips, in degrees, its pointed end up.
const _ARMS := [[1.0, -170.0, 4.0], [-1.0, -122.0, 3.0]]
## An arm at natural size, pointing right from where it crosses the post: how far its square back end
## sticks out behind the post, where its point begins and where its tip is; and half its height.
const _ARM_BACK := -30.0
const _ARM_SHOULDER := 90.0
const _ARM_TIP := 118.0
const _ARM_HALF := 15.0
## The grain along an arm pointing right, from where it crosses the post.
const _ARM_GRAIN := [Vector2(-14.0, 4.0), Vector2(30.0, 1.0), Vector2(74.0, 4.0)]
## Width of the grain lines, as a multiple of the drawing's line width.
const _GRAIN_LINE := 0.5


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var wash := palette.paper.lerp(color, wash_strength)
	var lines: Array[InkLine] = []
	var post := InkLine.along(InkBrush.resample_polyline(_scaled(_POST), spacing), color, 1.0, true)
	post.fill = wash
	lines.append(post)
	lines.append(InkLine.along(InkBrush.resample_smooth(_scaled(_POST_GRAIN), false, spacing), color, _GRAIN_LINE))
	for arm: Array in _ARMS:
		var way: float = arm[0]
		var height: float = arm[1]
		var tip_up: float = arm[2]
		var place := Transform2D(deg_to_rad(-tip_up * way), Vector2(0.0, height) * post_scale) \
				.scaled_local(Vector2(way, 1.0) * post_scale)
		var outline := PackedVector2Array([Vector2(_ARM_BACK, -_ARM_HALF), Vector2(_ARM_SHOULDER, -_ARM_HALF),
				Vector2(_ARM_TIP, 0.0), Vector2(_ARM_SHOULDER, _ARM_HALF), Vector2(_ARM_BACK, _ARM_HALF),
				Vector2(_ARM_BACK, -_ARM_HALF)])
		var board := InkLine.along(InkBrush.resample_polyline(place * outline, spacing), color, 1.0, true)
		board.fill = wash
		lines.append(board)
		var grain := InkBrush.resample_smooth(place * PackedVector2Array(_ARM_GRAIN), false, spacing)
		lines.append(InkLine.along(grain, color, _GRAIN_LINE))
		lines.append(InkLine.dot(place * Vector2.ZERO, nail_radius, palette.color(nail_role)))
	return lines


func _scaled(points: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point: Vector2 in points:
		out.append(point * post_scale)
	return out
