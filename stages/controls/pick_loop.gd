@tool
class_name PickLoop
extends InkDrawing
## The amber loop a hand draws round a pick: a little over one anticlockwise turn of a tilted ellipse
## that widens as it goes, so the overshoot never retraces the start. It stays hidden until
## [method circle] draws it on round a point.

## Half the loop's width and height.
@export var radii := Vector2(228.0, 196.0):
	set(value):
		radii = value
		queue_redraw()
## How many times round the loop goes. A little over once, as a hand overshoots.
@export_range(0.5, 3.0, 0.01) var turns := 1.12:
	set(value):
		turns = value
		queue_redraw()
## Where the loop starts, in degrees clockwise from the right. It runs anticlockwise from there.
@export_range(-360.0, 360.0, 1.0) var start_angle := -100.0:
	set(value):
		start_angle = value
		queue_redraw()
## How much wider the loop is at its end than at its start, as a share of its size.
@export_range(0.0, 0.5, 0.005) var spread := 0.06:
	set(value):
		spread = value
		queue_redraw()
## How far the loop is tilted, in degrees.
@export_range(-45.0, 45.0, 0.5) var tilt := -4.0:
	set(value):
		tilt = value
		queue_redraw()
## Points per turn, before the loop is smoothed.
@export_range(8, 128, 1) var points_per_turn := 36:
	set(value):
		points_per_turn = value
		queue_redraw()
## Width of the loop, as a multiple of the style's line width.
@export_range(0.2, 4.0, 0.05) var loop_width := 1.3:
	set(value):
		loop_width = value
		queue_redraw()
## Palette role of the loop.
@export var role := &"amber":
	set(value):
		role = value
		queue_redraw()

## The middle of the loop, in this node's space.
var center := Vector2.ZERO:
	set(value):
		center = value
		queue_redraw()


func _ready() -> void:
	super._ready()
	if not Engine.is_editor_hint():
		visible = false


## Draws the loop on round [param around], a point in this node's space, over [param duration]
## seconds. Await it to wait until it is drawn.
func circle(around: Vector2, duration: float) -> void:
	center = around
	visible = true
	await draw_on(duration).finished


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var points := PackedVector2Array()
	var count := maxi(1, ceili(points_per_turn * turns))
	var start := deg_to_rad(start_angle)
	var lean := deg_to_rad(tilt)
	for i in count + 1:
		var along := float(i) / count
		var angle := start - TAU * turns * along
		var size := radii * (1.0 + spread * (along - 0.5))
		points.append(center + Vector2(cos(angle) * size.x, sin(angle) * size.y).rotated(lean))
	var lines: Array[InkLine] = [InkLine.along(InkBrush.resample_smooth(points, false, style.sample_spacing),
			palette.color(role), loop_width)]
	return lines
