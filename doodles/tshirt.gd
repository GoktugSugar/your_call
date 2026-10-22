@tool
class_name Tshirt
extends InkDrawing
## A doodle: a shirt that never stains. A blue T shirt laid flat and seen from the front: short
## sleeves, a seam where each sleeve meets the body, and a round neck, its front dipping below the back
## with a band of rib round it. A blue wash fills it. Its origin is the ground under the middle of its
## hem.

## How big the shirt is drawn, as a multiple of its natural size.
@export_range(0.2, 3.0, 0.01) var shirt_scale := 1.0:
	set(value):
		shirt_scale = value
		queue_redraw()
## Palette role of the line.
@export var line_role := &"blue":
	set(value):
		line_role = value
		queue_redraw()
## How strongly the wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()

## The right half of the shirt's outline at natural size, in runs that meet in its corners: from the
## middle of the back of the neck along the shoulder, out along the sleeve, across its cuff and back
## under it, then down the side to the middle of the hem. The left half mirrors it.
const _OUTLINE := [
	[Vector2(0.0, -190.0), Vector2(16.0, -191.0), Vector2(30.0, -196.0)],
	[Vector2(30.0, -196.0), Vector2(72.0, -184.0)],
	[Vector2(72.0, -184.0), Vector2(92.0, -170.0), Vector2(112.0, -152.0)],
	[Vector2(112.0, -152.0), Vector2(94.0, -128.0)],
	[Vector2(94.0, -128.0), Vector2(68.0, -140.0)],
	[Vector2(68.0, -140.0), Vector2(65.0, -70.0), Vector2(70.0, 0.0)],
	[Vector2(70.0, 0.0), Vector2(0.0, 0.0)],
]
## The front of the neck, dipping from one shoulder to the other.
const _NECK := [Vector2(-30.0, -196.0), Vector2(-22.0, -180.0), Vector2(0.0, -170.0), Vector2(22.0, -180.0),
		Vector2(30.0, -196.0)]
## The lower edge of the rib round the neck.
const _RIB := [Vector2(-39.0, -193.0), Vector2(-29.0, -173.0), Vector2(0.0, -161.0), Vector2(29.0, -173.0),
		Vector2(39.0, -193.0)]
## The seam where the right sleeve meets the body, shoulder to armpit; the left mirrors it.
const _SEAM := [Vector2(72.0, -184.0), Vector2(67.0, -162.0), Vector2(68.0, -140.0)]


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(line_role)
	var outline := PackedVector2Array()
	for side: float in [1.0, -1.0]:
		var half := PackedVector2Array()
		for run: Array in _OUTLINE:
			var part := InkBrush.resample_smooth(_scaled(run, side), false, spacing)
			half.append_array(part if half.is_empty() else part.slice(1))
		if side < 0.0:
			half.reverse()
		outline.append_array(half if outline.is_empty() else half.slice(1))
	var shirt := InkLine.along(outline, color, 1.0, true)
	shirt.fill = palette.paper.lerp(color, wash_strength)
	var lines: Array[InkLine] = [shirt]
	for side: float in [1.0, -1.0]:
		lines.append(InkLine.along(InkBrush.resample_smooth(_scaled(_SEAM, side), false, spacing), color, 0.7))
	lines.append(InkLine.along(InkBrush.resample_smooth(_scaled(_NECK, 1.0), false, spacing), color))
	lines.append(InkLine.along(InkBrush.resample_smooth(_scaled(_RIB, 1.0), false, spacing), color, 0.7))
	return lines


## [param points] at natural size, mirrored about the middle when [param side] is [code]-1[/code], and scaled.
func _scaled(points: Array, side: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point: Vector2 in points:
		out.append(Vector2(point.x * side, point.y) * shirt_scale)
	return out
