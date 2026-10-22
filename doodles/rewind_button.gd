@tool
class_name RewindButton
extends InkDrawing
## A doodle: a round push button in ink with a rewind symbol on its cap, and a soft wash in the cap.
## The button body is shared: [PauseButton] extends this and draws only its own symbol.
## Its origin is the middle of the button's base.

## Width and height of the base the cap sits on.
@export var base_size := Vector2(170.0, 30.0):
	set(value):
		base_size = value
		queue_redraw()
## Radius of the base's rounded corners.
@export_range(0.0, 40.0, 0.5) var base_corner := 12.0:
	set(value):
		base_corner = value
		queue_redraw()
## Radius of the round cap.
@export_range(10.0, 120.0, 0.5) var cap_radius := 62.0:
	set(value):
		cap_radius = value
		queue_redraw()
## Palette role of the soft wash inside the cap.
@export var cap_role := &"secondary":
	set(value):
		cap_role = value
		queue_redraw()
## How strongly the cap's wash takes its colour over the paper.
@export_range(0.0, 1.0, 0.01) var cap_wash := 0.4:
	set(value):
		cap_wash = value
		queue_redraw()
## Width of the symbol's line, as a multiple of the drawing's line width.
@export_range(0.2, 3.0, 0.05) var symbol_width := 1.2:
	set(value):
		symbol_width = value
		queue_redraw()

## The rewind symbol, two triangles pointing left, relative to the middle of the cap.
const _REWIND := [[Vector2(4.0, -22.0), Vector2(4.0, 22.0), Vector2(-30.0, 0.0)],
		[Vector2(34.0, -22.0), Vector2(34.0, 22.0), Vector2(0.0, 0.0)]]


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var ink := palette.ink
	var lines: Array[InkLine] = []
	var base_rect := Rect2(-base_size.x * 0.5, -base_size.y, base_size.x, base_size.y)
	var base := InkLine.along(InkBrush.rounded_rect(base_rect, base_corner, spacing), ink, 1.0, true)
	base.fill = palette.paper
	lines.append(base)
	var middle := cap_middle()
	var cap := InkLine.along(InkBrush.ellipse(middle, Vector2.ONE * cap_radius, spacing, -PI * 0.7), ink, 1.0, true)
	cap.fill = palette.paper.lerp(palette.color(cap_role), cap_wash)
	lines.append(cap)
	for shape in _symbol(middle):
		var corners := shape.duplicate()
		corners.append(shape[0])
		lines.append(InkLine.along(InkBrush.resample_polyline(corners, spacing), ink, symbol_width, true))
	return lines


## The middle of the cap: it sits on the base, just touching it.
func cap_middle() -> Vector2:
	return Vector2(0.0, -base_size.y - cap_radius + base_size.y * 0.25)


## The symbol on the cap as closed outlines, placed around [param middle]. Subclasses draw their own.
func _symbol(middle: Vector2) -> Array[PackedVector2Array]:
	var shapes: Array[PackedVector2Array] = []
	for triangle: Array in _REWIND:
		var shape := PackedVector2Array()
		for corner: Vector2 in triangle:
			shape.append(middle + corner)
		shapes.append(shape)
	return shapes
