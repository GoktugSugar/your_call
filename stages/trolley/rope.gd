@tool
class_name Rope
extends InkDrawing
## A rope tying souls together where they stand: a loop round each one's waist and a sagging length
## from each to the next. Drawn in this node's space from where the souls are.

## Height of the waist above a grown soul's feet, in pixels. Scaled with each soul.
@export_range(0.0, 200.0, 0.5) var waist_height := 54.0:
	set(value):
		waist_height = value
		queue_redraw()
## How far the rope sags between two souls, in pixels.
@export_range(0.0, 60.0, 0.5) var sag := 10.0:
	set(value):
		sag = value
		queue_redraw()
## Half width and half height of the loop round each waist.
@export var loop_radii := Vector2(8.0, 3.5):
	set(value):
		loop_radii = value
		queue_redraw()
## Palette role of the rope.
@export var role := &"brown":
	set(value):
		role = value
		queue_redraw()

## The souls tied together, in order along the rope.
var souls: Array[Soul] = []:
	set(value):
		souls = value
		queue_redraw()


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var lines: Array[InkLine] = []
	var waists := PackedVector2Array()
	for soul in souls:
		waists.append(to_local(soul.global_position) + Vector2.UP * waist_height * soul.scale.y)
	for waist in waists:
		lines.append(InkLine.along(InkBrush.ellipse(waist, loop_radii, spacing * 0.5), color, 0.8, true))
	for i in range(1, waists.size()):
		var from := waists[i - 1] + Vector2(loop_radii.x, 0.0)
		var to := waists[i] - Vector2(loop_radii.x, 0.0)
		var low := from.lerp(to, 0.5) + Vector2.DOWN * sag
		lines.append(InkLine.along(InkBrush.resample_smooth(PackedVector2Array([from, low, to]), false, spacing), color, 0.8))
	return lines
