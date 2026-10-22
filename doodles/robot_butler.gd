@tool
class_name RobotButler
extends InkDrawing
## A doodle: a robot butler that judges you in complete silence. A boxy sky blue robot standing bolt
## upright and facing out, a square head on a box of a body, each with a sky wash, an antenna with a
## ball on top, two dot eyes, a little ink bow tie and three buttons down its front. One arm hangs
## stiffly at its side; the other is bent to hold out a tray with a covered dish on it. It stands a little left of its origin, so that
## it and its tray together are centred on it. Its origin is the ground under it.

## Palette role of its line.
@export var role := &"sky":
	set(value):
		role = value
		queue_redraw()
## How strongly each wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()
## How strongly the bow tie's wash takes the ink over the paper.
@export_range(0.0, 1.0, 0.01) var tie_wash := 0.6:
	set(value):
		tie_wash = value
		queue_redraw()
## Radius of each dot eye.
@export_range(0.5, 8.0, 0.1) var eye_radius := 3.2:
	set(value):
		eye_radius = value
		queue_redraw()

## The robot at natural size, with its middle on the origin: it is moved over by [constant _SHIFT] as
## it is drawn.
const _HEAD := Rect2(-30.0, -196.0, 60.0, 48.0)
const _BODY := Rect2(-38.0, -140.0, 76.0, 80.0)
## How round the corners of the head and body are.
const _CORNER := 7.0
const _NECK := [Vector2(0.0, -148.0), Vector2(0.0, -140.0)]
const _ANTENNA := [Vector2(0.0, -196.0), Vector2(0.0, -214.0)]
const _ANTENNA_BALL := Vector2(0.0, -220.0)
const _ANTENNA_BALL_RADIUS := 6.0
const _EYES := [Vector2(-11.0, -174.0), Vector2(11.0, -174.0)]
## The screen left leg, hip to foot; the right mirrors it.
const _LEG := [Vector2(-16.0, -62.0), Vector2(-16.0, -12.0)]
## The screen left foot; the right mirrors it.
const _FOOT := Rect2(-30.0, -13.0, 26.0, 13.0)
const _FOOT_CORNER := 5.0
## The arm hanging at its side, shoulder to elbow to hand.
const _HANGING_ARM := [Vector2(-38.0, -130.0), Vector2(-46.0, -100.0), Vector2(-48.0, -74.0)]
## The arm holding out the tray, shoulder to elbow to hand.
const _TRAY_ARM := [Vector2(38.0, -130.0), Vector2(62.0, -100.0), Vector2(86.0, -120.0)]
const _HAND_RADIUS := 5.0
## The tray, flat on the hand, and the covered dish on it: the dish's two feet and its top, and the
## little knob on top of it.
const _TRAY := Rect2(56.0, -131.0, 62.0, 6.0)
const _DISH := [Vector2(68.0, -131.0), Vector2(70.0, -146.0), Vector2(87.0, -156.0), Vector2(104.0, -146.0),
		Vector2(106.0, -131.0)]
const _KNOB := Vector2(87.0, -160.0)
const _KNOB_RADIUS := 4.0
## The bow tie, from the knot out to its two corners on the screen left side; the right mirrors it.
const _TIE := [Vector2(0.0, -132.0), Vector2(-16.0, -141.0), Vector2(-16.0, -123.0)]
const _KNOT_RADIUS := 4.0
## The buttons down the front of its body, under the bow tie, and their radius.
const _BUTTONS := [Vector2(0.0, -110.0), Vector2(0.0, -94.0), Vector2(0.0, -78.0)]
const _BUTTON_RADIUS := 3.5
## How far the whole robot is moved, so that it and its tray together are centred on the origin.
const _SHIFT := Vector2(-35.0, 0.0)


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var wash := palette.paper.lerp(color, wash_strength)
	var ink := palette.ink
	var lines: Array[InkLine] = []
	for side: float in [1.0, -1.0]:
		lines.append(InkLine.along(InkBrush.resample_polyline(_placed(_LEG, side), spacing), color))
		var foot := _moved(_FOOT)
		if side < 0.0:
			foot.position.x = _SHIFT.x - _FOOT.end.x
		lines.append(_washed(InkBrush.rounded_rect(foot, _FOOT_CORNER, spacing), color, wash, 0.9))
	lines.append(InkLine.along(InkBrush.resample_polyline(_placed(_NECK, 1.0), spacing), color))
	lines.append(InkLine.along(InkBrush.resample_polyline(_placed(_ANTENNA, 1.0), spacing), color, 0.8))
	lines.append(_washed(InkBrush.ellipse(_ANTENNA_BALL + _SHIFT, Vector2.ONE * _ANTENNA_BALL_RADIUS, spacing * 0.5), color, wash, 0.8))
	for arm: Array in [_HANGING_ARM, _TRAY_ARM]:
		lines.append(InkLine.along(InkBrush.resample_polyline(_placed(arm, 1.0), spacing), color))
	lines.append(_washed(InkBrush.rounded_rect(_moved(_BODY), _CORNER, spacing), color, wash))
	lines.append(_washed(InkBrush.rounded_rect(_moved(_HEAD), _CORNER, spacing), color, wash))
	for button: Vector2 in _BUTTONS:
		lines.append(_washed(InkBrush.ellipse(button + _SHIFT, Vector2.ONE * _BUTTON_RADIUS, spacing * 0.5), color, palette.paper, 0.7))
	for side: float in [1.0, -1.0]:
		lines.append(_washed(InkBrush.resample_polyline(_closed(_placed(_TIE, side)), spacing), ink,
				palette.paper.lerp(ink, tie_wash), 0.7))
	var knot: Vector2 = _TIE[0]
	lines.append(_washed(InkBrush.ellipse(knot + _SHIFT, Vector2.ONE * _KNOT_RADIUS, spacing * 0.5), ink, ink, 0.7))
	lines.append(_washed(InkBrush.resample_smooth(_placed(_DISH, 1.0), true, spacing), color, wash, 0.9))
	lines.append(_washed(InkBrush.ellipse(_KNOB + _SHIFT, Vector2.ONE * _KNOB_RADIUS, spacing * 0.5), color, wash, 0.8))
	lines.append(_washed(InkBrush.rounded_rect(_moved(_TRAY), _TRAY.size.y * 0.5, spacing), color, wash, 0.9))
	for arm: Array in [_HANGING_ARM, _TRAY_ARM]:
		var hand: Vector2 = arm[arm.size() - 1]
		lines.append(_washed(InkBrush.ellipse(hand + _SHIFT, Vector2.ONE * _HAND_RADIUS, spacing * 0.5), color, wash, 0.9))
	for eye: Vector2 in _EYES:
		lines.append(InkLine.dot(eye + _SHIFT, eye_radius, ink))
	return lines


## A closed line along [param path] with [param wash] inside.
static func _washed(path: PackedVector2Array, color: Color, wash: Color, width := 1.0) -> InkLine:
	var line := InkLine.along(path, color, width, true)
	line.fill = wash
	return line


static func _moved(rect: Rect2) -> Rect2:
	return Rect2(rect.position + _SHIFT, rect.size)


## [param points] mirrored about the robot's middle when [param side] is [code]-1[/code], then moved by [constant _SHIFT].
static func _placed(points: Array, side: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point: Vector2 in points:
		out.append(Vector2(point.x * side, point.y) + _SHIFT)
	return out


## [param corners] with the first repeated at the end, to draw them as a closed polyline.
static func _closed(corners: PackedVector2Array) -> PackedVector2Array:
	var out := corners.duplicate()
	out.append(corners[0])
	return out
