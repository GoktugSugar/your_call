@tool
class_name HouseCat
extends InkDrawing
## A doodle: a house cat, standing side on and facing right with its tail up. One sky blue outline
## runs along its back, over its head and its two pointed ears and round its chest and belly, with a
## wash inside; its tail rises from its rump in a curl, it stands on four slim legs and it has a single
## dot eye. Many of them stand in for a crowd. Its origin is the ground under its middle.

## Palette role of its line.
@export var role := &"sky":
	set(value):
		role = value
		queue_redraw()
## How strongly the wash inside its body and legs takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()
## Radius of the dot eye.
@export_range(0.5, 10.0, 0.1) var eye_radius := 3.4:
	set(value):
		eye_radius = value
		queue_redraw()

## The outline, from the root of the tail along the back, up the back of the head, over both ears and
## down the face, and back under the chin, down the chest, along the belly and round the rump.
const _OUTLINE := [Vector2(-67.0, -92.0), Vector2(-35.0, -100.0), Vector2(-1.0, -100.0), Vector2(29.0, -102.0),
		Vector2(45.0, -114.0), Vector2(47.0, -134.0), Vector2(51.0, -160.0), Vector2(67.0, -148.0),
		Vector2(87.0, -164.0), Vector2(95.0, -140.0), Vector2(101.0, -122.0), Vector2(95.0, -104.0),
		Vector2(81.0, -96.0), Vector2(67.0, -86.0), Vector2(59.0, -62.0), Vector2(35.0, -52.0),
		Vector2(-5.0, -50.0), Vector2(-41.0, -52.0), Vector2(-65.0, -58.0), Vector2(-77.0, -74.0)]
## The tail, from its root up into a curl.
const _TAIL := [Vector2(-69.0, -90.0), Vector2(-89.0, -108.0), Vector2(-99.0, -138.0), Vector2(-95.0, -166.0),
		Vector2(-83.0, -180.0), Vector2(-69.0, -180.0)]
## The legs, each from inside the body down to the ground: the far foreleg and far hind leg first,
## then the near ones, which stand a little in front of them.
const _LEGS := [Rect2(31.0, -56.0, 14.0, 56.0), Rect2(-77.0, -62.0, 14.0, 62.0), Rect2(45.0, -60.0, 14.0, 60.0),
		Rect2(-63.0, -58.0, 14.0, 58.0)]
## How round the ends of the legs are.
const _LEG_ROUNDING := 7.0
const _EYE := Vector2(83.0, -126.0)
## Width of the tail's line, as a multiple of the line's width.
const _TAIL_WIDTH := 1.4


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var wash := palette.paper.lerp(color, wash_strength)
	var lines: Array[InkLine] = []
	# The legs and the tail come first, so the body's wash hides where they join it.
	for leg: Rect2 in _LEGS:
		var outline := InkLine.along(InkBrush.rounded_rect(leg, _LEG_ROUNDING, spacing), color, 0.9, true)
		outline.fill = wash
		lines.append(outline)
	lines.append(InkLine.along(InkBrush.resample_smooth(PackedVector2Array(_TAIL), false, spacing), color, _TAIL_WIDTH))
	var body := InkLine.along(InkBrush.resample_smooth(PackedVector2Array(_OUTLINE), true, spacing), color, 1.0, true)
	body.fill = wash
	lines.append(body)
	lines.append(InkLine.dot(_EYE, eye_radius, palette.ink))
	return lines
