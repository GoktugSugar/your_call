@tool
class_name Sun
extends InkDrawing
## A doodle: the sun, for always being a little too hot. A round gold disc with a gold wash inside,
## ringed by orange rays, long and short in turn, the first pointing straight up. It hangs a little off
## the ground. Its origin is the ground under it.

## How high its middle hangs, from the ground.
@export_range(0.0, 240.0, 0.5) var middle_height := 100.0:
	set(value):
		middle_height = value
		queue_redraw()
## Radius of the disc.
@export_range(10.0, 120.0, 0.5) var disc_radius := 46.0:
	set(value):
		disc_radius = value
		queue_redraw()
## Gap between the disc and the inner end of each ray.
@export_range(0.0, 60.0, 0.5) var ray_gap := 12.0:
	set(value):
		ray_gap = value
		queue_redraw()
## Length of the long rays.
@export_range(2.0, 80.0, 0.5) var long_ray := 32.0:
	set(value):
		long_ray = value
		queue_redraw()
## Length of the short rays between them.
@export_range(2.0, 80.0, 0.5) var short_ray := 22.0:
	set(value):
		short_ray = value
		queue_redraw()
## How many rays ring the disc, long and short in turn.
@export_range(2, 32, 2) var ray_count := 12:
	set(value):
		ray_count = value
		queue_redraw()
## Palette role of the disc.
@export var disc_role := &"gold":
	set(value):
		disc_role = value
		queue_redraw()
## Palette role of the rays.
@export var ray_role := &"orange":
	set(value):
		ray_role = value
		queue_redraw()
## How strongly the disc's wash takes its colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.5:
	set(value):
		wash_strength = value
		queue_redraw()


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var middle := Vector2(0.0, -middle_height)
	var disc_color := palette.color(disc_role)
	var ray_color := palette.color(ray_role)
	var lines: Array[InkLine] = []
	var disc := InkLine.along(InkBrush.ellipse(middle, Vector2.ONE * disc_radius, spacing, -PI * 0.75), disc_color, 1.0, true)
	disc.fill = palette.paper.lerp(disc_color, wash_strength)
	lines.append(disc)
	var inner := disc_radius + ray_gap
	for ray in ray_count:
		var out := Vector2.UP.rotated(TAU * ray / ray_count)
		var length := long_ray if ray % 2 == 0 else short_ray
		var path := PackedVector2Array([middle + out * inner, middle + out * (inner + length)])
		lines.append(InkLine.along(InkBrush.resample_polyline(path, spacing), ray_color, 0.9))
	return lines
