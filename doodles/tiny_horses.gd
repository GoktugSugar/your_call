@tool
class_name TinyHorses
extends InkDrawing
## A doodle: a herd of tiny horses, the size of ducks. A dozen small brown horses in three staggered
## rows stand in for the hundred; the words around them carry the count. Each has a dot eye and a
## wash inside its outline, so the ones in front hide the ones behind. Its origin is the ground under
## the herd's middle.

## How big each horse is drawn, as a multiple of its natural size.
@export_range(0.2, 4.0, 0.01) var horse_scale := 1.25:
	set(value):
		horse_scale = value
		queue_redraw()
## Palette role of the horses' lines.
@export var line_role := &"brown":
	set(value):
		line_role = value
		queue_redraw()
## How strongly each horse's wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.4:
	set(value):
		wash_strength = value
		queue_redraw()
## Radius of each dot eye.
@export_range(0.3, 6.0, 0.1) var eye_radius := 1.8:
	set(value):
		eye_radius = value
		queue_redraw()
## How much smaller each row back is, as a fraction of the row in front.
@export_range(0.5, 1.0, 0.01) var row_shrink := 0.88:
	set(value):
		row_shrink = value
		queue_redraw()

## The herd in rows, back row first: each horse's feet, at natural size, and whether it faces left.
const _HERD := [
	[[Vector2(-102.0, -74.0), false], [Vector2(-36.0, -78.0), true], [Vector2(30.0, -75.0), false], [Vector2(96.0, -77.0), false]],
	[[Vector2(-128.0, -38.0), false], [Vector2(-64.0, -36.0), false], [Vector2(0.0, -40.0), true], [Vector2(64.0, -37.0), false],
			[Vector2(126.0, -39.0), true]],
	[[Vector2(-78.0, 0.0), false], [Vector2(6.0, -2.0), false], [Vector2(84.0, 0.0), true]],
]

## One horse at natural size, facing right and standing on its own origin: its outline runs from the
## top of its rump along its back, up its neck, over its ear and down its face, and back under its
## chin and along its belly.
const _OUTLINE := [Vector2(-17.0, -27.0), Vector2(-6.0, -29.0), Vector2(7.0, -29.0), Vector2(13.0, -35.0),
		Vector2(17.0, -43.0), Vector2(19.0, -49.0), Vector2(22.0, -45.0), Vector2(29.0, -39.0), Vector2(32.0, -33.0),
		Vector2(28.0, -31.0), Vector2(22.0, -35.0), Vector2(18.0, -28.0), Vector2(16.0, -21.0), Vector2(9.0, -17.0),
		Vector2(-8.0, -17.0), Vector2(-17.0, -19.0), Vector2(-20.0, -23.0)]
const _LEGS := [[Vector2(-15.0, -19.0), Vector2(-16.0, 0.0)], [Vector2(-10.0, -18.0), Vector2(-10.0, 0.0)],
		[Vector2(7.0, -18.0), Vector2(6.0, 0.0)], [Vector2(12.0, -19.0), Vector2(12.0, 0.0)]]
const _TAIL := [Vector2(-18.0, -26.0), Vector2(-24.0, -21.0), Vector2(-24.0, -11.0)]
const _EYE := Vector2(23.0, -41.0)


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(line_role)
	var wash := palette.paper.lerp(color, wash_strength)
	var lines: Array[InkLine] = []
	for row in _HERD.size():
		var size := horse_scale * pow(row_shrink, _HERD.size() - 1 - row)
		for horse: Array in _HERD[row]:
			var feet: Vector2 = horse[0] * horse_scale
			lines.append_array(_horse(feet, size, -1.0 if horse[1] else 1.0, color, wash, palette.ink, spacing))
	return lines


## One horse's lines: legs and tail behind, then its washed outline and its eye.
func _horse(feet: Vector2, size: float, facing: float, color: Color, wash: Color, eye: Color, spacing: float) -> Array[InkLine]:
	var lines: Array[InkLine] = []
	for leg: Array in _LEGS:
		lines.append(InkLine.along(InkBrush.resample_polyline(_placed(leg, feet, size, facing), spacing), color, 0.8))
	lines.append(InkLine.along(InkBrush.resample_smooth(_placed(_TAIL, feet, size, facing), false, spacing), color, 0.8))
	var outline := InkLine.along(InkBrush.resample_smooth(_placed(_OUTLINE, feet, size, facing), true, spacing), color, 0.9, true)
	outline.fill = wash
	lines.append(outline)
	lines.append(InkLine.dot(feet + Vector2(_EYE.x * facing, _EYE.y) * size, eye_radius, eye))
	return lines


## [param points] of a horse drawn [param size] times its natural size, standing on [param feet] and
## facing right ([code]1[/code]) or left ([code]-1[/code]).
static func _placed(points: Array, feet: Vector2, size: float, facing: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point: Vector2 in points:
		out.append(feet + Vector2(point.x * facing, point.y) * size)
	return out
