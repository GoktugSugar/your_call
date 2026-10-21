@tool
class_name StickFigure
extends InkDrawing
## A soul: the androgynous stick figure every person in the game is drawn with. Dot eyes, no other face.
## The body is a jointed rig posed by a [FigurePose]. Its legs bend at the knee to keep the feet planted,
## it breathes, and it folds down dead. Its origin is the ground between its feet.

## Emitted once a fold has finished and the figure has dissolved away.
signal folded

## The pose the figure holds. Setting it snaps the figure into it.
@export var pose: FigurePose:
	set(value):
		pose = value
		_kill_motion()
		_shown = value.duplicate() as FigurePose if value != null else FigurePose.new()
		queue_redraw()

@export_group("Body")
## Hips to ground when standing straight.
@export_range(10.0, 200.0, 0.5) var leg_length := 51.0:
	set(value):
		leg_length = value
		queue_redraw()
## Hips to neck.
@export_range(10.0, 200.0, 0.5) var spine_length := 38.0:
	set(value):
		spine_length = value
		queue_redraw()
## Neck to the bottom of the head.
@export_range(0.0, 40.0, 0.5) var neck_length := 4.0:
	set(value):
		neck_length = value
		queue_redraw()
## Radius of the head.
@export_range(4.0, 60.0, 0.5) var head_radius := 11.5:
	set(value):
		head_radius = value
		queue_redraw()
## Shoulder to elbow.
@export_range(5.0, 100.0, 0.5) var upper_arm_length := 21.0:
	set(value):
		upper_arm_length = value
		queue_redraw()
## Elbow to hand.
@export_range(5.0, 100.0, 0.5) var forearm_length := 20.0:
	set(value):
		forearm_length = value
		queue_redraw()
## How far below the neck the arms join the spine.
@export_range(0.0, 60.0, 0.5) var shoulder_drop := 5.5:
	set(value):
		shoulder_drop = value
		queue_redraw()
## How far each foot stands from the middle.
@export_range(0.0, 60.0, 0.5) var foot_spread := 10.0:
	set(value):
		foot_spread = value
		queue_redraw()
## Once the spine leans further than this, in degrees, the knees bend up off the ground instead of out to the sides.
@export_range(0.0, 90.0, 0.5) var knee_lift_lean := 45.0

@export_group("Face")
## Radius of each dot eye.
@export_range(0.5, 8.0, 0.1) var eye_radius := 2.6:
	set(value):
		eye_radius = value
		queue_redraw()
## How far each eye sits from the middle of the face.
@export_range(0.0, 20.0, 0.1) var eye_spread := 4.2:
	set(value):
		eye_spread = value
		queue_redraw()
## How far above the middle of the head the eyes sit.
@export_range(-20.0, 20.0, 0.1) var eye_height := 1.2:
	set(value):
		eye_height = value
		queue_redraw()

@export_group("Breathing")
## How far the hips rise and fall with each breath, in pixels.
@export_range(0.0, 6.0, 0.1) var breath_depth := 1.1
## Seconds per breath.
@export_range(0.5, 10.0, 0.1) var breath_period := 3.4
## How far the arms sway with each breath, in degrees.
@export_range(0.0, 10.0, 0.1) var breath_arm_sway := 2.5

@export_group("Dying")
## The steps of the fold, in order: each pose says how long the figure takes to reach it.
@export var fold_steps: Array[FigurePose] = []
## Seconds the body takes to dissolve once it is down.
@export_range(0.0, 3.0, 0.01) var fold_fade := 0.5

var _shown := FigurePose.new()
var _breathing := true
var _motion: Tween


## Blends from the pose shown now into [param target]. Await the returned tween's [code]finished[/code].
func blend_to(target: FigurePose, duration: float, transition := Tween.TRANS_SINE, ease := Tween.EASE_IN_OUT) -> Tween:
	_kill_motion()
	var from := _shown.duplicate() as FigurePose
	_motion = create_tween()
	_motion.tween_method(_blend_step.bind(from, target), 0.0, 1.0, maxf(duration, 0.001)) \
			.set_trans(transition).set_ease(ease)
	return _motion


## Plays [param steps] in order, each pose arriving the way it says. Mirrors them when [param mirror] is set.
func play_motion(steps: Array[FigurePose], mirror := false) -> void:
	for step in steps:
		var target := step.mirrored() if mirror else step
		await blend_to(target, step.arrive_duration, step.arrive_transition, step.arrive_ease).finished
		if step.hold > 0.0:
			await get_tree().create_timer(step.hold, false).timeout


