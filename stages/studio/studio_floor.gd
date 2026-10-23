@tool
class_name StudioFloor
extends InkDrawing
## The game show's stage floor: a line across the page, which can have trapdoors in it, each a slot along
## the line with solid paper below it that hides whatever drops through. Opening one ([method set_open])
## lets its flap swing down into a dark hole. It is drawn in front of the contestants. Its origin is the
## left end of the floor line.

## How long the floor runs.
@export_range(100.0, 4000.0, 1.0) var floor_width := 1920.0:
	set(value):
		floor_width = value
		queue_redraw()
## How deep the solid paper below each trapdoor reaches, hiding whatever drops through.
@export_range(0.0, 600.0, 1.0) var apron_depth := 260.0:
	set(value):
		apron_depth = value
		queue_redraw()
## Where each trapdoor sits along the floor, from its left end.
@export var trapdoors: PackedFloat32Array = []:
	set(value):
		trapdoors = value
		_open.resize(trapdoors.size())
		queue_redraw()
## How wide each trapdoor is.
@export_range(10.0, 600.0, 1.0) var trapdoor_width := 170.0:
	set(value):
		trapdoor_width = value
		queue_redraw()
## How deep the hole under an open trapdoor shows.
@export_range(10.0, 600.0, 1.0) var hole_depth := 110.0:
	set(value):
		hole_depth = value
		queue_redraw()
## Height of the small marks at each end of a trapdoor.
@export_range(0.0, 40.0, 0.5) var hinge_mark := 9.0:
	set(value):
		hinge_mark = value
		queue_redraw()
## Palette role of the line.
@export var role := &"ink":
	set(value):
		role = value
		queue_redraw()
## How strongly the dark of an open hole covers the paper.
@export_range(0.0, 1.0, 0.01) var hole_wash := 0.85:
	set(value):
		hole_wash = value
		queue_redraw()

## How open each trapdoor is, from 0 to 1.
var _open := PackedFloat32Array()


## Opens the trapdoor at [param index] by [param amount], from 0 shut to 1 wide open.
func set_open(index: int, amount: float) -> void:
	if index < 0 or index >= _open.size():
		return
	_open[index] = clampf(amount, 0.0, 1.0)
	queue_redraw()


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var lines: Array[InkLine] = []
	for i in trapdoors.size():
		var left := trapdoors[i] - trapdoor_width * 0.5
		var open := _open[i] if i < _open.size() else 0.0
		# Paper with no line round it, so it reads as more of the page.
		var apron := InkLine.along(InkBrush.rounded_rect(Rect2(left, 0.0, trapdoor_width, apron_depth), 0.0, spacing),
				Color(color, 0.0), 1.0, true)
		apron.fill = palette.paper
		lines.append(apron)
		if open > 0.0:
			var hole := InkLine.along(InkBrush.rounded_rect(Rect2(left, 0.0, trapdoor_width, hole_depth * open), 4.0, spacing),
					color, 0.6, true)
			hole.fill = palette.paper.lerp(color, hole_wash)
			lines.append(hole)
			var flap_end := Vector2(left, 0.0) + Vector2(trapdoor_width, 0.0).rotated(open * PI * 0.5)
			lines.append(InkLine.along(InkBrush.resample_polyline(PackedVector2Array([Vector2(left, 0.0), flap_end]), spacing), color))
		for end in [left, left + trapdoor_width]:
			lines.append(InkLine.along(PackedVector2Array([Vector2(end, -hinge_mark * 0.5), Vector2(end, hinge_mark)]), color, 0.7))
	lines.append(InkLine.along(InkBrush.resample_polyline(PackedVector2Array([Vector2.ZERO, Vector2(floor_width, 0.0)]), spacing), color))
	return lines
