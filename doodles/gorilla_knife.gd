@tool
class_name GorillaKnife
extends Gorilla
## A doodle: the silverback of [Gorilla], line for line, holding a small knife in its near fist. The
## handle is gripped across the fist and the blade points up and forward, clear of the arm. The knife
## is drawn in its own colour, with a wash in its handle and bare paper in its blade.
## Its origin is the ground under its middle.

## Palette role of the knife.
@export var knife_role := &"red":
	set(value):
		knife_role = value
		queue_redraw()

## Where the knife's hilt sits, in the gorilla's space, and which way its blade points, in degrees
## from pointing straight forward, upward negative. The knife's shapes below are drawn round its hilt,
## with the blade pointing along positive x.
const _KNIFE_HILT := Vector2(101.0, -24.0)
const _KNIFE_ANGLE := -60.0
## The handle, gripped across the fist.
const _HANDLE := Rect2(-26.0, -5.0, 24.0, 10.0)
const _HANDLE_CORNER := 4.0
## The guard between the handle and the blade.
const _GUARD := [Vector2(0.0, -10.0), Vector2(0.0, 10.0)]
## The blade, from the spine at the hilt out to its point and back along its curved edge.
const _BLADE := [Vector2(2.0, -5.0), Vector2(38.0, -5.0), Vector2(52.0, -4.0), Vector2(32.0, 5.0), Vector2(2.0, 6.0)]


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(knife_role)
	var lines := super._build_lines(style, palette)
	var blade_corners := _knife_space(PackedVector2Array(_BLADE))
	blade_corners.append(blade_corners[0])
	var blade := InkLine.along(InkBrush.resample_polyline(blade_corners, spacing * 0.5), color, 0.8, true)
	blade.fill = palette.paper
	lines.append(blade)
	var handle := InkLine.along(_knife_space(InkBrush.rounded_rect(_HANDLE, _HANDLE_CORNER, spacing * 0.5)), color, 0.8, true)
	handle.fill = palette.paper.lerp(color, wash_strength)
	lines.append(handle)
	lines.append(InkLine.along(InkBrush.resample_polyline(_knife_space(PackedVector2Array(_GUARD)), spacing * 0.5), color, 0.9))
	return lines


## [param points] drawn round the knife's hilt, turned the way its blade points.
static func _knife_space(points: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	var turn := deg_to_rad(_KNIFE_ANGLE)
	for point in points:
		out.append(_KNIFE_HILT + point.rotated(turn))
	return out
