@tool
class_name Bear
extends Soul
## The last bear, the last female of her kind still able to breed. She sits up facing the player: a
## rounded body, short arms hanging at her sides, two round feet out in front, and a round head whose
## ears are open bumps on its outline, never circles laid on top. Dot eyes, and a tiny smile on a lighter
## muzzle. She is filled solid brown, the one solid fill in the game. She breathes, stepped with the boil.
## Shot, she topples over sideways about the outer edge of her feet, lands with a slight settle and
## dissolves. Her origin is the ground under her middle.

## Points the smile's curve is laid through before it is smoothed.
const _SMILE_POINTS := 5
## Where round the head its outline starts and ends, in radians clockwise from the screen right: low on
## the screen left, where the pen's overlap lies over the body.
const _HEAD_START := PI * 0.75

@export_group("Body")
## Width and height of the body, which sits on the ground.
@export var body_size := Vector2(88.0, 78.0):
	set(value):
		body_size = value
		queue_redraw()
## How much fuller the body is toward the bottom than toward the top, as a share of its width.
@export_range(0.0, 0.5, 0.01) var body_flare := 0.14:
	set(value):
		body_flare = value
		queue_redraw()
## Radius of the head.
@export_range(5.0, 80.0, 0.5) var head_radius := 28.0:
	set(value):
		head_radius = value
		queue_redraw()
## How high the middle of the head sits above the ground.
@export_range(10.0, 300.0, 0.5) var head_height := 96.0:
	set(value):
		head_height = value
		queue_redraw()
## Radius of each ear.
@export_range(1.0, 40.0, 0.5) var ear_radius := 10.0:
	set(value):
		ear_radius = value
		queue_redraw()
## Where each ear sits round the head, in degrees either side of its top.
@export_range(0.0, 90.0, 0.5) var ear_angle := 40.0:
	set(value):
		ear_angle = value
		queue_redraw()
## How far out from the middle of the head each ear's middle sits, as a share of the head's radius.
## Under 1 the ear's middle is inside the head, so only a bump of the ear shows on the outline.
@export_range(0.5, 1.2, 0.01) var ear_reach := 0.92:
	set(value):
		ear_reach = value
		queue_redraw()
## Thickness and length of each arm, shoulder to paw.
@export var arm_size := Vector2(17.0, 36.0):
	set(value):
		arm_size = value
		queue_redraw()
## How high above the ground each arm leaves the side of the body.
@export_range(0.0, 200.0, 0.5) var shoulder_height := 58.0:
	set(value):
		shoulder_height = value
		queue_redraw()
## How far each arm swings out from hanging straight down, in degrees.
@export_range(-45.0, 90.0, 0.5) var arm_swing := 12.0:
	set(value):
		arm_swing = value
		queue_redraw()
## Width and height of each foot.
@export var foot_size := Vector2(30.0, 21.0):
	set(value):
		foot_size = value
		queue_redraw()
## How far out from the middle each foot sits.
@export_range(0.0, 80.0, 0.5) var foot_spread := 25.0:
	set(value):
		foot_spread = value
		queue_redraw()
## Gap between the top of the head and anything floating over it, in pixels.
@export_range(0.0, 80.0, 0.5) var float_gap := 12.0

@export_group("Face")
## Radius of each dot eye.
@export_range(0.5, 8.0, 0.1) var eye_radius := 3.2:
	set(value):
		eye_radius = value
		queue_redraw()
## How far each eye sits from the middle of the face.
@export_range(0.0, 30.0, 0.1) var eye_spread := 10.5:
	set(value):
		eye_spread = value
		queue_redraw()
## How far above the middle of the head the eyes sit.
@export_range(-30.0, 30.0, 0.1) var eye_height := 6.0:
	set(value):
		eye_height = value
		queue_redraw()
## A lighter patch over the snout, so the eyes and the smile read on the brown.
@export var muzzle := true:
	set(value):
		muzzle = value
		queue_redraw()
