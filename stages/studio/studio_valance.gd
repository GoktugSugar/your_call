@tool
class_name StudioValance
extends InkDrawing
## The top of the game show's studio: a curtain valance hanging across the top of the page, its lower
## edge in scallops, and a short swag gathered at either corner, all kept above where the imp stands.
## An ink line round a muted wash. Its origin is the top left of the page.

## How wide the page is.
@export_range(100.0, 4000.0, 1.0) var page_width := 1920.0:
	set(value):
		page_width = value
		queue_redraw()
## How far down the valance hangs, to the top of its scallops.
@export_range(0.0, 400.0, 1.0) var depth := 58.0:
	set(value):
		depth = value
		queue_redraw()
## How many scallops run along its lower edge.
@export_range(1, 40) var scallops := 9:
	set(value):
		scallops = value
		queue_redraw()
## How far each scallop sags below the valance.
@export_range(0.0, 120.0, 0.5) var sag := 22.0:
	set(value):
		sag = value
		queue_redraw()
## How far down each corner swag hangs, and how far in it reaches along the valance.
@export var swag := Vector2(150.0, 170.0):
	set(value):
		swag = value
		queue_redraw()
## Palette role of the line.
@export var role := &"ink":
	set(value):
		role = value
		queue_redraw()
## Palette role of the wash inside.
@export var wash_role := &"secondary":
	set(value):
		wash_role = value
		queue_redraw()
## How strongly the wash takes its colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.35:
	set(value):
		wash_strength = value
		queue_redraw()

## How far above the page the valance starts, so its top edge is never seen.
const _ABOVE := 12.0
## Points along each scallop's curve.
const _SCALLOP_POINTS := 8


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var color := palette.color(role)
	var wash := palette.paper.lerp(palette.color(wash_role), wash_strength)
	var lines: Array[InkLine] = []
	var outline := PackedVector2Array([Vector2(page_width + _ABOVE, -_ABOVE), Vector2(-_ABOVE, -_ABOVE)])
	var step := page_width / scallops
	for i in scallops:
		for j in _SCALLOP_POINTS + 1:
			var t := float(j) / _SCALLOP_POINTS
			outline.append(Vector2(step * (i + t), depth + sin(t * PI) * sag))
	lines.append(_washed(InkBrush.resample_smooth(outline, true, style.sample_spacing), color, wash))
	for side in [-1.0, 1.0]:
		var edge := 0.0 if side < 0.0 else page_width
		var swag_points := PackedVector2Array([Vector2(edge - side * _ABOVE, depth),
				Vector2(edge - side * _ABOVE, depth + swag.y), Vector2(edge - side * swag.x * 0.35, depth + swag.y * 0.55),
				Vector2(edge - side * swag.x, depth + sag * 0.5)])
		lines.append(_washed(InkBrush.resample_smooth(swag_points, true, style.sample_spacing), color, wash))
	return lines


static func _washed(path: PackedVector2Array, color: Color, wash: Color) -> InkLine:
	var line := InkLine.along(path, color, 1.0, true)
	line.fill = wash
	return line
