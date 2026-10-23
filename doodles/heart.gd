@tool
class_name Heart
extends InkDrawing
## A doodle: a plain heart, for saving someone. Two round lobes meeting in a dip at the top and a point
## at the bottom, tipped a little to one side and hanging just over the ground, with a short shine
## across its upper left lobe. Its line is pink, with a pink wash inside and the shine in the paper's
## own colour. The whole of it is set so it hangs centred over its origin, the ground under its middle.

## How wide the heart is drawn, from lobe to lobe.
@export_range(20.0, 400.0, 0.5) var heart_width := 206.0:
	set(value):
		heart_width = value
		queue_redraw()
## How far the heart tips, in degrees. Negative tips its top to the left.
@export_range(-45.0, 45.0, 0.5) var tilt := -6.0:
	set(value):
		tilt = value
		queue_redraw()
## Gap between the ground and the heart's lowest point.
@export_range(0.0, 120.0, 0.5) var lift := 8.0:
	set(value):
		lift = value
		queue_redraw()
## Palette role of the heart's line.
@export var role := &"pink":
	set(value):
		role = value
		queue_redraw()
## Palette role of the shine.
@export var shine_role := &"paper":
	set(value):
		shine_role = value
		queue_redraw()
## How strongly the wash inside takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.5:
	set(value):
		wash_strength = value
		queue_redraw()

## The heart is the classic heart curve, 32 units wide: at t, x is 16 times sin(t) cubed and y, upward,
## is 13 cos(t) less 5 cos(2t), 2 cos(3t) and cos(4t). It runs from the dip at the top, at t of zero,
## round the right lobe to the point, at t of PI, and back up round the left. These are its width in
## units and how many points it is sampled at before it is resampled for the brush.
const _CURVE_WIDTH := 32.0
const _CURVE_SAMPLES := 240
## The shine, in the curve's units: a short stroke following the inside of the upper left lobe, from
## low on its side up toward its top.
const _SHINE := [Vector2(-13.2, 4.6), Vector2(-12.3, 7.4), Vector2(-10.2, 9.4)]
## Width of the shine's stroke, as a multiple of the drawing's line width.
const _SHINE_LINE := 0.8


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var unit := heart_width / _CURVE_WIDTH
	var tip := Transform2D(deg_to_rad(tilt), Vector2.ZERO).scaled_local(Vector2(unit, -unit))
	var curve := PackedVector2Array()
	for k in _CURVE_SAMPLES:
		var t := TAU * k / _CURVE_SAMPLES
		curve.append(Vector2(16.0 * pow(sin(t), 3.0), 13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t)))
	curve.append(curve[0])
	var outline := InkLine.along(InkBrush.resample_polyline(tip * curve, spacing), color, 1.0, true)
	outline.fill = palette.paper.lerp(color, wash_strength)
	var shine := InkBrush.resample_smooth(tip * PackedVector2Array(_SHINE), false, spacing * 0.5)
	var lines: Array[InkLine] = [outline, InkLine.along(shine, palette.color(shine_role), _SHINE_LINE)]
	# Set the whole of it centred over the origin, its point lifted off the ground.
	var box := Rect2(outline.path[0], Vector2.ZERO)
	for point in outline.path:
		box = box.expand(point)
	var place := Transform2D(0.0, Vector2(-box.get_center().x, -lift - box.end.y))
	for line in lines:
		line.path = place * line.path
	return lines