## Folds the figure down dead: it buckles, collapses and topples toward [param direction]
## (positive is right), then dissolves. Emits [signal folded] at the end.
func fold(direction := 1.0) -> void:
	_breathing = false
	await play_motion(fold_steps, direction < 0.0)
	await dissolve_away(fold_fade).finished
	folded.emit()


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var shown := _shown
	var breath := _breath()
	var spine_dir := Vector2.UP.rotated(deg_to_rad(shown.spine_angle))
	var head_angle := deg_to_rad(shown.spine_angle + shown.head_tilt)
	var head_dir := Vector2.UP.rotated(head_angle)
	var hips := Vector2(0.0, -leg_length) + shown.hip_offset + Vector2(0.0, -breath * breath_depth * 0.5)
	var neck := hips + spine_dir * spine_length
	var head := neck + head_dir * (neck_length + head_radius)
	var chin := head - head_dir * head_radius
	var shoulders := neck - spine_dir * shoulder_drop
	var down := -spine_dir
	var sway := breath * breath_arm_sway
	var left_angle := deg_to_rad(shown.left_shoulder + sway)
	var right_angle := deg_to_rad(-shown.right_shoulder - sway)
	var left_elbow := shoulders + down.rotated(left_angle) * upper_arm_length
	var left_hand := left_elbow + down.rotated(left_angle + deg_to_rad(shown.left_elbow)) * forearm_length
	var right_elbow := shoulders + down.rotated(right_angle) * upper_arm_length
	var right_hand := right_elbow + down.rotated(right_angle - deg_to_rad(shown.right_elbow)) * forearm_length
	var left_foot := Vector2(-foot_spread, 0.0) + shown.left_foot
	var right_foot := Vector2(foot_spread, 0.0) + shown.right_foot

	var ink := palette.ink
	var lines: Array[InkLine] = []
	lines.append(InkLine.along(InkBrush.ellipse(head, Vector2.ONE * head_radius, spacing, head_angle - PI * 0.75),
			ink, 1.0, true))
	lines.append(InkLine.along(InkBrush.resample_polyline(PackedVector2Array([hips, neck, chin]), spacing), ink))
	lines.append(InkLine.along(InkBrush.resample_polyline(PackedVector2Array([shoulders, left_elbow, left_hand]), spacing), ink))
	lines.append(InkLine.along(InkBrush.resample_polyline(PackedVector2Array([shoulders, right_elbow, right_hand]), spacing), ink))
	var lying := absf(shown.spine_angle) > knee_lift_lean
	lines.append(InkLine.along(InkBrush.resample_polyline(
			PackedVector2Array([hips, _knee(hips, left_foot, 1.0, lying), left_foot]), spacing), ink))
	lines.append(InkLine.along(InkBrush.resample_polyline(
			PackedVector2Array([hips, _knee(hips, right_foot, -1.0, lying), right_foot]), spacing), ink))
	for side: float in [-1.0, 1.0]:
		var eye := head + Vector2(eye_spread * side, -eye_height).rotated(head_angle)
		lines.append(InkLine.dot(eye, eye_radius, ink))
	return lines


## Where the knee sits for a leg reaching from [param hip] to [param foot]. Standing, it bends out
## to [param side]; [param lying], it bends up, away from the ground.
func _knee(hip: Vector2, foot: Vector2, side: float, lying: bool) -> Vector2:
	var thigh := leg_length * 0.5
	var shin := leg_length * 0.5
	var to_foot := foot - hip
	var reach := clampf(to_foot.length(), 0.001, thigh + shin - 0.001)
	var bend := acos(clampf((thigh * thigh + reach * reach - shin * shin) / (2.0 * thigh * reach), -1.0, 1.0))
	var along := to_foot.normalized()
	var knee := hip + along.rotated(bend * side) * thigh
	if lying:
		var other := hip + along.rotated(-bend * side) * thigh
		if other.y < knee.y:
			knee = other
	return knee


## Where the figure is in its breath, from -1 to 1. Read from the page clock, so it steps with the boil.
func _breath() -> float:
	if Engine.is_editor_hint() or not _breathing or breath_period <= 0.0:
		return 0.0
	var offset := float(posmod(_seed, 1000)) / 1000.0 * breath_period
	return sin((Ink.time + offset) * TAU / breath_period)


func _blend_step(weight: float, from: FigurePose, target: FigurePose) -> void:
	_shown.blend(from, target, weight)
	queue_redraw()


func _kill_motion() -> void:
	if _motion != null and _motion.is_valid():
		_motion.kill()
	_motion = null
