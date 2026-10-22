@tool
class_name SharpHead
extends InkDrawing
## A doodle: a perfect memory that forgets nothing, ever. The head the head doodles share
## ([ProfileHead]), in profile and facing right, in ink with a quiet grey wash, packed inside its skull
## with two rows of crisp, hard zigzag, every stored detail a sharp corner.
## Its origin is the ground under the head's middle.

## How big the head is drawn, as a multiple of its natural size.
@export_range(0.2, 3.0, 0.01) var head_scale := 1.0:
	set(value):
		head_scale = value
		queue_redraw()
## Palette role of the head and its zigzags.
@export var role := &"ink":
	set(value):
		role = value
		queue_redraw()
## Palette role of the wash inside the head: a quiet grey, since an ink wash would sink the zigzags.
@export var wash_role := &"secondary":
	set(value):
		wash_role = value
		queue_redraw()
## How strongly the head's wash takes its colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()
## Radius of the dot eye.
@export_range(0.5, 10.0, 0.1) var eye_radius := 4.0:
	set(value):
		eye_radius = value
		queue_redraw()
## Width of the zigzags' line, as a multiple of the drawing's line width.
@export_range(0.2, 3.0, 0.05) var zigzag_width := 0.75:
	set(value):
		zigzag_width = value
		queue_redraw()

## The zigzags at natural size, from the middle of the skull ([constant ProfileHead.MIND]): two rows of
## narrow, even, sharp teeth, the lower row set a little back, as the skull is, with its teeth under the
## upper row's gaps.
const _ZIGZAGS := [
	[Vector2(-32.0, -10.0), Vector2(-24.0, -28.0), Vector2(-16.0, -10.0), Vector2(-8.0, -28.0), Vector2(0.0, -10.0),
			Vector2(8.0, -28.0), Vector2(16.0, -10.0), Vector2(24.0, -28.0), Vector2(32.0, -10.0)],
	[Vector2(-48.0, 24.0), Vector2(-40.0, 6.0), Vector2(-32.0, 24.0), Vector2(-24.0, 6.0), Vector2(-16.0, 24.0),
			Vector2(-8.0, 6.0), Vector2(0.0, 24.0), Vector2(8.0, 6.0), Vector2(16.0, 24.0), Vector2(24.0, 6.0),
			Vector2(32.0, 24.0)],
]


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var wash := palette.paper.lerp(palette.color(wash_role), wash_strength)
	var lines := ProfileHead.lines(Vector2.ZERO, head_scale, color, wash, eye_radius, palette.ink, spacing)
	var mind := ProfileHead.place(ProfileHead.MIND, Vector2.ZERO, head_scale)
	for zigzag: Array in _ZIGZAGS:
		var path := InkBrush.resample_polyline(ProfileHead.placed(zigzag, mind, head_scale), spacing)
		lines.append(InkLine.along(path, color, zigzag_width))
	return lines
