@tool
class_name MapPin
extends InkDrawing
## A pushpin in ink: a round red head with a soft wash, on a short needle leaning a little to one side.
## Its origin is the needle's tip, so a pin placed at a point on the map pricks that point.

## Radius of the head.
@export_range(2.0, 40.0, 0.5) var head_radius := 11.0:
	set(value):
		head_radius = value
		queue_redraw()
## Length of the needle, from its tip to the head.
@export_range(4.0, 120.0, 0.5) var needle_length := 26.0:
	set(value):
		needle_length = value
		queue_redraw()
## How far the pin leans, in degrees. Positive leans to the right.
@export_range(-45.0, 45.0, 0.5) var lean := 12.0:
	set(value):
		lean = value
		queue_redraw()
## Palette role of the head.
@export var head_role := &"red":
	set(value):
		head_role = value
		queue_redraw()
## How strongly the head's wash takes its colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash := 0.5:
	set(value):
		wash = value
		queue_redraw()
## Width of the needle, as a multiple of the line width.
@export_range(0.1, 3.0, 0.05) var needle_width := 0.8:
	set(value):
		needle_width = value
		queue_redraw()


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var up := Vector2.UP.rotated(deg_to_rad(lean))
	var color := palette.color(head_role)
	var lines: Array[InkLine] = []
	lines.append(InkLine.along(InkBrush.resample_polyline(PackedVector2Array([Vector2.ZERO, up * needle_length]),
			spacing * 0.5), palette.ink, needle_width))
	var head := InkLine.along(InkBrush.ellipse(up * (needle_length + head_radius), Vector2.ONE * head_radius,
			spacing * 0.5, -PI * 0.7), color, 1.0, true)
	head.fill = palette.paper.lerp(color, wash)
	lines.append(head)
	return lines
