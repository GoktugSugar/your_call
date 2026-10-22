@tool
class_name CharityHand
extends InkDrawing
## A doodle: a hand held out palm up, offering a small heart, for ending poverty. The hand comes out of
## a cuff on the left with its thumb raised, its fingers reaching right with their tips curled up, and
## the heart rests on it between the thumb and the fingertips with its point tucked behind the hand.
## All of it is gold, with a gold wash inside each line. Its origin is the ground under the hand's middle.

## How big the hand and its heart are drawn, as a multiple of their natural size.
@export_range(0.2, 3.0, 0.01) var hand_scale := 1.0:
	set(value):
		hand_scale = value
		queue_redraw()
## Palette role of every line.
@export var role := &"gold":
	set(value):
		role = value
		queue_redraw()
## How strongly the hand's and the cuff's wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()
## How strongly the heart's wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var heart_wash := 0.6:
	set(value):
		heart_wash = value
		queue_redraw()

## The hand's outline at natural size, in smooth pieces that meet at sharp corners where the fingertips
## part: from the top of the wrist inside the cuff, up over the thumb and along the first finger to its
## tip, round each of the other fingertips in turn, and back along the underside to the wrist.
const _HAND := [
	[Vector2(-124.0, -80.0), Vector2(-100.0, -83.0), Vector2(-84.0, -90.0), Vector2(-72.0, -106.0),
			Vector2(-62.0, -124.0), Vector2(-51.0, -137.0), Vector2(-37.0, -138.0), Vector2(-30.0, -127.0),
			Vector2(-30.0, -112.0), Vector2(-22.0, -98.0), Vector2(0.0, -93.0), Vector2(40.0, -91.0), Vector2(78.0, -95.0),
			Vector2(106.0, -104.0), Vector2(124.0, -110.0), Vector2(136.0, -102.0), Vector2(134.0, -92.0),
			Vector2(124.0, -87.0)],
	[Vector2(124.0, -87.0), Vector2(138.0, -82.0), Vector2(140.0, -70.0), Vector2(126.0, -64.0)],
	[Vector2(126.0, -64.0), Vector2(138.0, -58.0), Vector2(136.0, -46.0), Vector2(122.0, -42.0)],
	[Vector2(122.0, -42.0), Vector2(130.0, -34.0), Vector2(122.0, -25.0), Vector2(100.0, -21.0),
			Vector2(40.0, -21.0), Vector2(-40.0, -27.0), Vector2(-100.0, -39.0), Vector2(-124.0, -44.0)],
]
## Where the fingers part, each running back from between two fingertips.
const _PARTINGS := [[Vector2(124.0, -87.0), Vector2(96.0, -84.0), Vector2(64.0, -84.0)],
		[Vector2(126.0, -64.0), Vector2(96.0, -63.0), Vector2(66.0, -64.0)],
		[Vector2(122.0, -42.0), Vector2(98.0, -42.0), Vector2(72.0, -44.0)]]
## The cuff the wrist comes out of, at natural size.
const _CUFF := Rect2(-146.0, -96.0, 30.0, 64.0)
## Radius of the cuff's rounded corners.
const _CUFF_CORNER := 8.0
## Where the heart's point rests, tucked behind the hand.
const _HEART_POINT := Vector2(52.0, -86.0)
## The heart's left half, from its point up round the left lobe to the dip between the lobes,
## relative to the point. The right half mirrors it.
const _HEART_HALF := [Vector2(0.0, 0.0), Vector2(-24.0, -26.0), Vector2(-46.0, -56.0), Vector2(-54.0, -86.0),
		Vector2(-46.0, -110.0), Vector2(-28.0, -120.0), Vector2(-10.0, -114.0), Vector2(0.0, -100.0)]


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var wash := palette.paper.lerp(color, wash_strength)
	var lines: Array[InkLine] = []
	# The heart comes first, so the hand hides its point.
	lines.append(_washed(_heart(spacing), color, palette.paper.lerp(color, heart_wash)))
	# The hand's line stops at the wrist, whose open end the cuff covers.
	var hand := PackedVector2Array()
	for piece: Array in _HAND:
		var path := InkBrush.resample_smooth(_scaled(piece), false, spacing)
		hand.append_array(path if hand.is_empty() else path.slice(1))
	var outline := InkLine.along(hand, color)
	outline.fill = wash
	lines.append(outline)
	for parting: Array in _PARTINGS:
		lines.append(InkLine.along(InkBrush.resample_smooth(_scaled(parting), false, spacing), color, 0.8))
	var cuff := Rect2(_CUFF.position * hand_scale, _CUFF.size * hand_scale)
	lines.append(_washed(InkBrush.rounded_rect(cuff, _CUFF_CORNER * hand_scale, spacing), color, wash))
	return lines


## The heart's outline: its left half up from the point to the dip, then the mirrored right half back
## down, each a smooth curve of its own so the point and the dip stay sharp.
func _heart(spacing: float) -> PackedVector2Array:
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for point: Vector2 in _HEART_HALF:
		left.append((_HEART_POINT + point) * hand_scale)
		right.append((_HEART_POINT + Vector2(-point.x, point.y)) * hand_scale)
	right.reverse()
	var path := InkBrush.resample_smooth(left, false, spacing)
	path.append_array(InkBrush.resample_smooth(right, false, spacing).slice(1))
	return path


## A closed line along [param path] with [param wash] inside.
static func _washed(path: PackedVector2Array, color: Color, wash: Color) -> InkLine:
	var line := InkLine.along(path, color, 1.0, true)
	line.fill = wash
	return line


func _scaled(points: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point: Vector2 in points:
		out.append(point * hand_scale)
	return out
