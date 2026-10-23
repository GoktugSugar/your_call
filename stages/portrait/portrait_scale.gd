@tool
class_name PortraitScale
extends InkDrawing
## One scale of the player's portrait: a hand-drawn line from one pole of an axis to the other, a tick
## at its middle, and a mark where the player leans. No numbers. Lit, the line turns amber while the imp
## talks about it. Its origin is the middle of the line.

## How long the line is.
@export_range(10.0, 1600.0, 1.0) var length := 700.0:
	set(value):
		length = value
		queue_redraw()
## Height of the tick at the middle.
@export_range(0.0, 60.0, 0.5) var tick := 14.0:
	set(value):
		tick = value
		queue_redraw()
## Radius of the mark.
@export_range(1.0, 40.0, 0.5) var mark_radius := 11.0:
	set(value):
		mark_radius = value
		queue_redraw()
## Palette roles of the line at rest, lit, and the mark.
@export var role := &"secondary":
	set(value):
		role = value
		queue_redraw()
@export var lit_role := &"amber":
	set(value):
		lit_role = value
		queue_redraw()
@export var mark_role := &"ink":
	set(value):
		mark_role = value
		queue_redraw()
## Where the mark sits, from -1 at the first pole's end to 1 at the second's.
@export_range(-1.0, 1.0, 0.001) var lean := 0.0:
	set(value):
		lean = value
		queue_redraw()
## Whether the imp is talking about this one.
@export var lit := false:
	set(value):
		lit = value
		queue_redraw()


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(lit_role if lit else role)
	var half := length * 0.5
	var lines: Array[InkLine] = []
	lines.append(InkLine.along(InkBrush.resample_smooth(PackedVector2Array([Vector2(-half, 0.0), Vector2(0.0, 1.5),
			Vector2(half, 0.0)]), false, spacing), color))
	lines.append(InkLine.along(PackedVector2Array([Vector2(0.0, -tick * 0.5), Vector2(0.0, tick * 0.5)]), color, 0.7))
	lines.append(InkLine.dot(Vector2(lean * half, 0.0), mark_radius, palette.color(lit_role if lit else mark_role)))
	return lines