## Width and height of the muzzle.
@export var muzzle_size := Vector2(28.0, 19.0):
	set(value):
		muzzle_size = value
		queue_redraw()
## How far below the middle of the head the middle of the muzzle sits.
@export_range(-30.0, 40.0, 0.1) var muzzle_drop := 9.0:
	set(value):
		muzzle_drop = value
		queue_redraw()
## How far the muzzle lightens from the fill toward the paper: 0 is the fill, 1 the paper.
@export_range(0.0, 1.0, 0.01) var muzzle_light := 0.55:
	set(value):
		muzzle_light = value
		queue_redraw()
## Width of the muzzle's soft edge, drawn in the fill's colour, as a multiple of the bear's line.
@export_range(0.1, 2.0, 0.05) var muzzle_edge := 0.6
## A tiny smile on the muzzle. Off leaves the face to its dot eyes alone.
@export var smile := true:
	set(value):
		smile = value
		queue_redraw()
## Width of the smile, and how deep it dips at its middle.
@export var smile_size := Vector2(9.0, 3.0):
	set(value):
		smile_size = value
		queue_redraw()
## How far below the middle of the head the corners of the smile sit.
@export_range(-30.0, 40.0, 0.1) var smile_drop := 11.0:
	set(value):
		smile_drop = value
		queue_redraw()
## Width of the smile's line, as a multiple of the bear's line.
@export_range(0.1, 2.0, 0.05) var smile_line := 0.6

@export_group("Colour")
## Palette role of the outline.
@export var line_role := &"ink":
	set(value):
		line_role = value
		queue_redraw()
## Palette role of the solid fill.
@export var fill_role := &"brown":
	set(value):
		fill_role = value
		queue_redraw()
## Palette role of the eyes and the smile.
@export var face_role := &"ink":
	set(value):
		face_role = value
		queue_redraw()

@export_group("Breathing")
## How far the body swells with each breath, in pixels. The head and arms rise with it.
@export_range(0.0, 6.0, 0.1) var breath_depth := 1.4
## Seconds per breath.
@export_range(0.5, 10.0, 0.1) var breath_period := 3.8

@export_group("Dying")
## How far she topples over, in degrees from sitting up.
@export_range(0.0, 120.0, 0.5) var fall_angle := 84.0
## Seconds the topple takes, gathering speed as she goes over.
@export_range(0.05, 3.0, 0.01) var fall_time := 0.42
## How far she rocks back up as she lands, in degrees.
@export_range(0.0, 30.0, 0.5) var settle_angle := 6.0
## Seconds the rock back up and down again takes.
@export_range(0.0, 2.0, 0.01) var settle_time := 0.26
## Seconds she lies still before she dissolves.
@export_range(0.0, 3.0, 0.01) var down_hold := 0.3

var _breathing := true
## How far she has toppled, in degrees.
var _tilt := 0.0
## Which way she topples: 1 toward the screen right, -1 toward the left.
var _fall_way := 1.0


