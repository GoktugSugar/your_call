@tool
class_name LyingDog
extends InkDrawing
## A doodle: a dog that only lies to you. A brown dog stands side on, facing left, head up and eager:
## a long snout, one floppy ear, a dot eye, four legs, and its tail up and wagging, with a stroke of
## motion either side of it. Brown washes fill it, the far legs behind the near ones. Its origin is the
## ground under its middle.

## How big the dog is drawn, as a multiple of its natural size.
@export_range(0.2, 3.0, 0.01) var dog_scale := 1.0:
	set(value):
		dog_scale = value
		queue_redraw()
## Palette role of the line.
@export var line_role := &"brown":
	set(value):
		line_role = value
		queue_redraw()
## How strongly each wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()
## Radius of the dot eye.
@export_range(0.5, 10.0, 0.1) var eye_radius := 3.4:
	set(value):
		eye_radius = value
		queue_redraw()
## Thickness of each leg, at natural size.
@export_range(2.0, 40.0, 0.5) var leg_width := 19.0:
	set(value):
		leg_width = value
		queue_redraw()
## Thickness of the tail where it leaves the body, at natural size.
@export_range(2.0, 40.0, 0.5) var tail_width := 16.0:
	set(value):
		tail_width = value
		queue_redraw()

## The middle of each leg at natural size, hip to paw, the far ones first so the near ones cover them:
## far front, far hind, the near front lifted eagerly, near hind. The body hides their tops, and each
## paw is the round end of its leg.
const _LEGS := [[Vector2(-12.0, -74.0), Vector2(-16.0, -38.0), Vector2(-18.0, -9.5)],
		[Vector2(52.0, -76.0), Vector2(56.0, -42.0), Vector2(48.0, -9.5)],
		[Vector2(-36.0, -78.0), Vector2(-44.0, -50.0), Vector2(-60.0, -38.0)],
		[Vector2(80.0, -80.0), Vector2(90.0, -46.0), Vector2(84.0, -9.5)]]
## The middle of the tail, from under the rump up to its tip.
const _TAIL := [Vector2(92.0, -104.0), Vector2(106.0, -128.0), Vector2(114.0, -154.0), Vector2(108.0, -180.0)]
## How thick the tail is at its tip, as a fraction of [member tail_width].
const _TAIL_TIP := 0.45
## The body and neck, from the throat down the chest, along the belly, round the rump, along the back
## and up the back of the neck. The head hides its top.
const _BODY := [Vector2(-48.0, -130.0), Vector2(-58.0, -106.0), Vector2(-50.0, -80.0), Vector2(-28.0, -68.0),
		Vector2(18.0, -64.0), Vector2(60.0, -68.0), Vector2(84.0, -74.0), Vector2(100.0, -92.0), Vector2(92.0, -112.0),
		Vector2(64.0, -120.0), Vector2(22.0, -116.0), Vector2(-8.0, -122.0), Vector2(-22.0, -142.0), Vector2(-38.0, -156.0)]
## The head, from the top of the skull forward down the brow, round the snout, back under the jaw and
## up the back of the head.
const _HEAD := [Vector2(-56.0, -198.0), Vector2(-80.0, -192.0), Vector2(-92.0, -177.0), Vector2(-110.0, -177.0),
		Vector2(-124.0, -172.0), Vector2(-127.0, -159.0), Vector2(-113.0, -150.0), Vector2(-86.0, -142.0),
		Vector2(-64.0, -134.0), Vector2(-38.0, -142.0), Vector2(-28.0, -164.0), Vector2(-34.0, -188.0)]
## The floppy ear, hanging from the top of the head down behind the eye.
const _EAR := [Vector2(-52.0, -196.0), Vector2(-34.0, -190.0), Vector2(-26.0, -166.0), Vector2(-28.0, -142.0),
		Vector2(-38.0, -132.0), Vector2(-48.0, -140.0), Vector2(-52.0, -164.0), Vector2(-58.0, -186.0)]
const _EYE := Vector2(-78.0, -170.0)
## A curved stroke of motion either side of the tail's tip: where each starts and ends, in degrees
## round the tip from the way the tail points, clockwise positive.
const _WAG := [[35.0, 105.0], [-35.0, -105.0]]
## Gap between the tail's tip and its strokes of motion.
const _WAG_GAP := 12.0
## Points per stroke of motion, before it is smoothed.
const _WAG_POINTS := 5


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(line_role)
	var wash := palette.paper.lerp(color, wash_strength)
	var lines: Array[InkLine] = []
	for leg: Array in _LEGS:
		lines.append(_washed(_band(_scaled(leg), leg_width * dog_scale, 1.0, spacing), color, wash, false))
	lines.append(_washed(_band(_scaled(_TAIL), tail_width * dog_scale, _TAIL_TIP, spacing), color, wash, false))
	var tip: Vector2 = _TAIL[-1]
	var reach := (tip - _TAIL[-2] as Vector2).normalized() * (tail_width * _TAIL_TIP * 0.5 + _WAG_GAP)
	for swing: Array in _WAG:
		var arc: Array[Vector2] = []
		for i in _WAG_POINTS:
			arc.append(tip + reach.rotated(deg_to_rad(lerpf(swing[0], swing[1], float(i) / (_WAG_POINTS - 1)))))
		lines.append(InkLine.along(InkBrush.resample_smooth(_scaled(arc), false, spacing), color, 0.8))
	lines.append(_washed(InkBrush.resample_smooth(_scaled(_BODY), true, spacing), color, wash, true))
	lines.append(_washed(InkBrush.resample_smooth(_scaled(_HEAD), true, spacing), color, wash, true))
	lines.append(_washed(InkBrush.resample_smooth(_scaled(_EAR), true, spacing), color, wash, true))
	lines.append(InkLine.dot(_EYE * dog_scale, eye_radius, palette.ink))
	return lines


## A line along [param path] with [param wash] inside it.
static func _washed(path: PackedVector2Array, color: Color, wash: Color, closed: bool) -> InkLine:
	var line := InkLine.along(path, color, 1.0, closed)
	line.fill = wash
	return line


## The outline of a band [param width] wide along the smooth [param spine], narrowing to
## [param tip_share] of that at its far end, which is capped round: out along one side, round the tip
## and back along the other. Its near end is left open.
static func _band(spine: PackedVector2Array, width: float, tip_share: float, spacing: float) -> PackedVector2Array:
	var middle := InkBrush.resample_smooth(spine, false, spacing)
	var n := middle.size()
	var near_side := PackedVector2Array()
	var far_side := PackedVector2Array()
	var tangent := Vector2.RIGHT
	var half := width * 0.5
	for i in n:
		tangent = (middle[mini(i + 1, n - 1)] - middle[maxi(i - 1, 0)]).normalized()
		half = width * 0.5 * lerpf(1.0, tip_share, float(i) / (n - 1))
		near_side.append(middle[i] + tangent.orthogonal() * half)
		far_side.append(middle[i] - tangent.orthogonal() * half)
	var cap_steps := maxi(2, ceili(PI * half / spacing))
	for k in range(1, cap_steps):
		var angle := PI * k / cap_steps
		near_side.append(middle[n - 1] + (tangent.orthogonal() * cos(angle) + tangent * sin(angle)) * half)
	far_side.reverse()
	near_side.append_array(far_side)
	return near_side


func _scaled(points: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point: Vector2 in points:
		out.append(point * dog_scale)
	return out
