@tool
class_name CharismaFigure
extends InkDrawing
## A doodle: charisma, everyone liking you at once. A small ink stick figure with dot eyes and a warm
## orange wash in its head, standing on its two feet with its arms held a little out, ringed all round by
## short orange lines like a glow; none falls below its feet. Its origin is the ground between its feet.

## Radius of its head.
@export_range(4.0, 40.0, 0.5) var head_radius := 15.0:
	set(value):
		head_radius = value
		queue_redraw()
## Radius of each dot eye.
@export_range(0.5, 8.0, 0.1) var eye_radius := 2.8:
	set(value):
		eye_radius = value
		queue_redraw()
## Palette role of the glow, and of the wash in its head.
@export var role := &"orange":
	set(value):
		role = value
		queue_redraw()
## How strongly the head's wash takes the glow's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()
## Length of each line of the glow.
@export_range(2.0, 80.0, 0.5) var ray_length := 20.0:
	set(value):
		ray_length = value
		queue_redraw()
## How many lines of glow ring the figure.
@export_range(3, 40) var ray_count := 11:
	set(value):
		ray_count = value
		queue_redraw()

const _HIPS := Vector2(0.0, -64.0)
const _NECK := Vector2(0.0, -124.0)
const _HEAD := Vector2(0.0, -142.0)
const _EYES := [Vector2(-5.0, -144.0), Vector2(5.0, -144.0)]
## The screen left arm, shoulder to elbow to hand, held a little out from its side; the right mirrors it.
const _ARM := [Vector2(0.0, -114.0), Vector2(-19.0, -95.0), Vector2(-37.0, -79.0)]
## The screen left leg, hip to knee to foot; the right mirrors it.
const _LEG := [Vector2(0.0, -64.0), Vector2(-11.0, -32.0), Vector2(-17.0, 0.0)]
## The ring the glow's lines start from: its middle and its radii, across and up.
const _GLOW_MIDDLE := Vector2(0.0, -88.0)
const _GLOW_RADII := Vector2(72.0, 96.0)
## How far round the figure the glow reaches either side, in degrees from straight up, so that it rings
## the figure without falling below its feet.
const _GLOW_REACH := 125.0


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var ink := palette.ink
	var glow := palette.color(role)
	var lines: Array[InkLine] = []
	for i in ray_count:
		var angle := deg_to_rad(lerpf(-_GLOW_REACH, _GLOW_REACH, float(i) / maxi(ray_count - 1, 1)))
		var from := _GLOW_MIDDLE + Vector2.UP.rotated(angle) * _GLOW_RADII
		var out := (from - _GLOW_MIDDLE).normalized()
		lines.append(InkLine.along(InkBrush.resample_polyline(PackedVector2Array([from, from + out * ray_length]), spacing),
				glow, 0.9))
	var head := InkLine.along(InkBrush.ellipse(_HEAD, Vector2.ONE * head_radius, spacing, -PI * 0.75), ink, 1.0, true)
	head.fill = palette.paper.lerp(glow, wash_strength)
	lines.append(head)
	lines.append(InkLine.along(InkBrush.resample_polyline(PackedVector2Array([_HIPS, _NECK]), spacing), ink))
	for side: float in [1.0, -1.0]:
		lines.append(InkLine.along(InkBrush.resample_polyline(_mirrored(_LEG, side), spacing), ink))
		lines.append(InkLine.along(InkBrush.resample_polyline(_mirrored(_ARM, side), spacing), ink))
	for eye: Vector2 in _EYES:
		lines.append(InkLine.dot(eye, eye_radius, ink))
	return lines


static func _mirrored(points: Array, side: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point: Vector2 in points:
		out.append(Vector2(point.x * side, point.y))
	return out
