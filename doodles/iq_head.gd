@tool
class_name IqHead
extends InkDrawing
## A doodle: ten more points of IQ. The head the head doodles share ([ProfileHead]), in profile and facing
## right, in sky with a sky wash, and a small bold up arrow rising from the top of its skull.
## Its origin is the ground under the head's middle.

## How big the head is drawn, as a multiple of its natural size.
@export_range(0.2, 3.0, 0.01) var head_scale := 1.0:
	set(value):
		head_scale = value
		queue_redraw()
## Palette role of the head and its arrow.
@export var role := &"sky":
	set(value):
		role = value
		queue_redraw()
## How strongly each wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()
## Radius of the dot eye.
@export_range(0.5, 10.0, 0.1) var eye_radius := 4.0:
	set(value):
		eye_radius = value
		queue_redraw()

## The arrow's outline at natural size, from the top of the skull ([constant ProfileHead.CROWN]): up one
## side of its shaft, out along its head to its point, and down the other side.
const _ARROW := [Vector2(-8.0, -7.0), Vector2(-8.0, -25.0), Vector2(-21.0, -25.0), Vector2(0.0, -47.0),
		Vector2(21.0, -25.0), Vector2(8.0, -25.0), Vector2(8.0, -7.0)]


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var wash := palette.paper.lerp(color, wash_strength)
	var lines := ProfileHead.lines(Vector2.ZERO, head_scale, color, wash, eye_radius, palette.ink, spacing)
	var crown := ProfileHead.place(ProfileHead.CROWN, Vector2.ZERO, head_scale)
	var corners := ProfileHead.placed(_ARROW, crown, head_scale)
	corners.append(corners[0])
	var arrow := InkLine.along(InkBrush.resample_polyline(corners, spacing), color, 1.0, true)
	arrow.fill = wash
	lines.append(arrow)
	return lines
