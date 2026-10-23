@tool
class_name VoiceHead
extends InkDrawing
## A doodle: a wise voice in your head, always right. The head the head doodles share ([ProfileHead]), in
## profile and facing right, in green with a green wash, and inside its skull a small speech bubble on
## the paper, a squiggle of speech in it and its tail pointing back into the head, where the voice is.
## Its origin is the ground under the head's middle.

## How big the head is drawn, as a multiple of its natural size.
@export_range(0.2, 3.0, 0.01) var head_scale := 1.0:
	set(value):
		head_scale = value
		queue_redraw()
## Palette role of the head, its bubble and its squiggle.
@export var role := &"green":
	set(value):
		role = value
		queue_redraw()
## How strongly the head's wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()
## Radius of the dot eye.
@export_range(0.5, 10.0, 0.1) var eye_radius := 4.0:
	set(value):
		eye_radius = value
		queue_redraw()
## The speech bubble's two radii, across and up, at natural size.
@export var bubble_size := Vector2(34.0, 23.0):
	set(value):
		bubble_size = value
		queue_redraw()
## Width of the bubble's and the squiggle's line, as a multiple of the drawing's line width.
@export_range(0.2, 3.0, 0.05) var bubble_width := 0.9:
	set(value):
		bubble_width = value
		queue_redraw()

## The bubble's middle at natural size, from the middle of the skull ([constant ProfileHead.MIND]).
const _BUBBLE_MIDDLE := Vector2(2.0, -6.0)
## Where the bubble's tail leaves its rim: the angles of its two roots, in degrees clockwise from pointing right.
const _TAIL_ROOTS := Vector2(116.0, 146.0)
## The way the tail points, in degrees clockwise from pointing right.
const _TAIL_ANGLE := 138.0
## How far the tail's point reaches past the rim, at natural size.
const _TAIL_REACH := 17.0
## How many waves the squiggle makes.
const _SQUIGGLE_WAVES := 2.0
## Points along each wave of the squiggle, before it is smoothed.
const _SQUIGGLE_POINTS := 8
## How far across the bubble the squiggle reaches either side of its middle, as a fraction of its radius.
const _SQUIGGLE_REACH := 0.56
## How high the squiggle's waves rise and fall, as a fraction of the bubble's upward radius.
const _SQUIGGLE_HEIGHT := 0.2


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var lines := ProfileHead.lines(Vector2.ZERO, head_scale, color, palette.paper.lerp(color, wash_strength),
			eye_radius, palette.ink, spacing)
	var mind := ProfileHead.place(ProfileHead.MIND, Vector2.ZERO, head_scale)
	var middle := mind + _BUBBLE_MIDDLE * head_scale
	var radii := bubble_size * head_scale
	var bubble := InkLine.along(_bubble(middle, radii, spacing), color, bubble_width, true)
	bubble.fill = palette.paper
	lines.append(bubble)
	lines.append(InkLine.along(InkBrush.resample_smooth(_squiggle(middle, radii), false, spacing), color, bubble_width))
	return lines


## The bubble's closed outline round [param middle]: its rim from one root of its tail the long way round to
## the other, then out to the tail's point and back, its corners kept sharp.
func _bubble(middle: Vector2, radii: Vector2, spacing: float) -> PackedVector2Array:
	var from := deg_to_rad(_TAIL_ROOTS.y)
	var to := deg_to_rad(_TAIL_ROOTS.x) + TAU
	var count := ceili((to - from) * maxf(radii.x, radii.y) / spacing)
	var path := PackedVector2Array()
	for i in count + 1:
		var angle := lerpf(from, to, float(i) / count)
		path.append(middle + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	var way := Vector2.from_angle(deg_to_rad(_TAIL_ANGLE))
	path.append(middle + way * radii + way * _TAIL_REACH * head_scale)
	path.append(path[0])
	return InkBrush.resample_polyline(path, spacing)


## The squiggle across the bubble's middle, before smoothing: a few gentle waves.
static func _squiggle(middle: Vector2, radii: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	var count := ceili(_SQUIGGLE_WAVES * _SQUIGGLE_POINTS)
	for i in count + 1:
		var t := float(i) / count
		var across := lerpf(-1.0, 1.0, t) * radii.x * _SQUIGGLE_REACH
		var rise := sin(TAU * _SQUIGGLE_WAVES * t) * radii.y * _SQUIGGLE_HEIGHT
		points.append(middle + Vector2(across, rise))
	return points
