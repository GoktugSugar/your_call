@tool
class_name Crosshair
extends InkDrawing
## The gun's sight, drawn in ink: a ring with four short ticks reaching out from it and a dot in the
## middle. There is no gun on screen; the aim reads through this alone. Its origin is the dot.

## Radius of the ring.
@export_range(4.0, 120.0, 0.5) var ring_radius := 30.0:
	set(value):
		ring_radius = value
		queue_redraw()
## How far each tick reaches out past the ring.
@export_range(0.0, 120.0, 0.5) var tick_length := 18.0:
	set(value):
		tick_length = value
		queue_redraw()
## Gap between the ring and where each tick starts.
@export_range(0.0, 60.0, 0.5) var tick_gap := 4.0:
	set(value):
		tick_gap = value
		queue_redraw()
## Radius of the dot in the middle.
@export_range(0.0, 12.0, 0.1) var dot_radius := 3.2:
	set(value):
		dot_radius = value
		queue_redraw()
## Width of the lines, as a multiple of the style's line width.
@export_range(0.2, 4.0, 0.05) var sight_width := 0.85:
	set(value):
		sight_width = value
		queue_redraw()
## Palette role of the sight.
@export var role := &"ink":
	set(value):
		role = value
		queue_redraw()


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var color := palette.color(role)
	var lines: Array[InkLine] = [InkLine.along(InkBrush.ellipse(Vector2.ZERO, Vector2.ONE * ring_radius, style.sample_spacing),
			color, sight_width, true)]
	for direction: Vector2 in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
		var start := direction * (ring_radius + tick_gap)
		lines.append(InkLine.along(InkBrush.resample_polyline(PackedVector2Array([start, start + direction * tick_length]),
				style.sample_spacing), color, sight_width))
	lines.append(InkLine.dot(Vector2.ZERO, dot_radius, color))
	return lines
