@tool
class_name SweetPoop
extends InkDrawing
## A doodle: a poop coiled like soft serve, the shit that tastes like ice cream. Brown line, a brown
## wash inside. Its swirl is shared with [FoulIceCream], whose scoop is the same shape.
## Its origin is the middle of its base.

## How big the swirl is drawn, as a multiple of its natural size.
@export_range(0.2, 3.0, 0.01) var swirl_scale := 1.35:
	set(value):
		swirl_scale = value
		queue_redraw()
## Palette role of the line.
@export var line_role := &"brown":
	set(value):
		line_role = value
		queue_redraw()
## How strongly the wash inside takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()

## The swirl's silhouette at natural size, standing on the origin, going round from the base.
const _OUTLINE := [Vector2(-70.0, -6.0), Vector2(-72.0, -26.0), Vector2(-56.0, -44.0), Vector2(-58.0, -60.0),
		Vector2(-42.0, -76.0), Vector2(-38.0, -92.0), Vector2(-20.0, -106.0), Vector2(-4.0, -118.0),
		Vector2(4.0, -134.0), Vector2(12.0, -121.0), Vector2(22.0, -106.0), Vector2(40.0, -92.0),
		Vector2(44.0, -76.0), Vector2(60.0, -60.0), Vector2(58.0, -44.0), Vector2(74.0, -26.0),
		Vector2(70.0, -6.0), Vector2(36.0, 0.0), Vector2(-36.0, 0.0)]
## The creases between the swirl's tiers, bottom to top.
const _TIERS := [
	[Vector2(-56.0, -44.0), Vector2(-28.0, -38.0), Vector2(4.0, -37.0), Vector2(34.0, -39.0), Vector2(58.0, -44.0)],
	[Vector2(-42.0, -76.0), Vector2(-16.0, -70.0), Vector2(12.0, -70.0), Vector2(44.0, -76.0)],
	[Vector2(-20.0, -106.0), Vector2(2.0, -101.0), Vector2(22.0, -106.0)],
]


## The lines of a soft serve swirl drawn [param size] times its natural size and standing on
## [param base], in [param color], with an opaque [param wash] inside so it hides whatever is behind it.
static func swirl_lines(base: Vector2, size: float, color: Color, wash: Color, spacing: float) -> Array[InkLine]:
	var lines: Array[InkLine] = []
	var outline := InkLine.along(InkBrush.resample_smooth(_placed(_OUTLINE, base, size), true, spacing), color, 1.0, true)
	outline.fill = wash
	lines.append(outline)
	for tier: Array in _TIERS:
		lines.append(InkLine.along(InkBrush.resample_smooth(_placed(tier, base, size), false, spacing), color, 0.8))
	return lines


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var color := palette.color(line_role)
	return swirl_lines(Vector2.ZERO, swirl_scale, color, palette.paper.lerp(color, wash_strength), style.sample_spacing)


static func _placed(points: Array, base: Vector2, size: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point: Vector2 in points:
		out.append(base + point * size)
	return out
