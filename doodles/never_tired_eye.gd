@tool
class_name NeverTiredEye
extends InkDrawing
## A doodle: never sleeping, never tiring again. One eye ([EyeLens]) held wide open, its lids pulled apart
## and propped there by a little ink stick either side of its washed purple iris, over a small purple z of
## sleep struck out with a line of ink. It hangs a little off the ground. Its origin is the ground under it.

## How high the eye's middle hangs, from the ground.
@export_range(0.0, 240.0, 0.5) var eye_height := 132.0:
	set(value):
		eye_height = value
		queue_redraw()
## Distance from the eye's middle to each of its corners.
@export_range(10.0, 200.0, 0.5) var eye_half_width := 90.0:
	set(value):
		eye_half_width = value
		queue_redraw()
## How far the lids are pulled from the eye's middle: the upper lid up, the lower lid down.
@export var lid_pull := Vector2(56.0, 46.0):
	set(value):
		lid_pull = value
		queue_redraw()
## Radius of the iris.
@export_range(1.0, 80.0, 0.5) var iris_radius := 29.0:
	set(value):
		iris_radius = value
		queue_redraw()
## Radius of the ink dot in the middle of the iris.
@export_range(1.0, 60.0, 0.5) var dot_radius := 13.0:
	set(value):
		dot_radius = value
		queue_redraw()
## Height of the z under the eye.
@export_range(4.0, 80.0, 0.5) var z_size := 40.0:
	set(value):
		z_size = value
		queue_redraw()
## Palette role of the eye, its iris and the z. The props and the strike are ink.
@export var role := &"purple":
	set(value):
		role = value
		queue_redraw()
## How strongly the iris's wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()

## Where each prop stands, as a fraction of the eye's half width out from its middle.
const _PROP_AT := 0.6
## How far each prop leans outward at its top, in degrees.
const _PROP_LEAN := 6.0
## How far each prop pokes past the lids it holds apart, top and bottom.
const _PROP_OVERHANG := 7.0
## Width of the props' line, as a multiple of the drawing's line width.
const _PROP_WIDTH := 1.1
## Gap between the bottom of the eye and the top of the z.
const _Z_GAP := 18.0
## Width of the z, as a fraction of its height.
const _Z_WIDTH := 0.9
## How far the line striking out the z runs either side of its middle, as a multiple of its half width.
const _STRIKE_REACH := 2.2
## How far the strike falls from its left end to its right, as a fraction of the z's height. It stays
## shallow, since a strike as steep as the z's slant would cross it into an hourglass.
const _STRIKE_FALL := 0.45
## Width of the strike's line, as a multiple of the drawing's line width.
const _STRIKE_WIDTH := 1.15


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var middle := Vector2(0.0, -eye_height)
	var lines: Array[InkLine] = []
	var outline := EyeLens.outline(middle, eye_half_width, lid_pull)
	lines.append(InkLine.along(InkBrush.resample_polyline(outline, spacing), color, 1.0, true))
	var iris := InkLine.along(InkBrush.ellipse(middle, Vector2.ONE * iris_radius, spacing, -PI * 0.75), color, 0.9, true)
	iris.fill = palette.paper.lerp(color, wash_strength)
	lines.append(iris)
	lines.append(InkLine.dot(middle, dot_radius, palette.ink))
	for side: float in [-1.0, 1.0]:
		var x := eye_half_width * _PROP_AT * side
		var low := EyeLens.lower(middle, eye_half_width, lid_pull, x)
		var lean := Vector2.UP.rotated(deg_to_rad(_PROP_LEAN) * side)
		var bottom := low - lean * _PROP_OVERHANG
		var top := low + lean * (low.y - EyeLens.upper(middle, eye_half_width, lid_pull, x).y + _PROP_OVERHANG)
		lines.append(InkLine.along(InkBrush.resample_polyline(PackedVector2Array([bottom, top]), spacing), palette.ink,
				_PROP_WIDTH))
	var z_middle := Vector2(0.0, middle.y + lid_pull.y + _Z_GAP + z_size * 0.5)
	var half := Vector2(z_size * _Z_WIDTH, z_size) * 0.5
	var z := PackedVector2Array([z_middle - half, z_middle + Vector2(half.x, -half.y), z_middle + Vector2(-half.x, half.y),
			z_middle + half])
	lines.append(InkLine.along(InkBrush.resample_polyline(z, spacing), color, 0.9))
	var strike := Vector2(half.x * _STRIKE_REACH, z_size * _STRIKE_FALL * 0.5)
	lines.append(InkLine.along(InkBrush.resample_polyline(PackedVector2Array([z_middle - strike, z_middle + strike]),
			spacing), palette.ink, _STRIKE_WIDTH))
	return lines
