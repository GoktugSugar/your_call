@tool
class_name LieEye
extends InkDrawing
## A doodle: the lie detector, always knowing when anyone lies to you. One big eye ([EyeLens]), wide open
## and staring, its small washed orange iris ringed all round by the white of the eye, with a few lashes
## along its upper lid and a couple of short lines of insight off each corner. It hangs a little off the
## ground. Its origin is the ground under it.

## How high the eye's middle hangs, from the ground.
@export_range(0.0, 240.0, 0.5) var eye_height := 112.0:
	set(value):
		eye_height = value
		queue_redraw()
## Distance from the eye's middle to each of its corners.
@export_range(10.0, 200.0, 0.5) var eye_half_width := 106.0:
	set(value):
		eye_half_width = value
		queue_redraw()
## How far the lids are pulled from the eye's middle: the upper lid up, the lower lid down.
@export var lid_pull := Vector2(50.0, 40.0):
	set(value):
		lid_pull = value
		queue_redraw()
## Radius of the iris: small, so the white shows all round it in a stare.
@export_range(1.0, 80.0, 0.5) var iris_radius := 24.0:
	set(value):
		iris_radius = value
		queue_redraw()
## Radius of the ink dot in the middle of the iris.
@export_range(1.0, 60.0, 0.5) var dot_radius := 9.5:
	set(value):
		dot_radius = value
		queue_redraw()
## Length of each lash.
@export_range(1.0, 60.0, 0.5) var lash_length := 18.0:
	set(value):
		lash_length = value
		queue_redraw()
## Length of each line of insight.
@export_range(1.0, 80.0, 0.5) var insight_length := 22.0:
	set(value):
		insight_length = value
		queue_redraw()
## Palette role of the eye, its iris, its lashes and its lines of insight.
@export var role := &"orange":
	set(value):
		role = value
		queue_redraw()
## How strongly the iris's wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()

## Where each lash grows from the upper lid, as a fraction of the way from the eye's middle to its right
## corner, negative toward its left.
const _LASHES := [-0.62, -0.31, 0.0, 0.31, 0.62]
## The lines of insight off the right corner, each the way it points in degrees clockwise from pointing
## right; the left corner's mirror them.
const _INSIGHT := [-24.0, 24.0]
## Gap between a corner and its lines of insight.
const _INSIGHT_GAP := 12.0


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var middle := Vector2(0.0, -eye_height)
	var lines: Array[InkLine] = []
	var outline := EyeLens.outline(middle, eye_half_width, lid_pull)
	lines.append(InkLine.along(InkBrush.resample_polyline(outline, spacing), color, 1.0, true))
	for share: float in _LASHES:
		var x := eye_half_width * share
		var root := EyeLens.upper(middle, eye_half_width, lid_pull, x)
		var tip := root + EyeLens.upper_normal(eye_half_width, lid_pull, x) * lash_length
		lines.append(InkLine.along(InkBrush.resample_polyline(PackedVector2Array([root, tip]), spacing), color, 0.8))
	for side: float in [-1.0, 1.0]:
		var corner := middle + Vector2.RIGHT * eye_half_width * side
		for angle: float in _INSIGHT:
			var out := Vector2.from_angle(deg_to_rad(angle))
			out.x *= side
			var from := corner + out * _INSIGHT_GAP
			lines.append(InkLine.along(InkBrush.resample_polyline(PackedVector2Array([from, from + out * insight_length]),
					spacing), color, 0.8))
	var iris := InkLine.along(InkBrush.ellipse(middle, Vector2.ONE * iris_radius, spacing, -PI * 0.75), color, 0.9, true)
	iris.fill = palette.paper.lerp(color, wash_strength)
	lines.append(iris)
	lines.append(InkLine.dot(middle, dot_radius, palette.ink))
	return lines
