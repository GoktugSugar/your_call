@tool
class_name InkFrame
extends Control
## A rounded frame drawn in ink around this control's rect, gone over twice by an unsteady hand,
## on a fill of box paper. The dialogue box is the one place the game draws a box.

## Radius of the rounded corners.
@export_range(0.0, 80.0, 0.5) var corner_radius := 26.0:
	set(value):
		corner_radius = value
		queue_redraw()
## How far apart the two passes of the line wander, in pixels.
@export_range(0.0, 8.0, 0.1) var second_pass_offset := 1.6:
	set(value):
		second_pass_offset = value
		queue_redraw()
## Width of the line, as a multiple of the style's line width.
@export_range(0.0, 4.0, 0.05) var width_scale := 0.9:
	set(value):
		width_scale = value
		queue_redraw()
## Palette role of the fill inside the frame.
@export var fill_role := &"box_paper":
	set(value):
		fill_role = value
		queue_redraw()
## How much of the frame is drawn, going round from the top left: 0 is none, 1 is all of it.
@export_range(0.0, 1.0, 0.001) var reveal := 1.0:
	set(value):
		reveal = value
		queue_redraw()

var _seed := 0


func _ready() -> void:
	_seed = InkPainter.seed_for(self)
	InkPainter.attach(self)
	resized.connect(queue_redraw)


func _draw() -> void:
	var style := InkStyle.get_default()
	var palette := InkPalette.get_default()
	var rect := Rect2(Vector2.ZERO, size)
	var outline := InkBrush.rounded_rect(rect, corner_radius, style.sample_spacing)
	if outline.size() < 3:
		return
	var lines: Array[InkLine] = []
	var first := InkLine.along(outline, palette.ink, 1.0, true)
	first.fill = palette.color(fill_role)
	lines.append(first)
	# The second time round starts a third of the way along, so the two seams fall apart.
	var second := InkBrush.rounded_rect(rect.grow(-second_pass_offset * 0.5), corner_radius, style.sample_spacing)
	var turn := second.size() / 3
	second = second.slice(turn) + second.slice(0, turn)
	lines.append(InkLine.along(second, palette.ink, 0.7, true))
	InkPainter.paint(get_canvas_item(), lines, style.width * width_scale, _seed, InkPainter.current_variant(), style, reveal)
