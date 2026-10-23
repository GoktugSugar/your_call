@tool
class_name GuessScale
extends InkDrawing
## The bar a guess is marked on: an empty ink outline from none of the room at its left end to all of it
## at its right, and, once there is one, the guess as an amber mark standing across it with a round
## handle on top. Its origin is the left end of the bar's middle.

## How long the bar is: the whole room.
@export_range(10.0, 1600.0, 1.0) var length := 800.0:
	set(value):
		length = value
		queue_redraw()
## How tall the bar is.
@export_range(2.0, 120.0, 0.5) var bar_height := 30.0:
	set(value):
		bar_height = value
		queue_redraw()
## How far the mark reaches past the bar, above and below.
@export_range(0.0, 120.0, 0.5) var mark_reach := 16.0:
	set(value):
		mark_reach = value
		queue_redraw()
## Radius of the mark's handle.
@export_range(0.0, 30.0, 0.5) var handle_radius := 7.0:
	set(value):
		handle_radius = value
		queue_redraw()
## Palette role of the bar.
@export var role := &"ink":
	set(value):
		role = value
		queue_redraw()
## Palette role of the mark.
@export var mark_role := &"amber":
	set(value):
		mark_role = value
		queue_redraw()
## The guess, from 0 to 100. Below 0 shows no mark.
@export_range(-1.0, 100.0, 0.1) var guess := -1.0:
	set(value):
		guess = value
		queue_redraw()


## Where along the bar [param share] of the room falls, in the bar's own space.
func x_of(share: float) -> float:
	return length * clampf(share, 0.0, 100.0) / 100.0


## The share of the room at [param x] along the bar, in the bar's own space, from 0 to 100.
func share_at(x: float) -> float:
	return clampf(x / length * 100.0, 0.0, 100.0) if length > 0.0 else 0.0


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var lines: Array[InkLine] = []
	var rect := Rect2(0.0, -bar_height * 0.5, length, bar_height)
	lines.append(InkLine.along(InkBrush.rounded_rect(rect, bar_height * 0.25, spacing), palette.color(role), 0.8, true))
	if guess >= 0.0:
		var x := x_of(guess)
		var top := Vector2(x, -bar_height * 0.5 - mark_reach)
		var color := palette.color(mark_role)
		lines.append(InkLine.along(InkBrush.resample_polyline(PackedVector2Array([top,
				Vector2(x, bar_height * 0.5 + mark_reach)]), spacing), color, 1.2))
		lines.append(InkLine.dot(top, handle_radius, color))
	return lines
