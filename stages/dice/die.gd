@tool
class_name Die
extends InkDrawing
## A six sided die drawn in ink, seen face on: a rounded square filled with paper, so it hides what it
## tumbles over, with the pips of the face it shows as dots. Its origin is its middle, so it turns about
## it as it tumbles.

## The face it shows, from 1 to 6.
@export_range(1, 6) var face := 6:
	set(value):
		face = clampi(value, 1, 6)
		queue_redraw()
## Width and height of the die.
@export_range(20.0, 400.0, 1.0) var side := 170.0:
	set(value):
		side = value
		queue_redraw()
## Radius of its rounded corners.
@export_range(0.0, 100.0, 0.5) var corner_radius := 30.0:
	set(value):
		corner_radius = value
		queue_redraw()
## Radius of each pip.
@export_range(1.0, 40.0, 0.5) var pip_radius := 13.0:
	set(value):
		pip_radius = value
		queue_redraw()
## How far the outer pips sit from the middle, as a share of the die's width.
@export_range(0.05, 0.45, 0.005) var pip_spread := 0.26:
	set(value):
		pip_spread = value
		queue_redraw()

## Where each face's pips sit, in steps of [member pip_spread] from the middle.
const _PIPS := {
	1: [Vector2(0, 0)],
	2: [Vector2(-1, -1), Vector2(1, 1)],
	3: [Vector2(-1, -1), Vector2(0, 0), Vector2(1, 1)],
	4: [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)],
	5: [Vector2(-1, -1), Vector2(1, -1), Vector2(0, 0), Vector2(-1, 1), Vector2(1, 1)],
	6: [Vector2(-1, -1), Vector2(-1, 0), Vector2(-1, 1), Vector2(1, -1), Vector2(1, 0), Vector2(1, 1)],
}


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var ink := palette.ink
	var half := side * 0.5
	var lines: Array[InkLine] = []
	var body := InkLine.along(InkBrush.rounded_rect(Rect2(-half, -half, side, side), corner_radius, style.sample_spacing),
			ink, 1.0, true)
	body.fill = palette.box_paper
	lines.append(body)
	for step: Vector2 in _PIPS[face]:
		lines.append(InkLine.dot(step * side * pip_spread, pip_radius, ink))
	return lines
