@tool
class_name BackArrow
extends InkDrawing
## A doodle: a thick arrow making a U turn, for rewinding one decision of a life. Drawn as a sky blue
## outline with a sky wash inside, its band runs right along the ground from a narrow tail, sweeps up
## round a half turn and heads back left over itself, ending in a broad head pointing left with its barbs
## swept back. Its origin is the ground under its middle.

## Radius of the half turn, out to the middle of the band.
@export_range(10.0, 120.0, 0.5) var turn_radius := 62.0:
	set(value):
		turn_radius = value
		queue_redraw()
## Width of the band, through the turn and on to the head.
@export_range(4.0, 100.0, 0.5) var band_width := 46.0:
	set(value):
		band_width = value
		queue_redraw()
## Width of the band at its tail, narrowing towards it along the lower run.
@export_range(2.0, 100.0, 0.5) var tail_width := 30.0:
	set(value):
		tail_width = value
		queue_redraw()
## Length of the band's lower run, from its tail to the turn.
@export_range(0.0, 200.0, 0.5) var lower_run := 116.0:
	set(value):
		lower_run = value
		queue_redraw()
## Length of the band's upper run, from the turn to the head.
@export_range(0.0, 200.0, 0.5) var upper_run := 58.0:
	set(value):
		upper_run = value
		queue_redraw()
## Length of the head, from its back edge to its tip.
@export_range(4.0, 160.0, 0.5) var head_length := 72.0:
	set(value):
		head_length = value
		queue_redraw()
## Width of the head across its back edge, from barb to barb.
@export_range(4.0, 200.0, 0.5) var head_width := 108.0:
	set(value):
		head_width = value
		queue_redraw()
## How far the tips of the barbs sweep back past where the head meets the band.
@export_range(0.0, 60.0, 0.5) var barb_sweep := 12.0:
	set(value):
		barb_sweep = value
		queue_redraw()
## Gap between the ground and the bottom of the band.
@export_range(0.0, 120.0, 0.5) var lift := 4.0:
	set(value):
		lift = value
		queue_redraw()
## Palette role of the line.
@export var role := &"sky":
	set(value):
		role = value
		queue_redraw()
## How strongly the wash inside takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var half := band_width * 0.5
	# The middle of the turn, set across so the whole arrow is centred on the origin.
	var reach_left := maxf(lower_run, upper_run + head_length)
	var reach_right := turn_radius + half
	var turn := Vector2((reach_left - reach_right) * 0.5, -lift - half - turn_radius)
	var lower := turn.y + turn_radius
	var upper := turn.y - turn_radius
	var head := turn.x - upper_run
	var tail := Vector2(turn.x - lower_run, lower)
	var barb := head + barb_sweep
	# Round the outside: along the bottom from the tail, up round the turn, back along the top to the head.
	var corners := PackedVector2Array([tail + Vector2(0.0, tail_width * 0.5)])
	corners.append_array(_arc(turn, turn_radius + half, PI * 0.5, -PI * 0.5, spacing))
	corners.append_array(PackedVector2Array([Vector2(head, upper - half), Vector2(barb, upper - head_width * 0.5),
			Vector2(head - head_length, upper), Vector2(barb, upper + head_width * 0.5), Vector2(head, upper + half)]))
	# And back round the inside to the tail.
	corners.append_array(_arc(turn, turn_radius - half, -PI * 0.5, PI * 0.5, spacing))
	corners.append(tail - Vector2(0.0, tail_width * 0.5))
	corners.append(corners[0])
	var arrow := InkLine.along(InkBrush.resample_polyline(corners, spacing), color, 1.0, true)
	arrow.fill = palette.paper.lerp(color, wash_strength)
	var lines: Array[InkLine] = [arrow]
	return lines


## Points round an arc of [param radius] about [param middle], from angle [param from] to angle
## [param to] (radians), about [param spacing] apart.
static func _arc(middle: Vector2, radius: float, from: float, to: float, spacing: float) -> PackedVector2Array:
	var steps := maxi(2, ceili(absf(to - from) * radius / spacing))
	var out := PackedVector2Array()
	for k in steps + 1:
		var angle := lerpf(from, to, float(k) / steps)
		out.append(middle + Vector2(cos(angle), sin(angle)) * radius)
	return out