## Topples her over toward [param direction] (positive is right), round the outer edge of her feet on
## that side, gathering speed as she goes; she lands with a slight settle, lies still a moment, then
## dissolves. Emits [signal folded] at the end.
func fold(direction := 1.0) -> void:
	_breathing = false
	_fall_way = -1.0 if direction < 0.0 else 1.0
	var fall := create_tween()
	fall.tween_method(_set_tilt, 0.0, fall_angle, fall_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if settle_angle > 0.0 and settle_time > 0.0:
		fall.tween_method(_set_tilt, fall_angle, fall_angle - settle_angle, settle_time * 0.5) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		fall.tween_method(_set_tilt, fall_angle - settle_angle, fall_angle, settle_time * 0.5) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	if down_hold > 0.0:
		fall.tween_interval(down_hold)
	await fall.finished
	await dissolve_away(fold_fade).finished
	folded.emit()


## Where something floating over her sits, such as a plea: just above the top of her head and ears, in
## her own space. It tips over with her as she topples.
func head_top() -> Vector2:
	var ear := Vector2.UP.rotated(deg_to_rad(ear_angle)) * head_radius * ear_reach
	var top := minf(-head_radius, ear.y - ear_radius)
	return _toppled(Vector2(0.0, -head_height + top - float_gap))


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var line := palette.color(line_role)
	var fill := palette.color(fill_role)
	var face := palette.color(face_role)
	# Breathing in, the body swells and the head and arms rise with it.
	var swell := _breath() * breath_depth
	var rise := Vector2(0.0, -swell)
	var head := Vector2(0.0, -head_height) + rise
	var body := body_size + Vector2.ONE * swell
	var lines: Array[InkLine] = []
	lines.append(_solid(_body(body, spacing), line, fill, true))
	for side: float in [-1.0, 1.0]:
		lines.append(_solid(_arm(side, body, rise, spacing), line, fill))
	for side: float in [-1.0, 1.0]:
		var foot := Vector2(foot_spread * side, -foot_size.y * 0.5)
		lines.append(_solid(InkBrush.ellipse(foot, foot_size * 0.5, spacing, -PI * 0.5), line, fill, true))
	lines.append(_solid(_head(head, spacing), line, fill, true))
	if muzzle:
		var patch := InkLine.along(InkBrush.ellipse(head + Vector2(0.0, muzzle_drop), muzzle_size * 0.5, spacing),
				fill, muzzle_edge, true)
		patch.fill = fill.lerp(palette.paper, muzzle_light)
		lines.append(patch)
	for side: float in [-1.0, 1.0]:
		lines.append(InkLine.dot(head + Vector2(eye_spread * side, -eye_height), eye_radius, face))
	if smile:
		lines.append(InkLine.along(_smile(head + Vector2(0.0, smile_drop), spacing), face, smile_line))
	_topple(lines)
	return lines


## The body's outline, [param size] across and high: an egg sitting on the ground, fuller toward the
## bottom. It starts at the top, under the head.
func _body(size: Vector2, spacing: float) -> PackedVector2Array:
	var half := size * 0.5
	var centre := Vector2(0.0, -half.y)
	var points := InkBrush.ellipse(centre, half, spacing, -PI * 0.5)
	for i in points.size():
		var height := (points[i].y - centre.y) / half.y
		points[i] = Vector2(points[i].x * (1.0 + body_flare * height), points[i].y)
	return points


## How far out from the middle the outline of a body [param size] across and high is at height
## [param y] (negative is up).
func _body_edge(size: Vector2, y: float) -> float:
	var half := size * 0.5
	var height := clampf((y + half.y) / half.y, -1.0, 1.0)
	return half.x * sqrt(1.0 - height * height) * (1.0 + body_flare * height)


## One arm, on the screen left for [param side] -1: a band that leaves the side of a body [param body]
## across and high, its outer edge running on from the body's outline, and hangs swung out, rounded at
## the paw. It is left open at the top, where it joins the body.
func _arm(side: float, body: Vector2, rise: Vector2, spacing: float) -> PackedVector2Array:
	var half := arm_size.x * 0.5
	var height := rise.y - shoulder_height
	var top := Vector2((_body_edge(body, height) - half) * side, height)
	var hang := Vector2.DOWN.rotated(-deg_to_rad(arm_swing) * side)
	var paw := top + hang * (arm_size.y - half)
	var out := hang.orthogonal() * side
	var points := PackedVector2Array([top + out * half])
	points.append_array(_arc(paw, half, out.angle(), PI * side, spacing))
	points.append(top - out * half)
	return InkBrush.resample_polyline(points, spacing)


## The head's outline round [param centre]: a circle with each ear an open bump on it, the ear's own
## circle traced only where it stands out from the head. It runs clockwise from low on the screen left
## of the head, so the pen's overlap falls over the body, and ends back on its first point.
func _head(centre: Vector2, spacing: float) -> PackedVector2Array:
	var reach := head_radius * ear_reach
	# How far round the head, either side of an ear, its circle crosses the head's.
	var cross := acos(clampf((head_radius * head_radius + reach * reach - ear_radius * ear_radius)
			/ (2.0 * head_radius * reach), -1.0, 1.0))
	var top := -PI * 0.5
	var ears: Array[float] = [top - deg_to_rad(ear_angle), top + deg_to_rad(ear_angle)]
	var points := PackedVector2Array()
	var start_at := _HEAD_START - TAU
	var from := start_at
	for ear in ears:
		points.append_array(_arc(centre, head_radius, from, ear - cross - from, spacing).slice(0 if points.is_empty() else 1))
		var middle := centre + Vector2.from_angle(ear) * reach
		var start := (centre + Vector2.from_angle(ear - cross) * head_radius - middle).angle()
		var end := (centre + Vector2.from_angle(ear + cross) * head_radius - middle).angle()
		points.append_array(_arc(middle, ear_radius, start, fposmod(end - start, TAU), spacing).slice(1))
		from = ear + cross
	points.append_array(_arc(centre, head_radius, from, start_at + TAU - from, spacing).slice(1))
	return points


## A tiny smile with its corners either side of [param corners]: a shallow curve dipping at its middle.
func _smile(corners: Vector2, spacing: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in _SMILE_POINTS:
		var t := lerpf(-1.0, 1.0, float(i) / (_SMILE_POINTS - 1))
		points.append(corners + Vector2(t * smile_size.x * 0.5, (1.0 - t * t) * smile_size.y))
	return InkBrush.resample_smooth(points, false, spacing * 0.5)


## Tips every line over by the topple so far, round the outer edge of the feet on the side she falls
## to, and lifts the whole of her wherever she would otherwise sink below the ground.
func _topple(lines: Array[InkLine]) -> void:
	if is_zero_approx(_tilt):
		return
	var lowest := 0.0
	for line in lines:
		var path := line.path
		for i in path.size():
			path[i] = _toppled(path[i])
			lowest = maxf(lowest, path[i].y)
		line.path = path
	if lowest <= 0.0:
		return
	for line in lines:
		var path := line.path
		for i in path.size():
			path[i] += Vector2.UP * lowest
		line.path = path


## [param point] tipped over by the topple so far, round the outer edge of the feet on the side she
## falls to.
func _toppled(point: Vector2) -> Vector2:
	var pivot := Vector2((foot_spread + foot_size.x * 0.5) * _fall_way, 0.0)
	return pivot + (point - pivot).rotated(deg_to_rad(_tilt) * _fall_way)


## Where she is in her breath, from -1 to 1. Read from the page clock, so it steps with the boil.
func _breath() -> float:
	if Engine.is_editor_hint() or not _breathing or breath_period <= 0.0:
		return 0.0
	var offset := float(posmod(_seed, 1000)) / 1000.0 * breath_period
	return sin((Ink.time + offset) * TAU / breath_period)


func _set_tilt(degrees: float) -> void:
	_tilt = degrees
	queue_redraw()


## A closed outline in [param line], filled solid with [param fill]. An outline left open at one side,
## like an arm joining the body, is still filled straight across that side.
static func _solid(points: PackedVector2Array, line: Color, fill: Color, closed := false) -> InkLine:
	var outline := InkLine.along(points, line, 1.0, closed)
	outline.fill = fill
	return outline


## Points about [param spacing] apart round a circle, from [param from] radians sweeping [param sweep]
## radians (positive is clockwise on screen), both ends included.
static func _arc(centre: Vector2, radius: float, from: float, sweep: float, spacing: float) -> PackedVector2Array:
	var steps := maxi(1, ceili(absf(sweep) * radius / spacing))
	var points := PackedVector2Array()
	for i in steps + 1:
		points.append(centre + Vector2.from_angle(from + sweep * i / steps) * radius)
	return points
