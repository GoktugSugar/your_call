@tool
class_name InkUnderline
extends Control
## A quick hand-drawn line across this control's width, through its middle, drawn on from the left.

## How much of the line is drawn, from the left: 0 is none, 1 is all of it.
@export_range(0.0, 1.0, 0.001) var reveal := 1.0:
	set(value):
		reveal = value
		queue_redraw()
## How far the line sags in the middle, in pixels. A hand rarely draws one dead straight.
@export_range(-20.0, 20.0, 0.1) var sag := 2.0:
	set(value):
		sag = value
		queue_redraw()
## Width of the line, as a multiple of the style's line width.
@export_range(0.0, 4.0, 0.05) var width_scale := 0.8:
	set(value):
		width_scale = value
		queue_redraw()
## Palette role of the line.
@export var color_role := &"amber":
	set(value):
		color_role = value
		queue_redraw()

var _seed := 0


func _ready() -> void:
	_seed = InkPainter.seed_for(self)
	InkPainter.attach(self)
	resized.connect(queue_redraw)


func _draw() -> void:
	if size.x <= 0.0:
		return
	var style := InkStyle.get_default()
	var y := size.y * 0.5
	var points := PackedVector2Array([Vector2(0.0, y), Vector2(size.x * 0.5, y + sag), Vector2(size.x, y - sag * 0.3)])
	var lines: Array[InkLine] = [InkLine.along(InkBrush.resample_smooth(points, false, style.sample_spacing),
			InkPalette.get_default().color(color_role))]
	InkPainter.paint(get_canvas_item(), lines, style.width * width_scale, _seed, InkPainter.current_variant(), style, reveal)
