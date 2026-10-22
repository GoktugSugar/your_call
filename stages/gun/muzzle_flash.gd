@tool
class_name MuzzleFlash
extends InkDrawing
## The flash at a gun's muzzle as it fires: a handful of short amber rays bursting out of a point, drawn
## on in an instant and gone just as fast. It marks the gun, never the one it hits. Its origin is the muzzle.

## How many rays burst out.
@export_range(3, 16) var rays := 7:
	set(value):
		rays = value
		queue_redraw()
## How far the rays start from the muzzle, and how far they reach.
@export var ray_span := Vector2(10.0, 42.0):
	set(value):
		ray_span = value
		queue_redraw()
## Width of the rays, as a multiple of the style's line width.
@export_range(0.2, 4.0, 0.05) var ray_width := 1.2:
	set(value):
		ray_width = value
		queue_redraw()
## Palette role of the rays.
@export var role := &"amber":
	set(value):
		role = value
		queue_redraw()
## Seconds the flash stays before it is gone.
@export_range(0.02, 1.0, 0.01) var flash_time := 0.14


func _ready() -> void:
	super._ready()
	if not Engine.is_editor_hint():
		visible = false


## Bursts at the muzzle and is gone again.
func burst() -> void:
	visible = true
	modulate.a = 1.0
	var fade := create_tween()
	fade.tween_property(self, ^"modulate:a", 0.0, flash_time).set_delay(flash_time * 0.5)
	await fade.finished
	visible = false


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var color := palette.color(role)
	var lines: Array[InkLine] = []
	for i in rays:
		var direction := Vector2.RIGHT.rotated(TAU * (i + 0.5 * (i % 2)) / rays)
		var reach := ray_span.y * (1.0 if i % 2 == 0 else 0.7)
		lines.append(InkLine.along(InkBrush.resample_polyline(PackedVector2Array([direction * ray_span.x, direction * reach]),
				style.sample_spacing), color, ray_width))
	return lines
