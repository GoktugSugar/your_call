@tool
class_name ReceiptSlip
extends InkDrawing
## A paper receipt drawn in ink: a slip on box paper, its top edge straight and its bottom edge torn off
## in a zigzag. Its origin is the middle of its top edge.

## Width and height of the slip, down to the middle of the torn edge.
@export var size := Vector2(640.0, 600.0):
	set(value):
		size = value
		queue_redraw()
## How far each tooth of the torn edge reaches.
@export_range(0.0, 60.0, 0.5) var tooth_depth := 12.0:
	set(value):
		tooth_depth = value
		queue_redraw()
## Width of each tooth of the torn edge.
@export_range(4.0, 120.0, 0.5) var tooth_width := 28.0:
	set(value):
		tooth_width = value
		queue_redraw()
## Palette role of the slip's line.
@export var role := &"ink":
	set(value):
		role = value
		queue_redraw()
## Palette role of the paper inside it.
@export var paper_role := &"box_paper":
	set(value):
		paper_role = value
		queue_redraw()
## Width of the line, as a multiple of the style's line width.
@export_range(0.2, 4.0, 0.05) var slip_width := 0.9:
	set(value):
		slip_width = value
		queue_redraw()


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var half := size.x * 0.5
	var corners := PackedVector2Array([Vector2(-half, 0.0), Vector2(half, 0.0), Vector2(half, size.y)])
	var teeth := maxi(1, roundi(size.x / tooth_width))
	for i in range(1, teeth * 2 + 1):
		var x := half - size.x * i / (teeth * 2.0)
		corners.append(Vector2(x, size.y + (tooth_depth if i % 2 == 1 else 0.0)))
	var line := InkLine.along(InkBrush.resample_polyline(corners, style.sample_spacing), palette.color(role), slip_width, true)
	line.fill = palette.color(paper_role)
	var lines: Array[InkLine] = [line]
	return lines
