@tool
class_name StickFigure
extends Soul
## A soul: the androgynous stick figure every person in the game is drawn with. Dot eyes, no other face.
## The body is a jointed rig posed by a [FigurePose]. Its legs bend at the knee to keep the feet planted,
## it breathes, it can turn and walk along the ground, and it folds down dead. Kinds of soul differ by
## small details, never new art: closed or hidden eyes, a pregnant belly, a cane and sparse hair, a beating
## heart, z marks drifting up from a sleeper. Its origin is the ground between its feet.

## Emitted once a walk has ended, with the figure standing in its pose where it was going.
signal arrived

enum Eyes { OPEN, CLOSED, HIDDEN }
## Which way a figure faces: toward the player, or turned to the screen left or right.
enum Facing { FRONT, LEFT, RIGHT }

## The pose the figure holds. Setting it snaps the figure into it.
@export var pose: FigurePose:
	set(value):
		pose = value
		_kill_motion()
		_shown = value.duplicate() as FigurePose if value != null else FigurePose.new()
		queue_redraw()
## Which way the figure faces. Turned left or right, its eyes slide that way and its knees bend that way.
## A walk turns it the way it goes.
@export var facing := Facing.FRONT:
	set(value):
		facing = value
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
## How far each eye sits from the middle of the pair once the figure is turned left or right.
@export_range(0.0, 20.0, 0.1) var turned_eye_spread := 3.3:
	set(value):
		turned_eye_spread = value
		queue_redraw()
## How far the eyes slide toward the side a turned figure faces.
@export_range(0.0, 20.0, 0.1) var turned_eye_shift := 2.3:
	set(value):
		turned_eye_shift = value
		queue_redraw()

@export_group("Breathing")
## How far the hips rise and fall with each breath, in pixels.
@export_range(0.0, 6.0, 0.1) var breath_depth := 1.1
## Seconds per breath.
@export_range(0.5, 10.0, 0.1) var breath_period := 3.4
## How far the arms sway with each breath, in degrees.
@export_range(0.0, 10.0, 0.1) var breath_arm_sway := 2.5

@export_group("Walking")
## How far each step carries the figure, in pixels.
@export_range(4.0, 120.0, 0.5) var stride := 36.0
## Seconds each step takes at the figure's own pace.
@export_range(0.05, 2.0, 0.01) var step_time := 0.4
## How high the stepping foot lifts, in pixels.
@export_range(0.0, 40.0, 0.5) var foot_lift := 9.0
## How far the hips dip after each foot lands, in pixels.
@export_range(0.0, 20.0, 0.1) var hip_bob := 4.0
## How long after a foot lands the hips are at their lowest, as a share of a step. The legs stay straight
## as the foot reaches the ground, and the knees give as the weight comes onto it.
@export_range(0.0, 1.0, 0.01) var bob_lag := 0.2
## How far the hips sink below standing for the whole walk, so the knees stay soft, in pixels.
@export_range(0.0, 20.0, 0.1) var walk_crouch := 0.0
## How far the arms swing forward and back, in degrees.
@export_range(0.0, 90.0, 0.5) var arm_swing := 30.0
## How far forward the arms hang at the middle of their swing, in degrees, so they stay clear of the body.
@export_range(-45.0, 45.0, 0.5) var arm_carry := 8.0
## How far the forearms bend forward while walking, in degrees.
@export_range(-90.0, 150.0, 0.5) var walk_elbow := 25.0
## How far the body leans into the walk, in degrees.
@export_range(-30.0, 30.0, 0.5) var walk_lean := 5.0

@export_group("Details")
## Open dot eyes, eyes closed in sleep, or none at all for a figure turned away.
@export var eyes := Eyes.OPEN:
	set(value):
		eyes = value
		queue_redraw()
## How far a pregnant belly bulges from the spine, in pixels. Zero for none.
@export_range(0.0, 40.0, 0.5) var belly := 0.0:
	set(value):
		belly = value
		queue_redraw()
## Leans on a cane, held in the screen right hand.
@export var cane := false:
	set(value):
		cane = value
		queue_redraw()
## A few sparse wisps of hair, for the old.
@export var hair := false:
	set(value):
		hair = value
		queue_redraw()
## A small beating heart floats over the head.
@export var heart := false:
	set(value):
		heart = value
		queue_redraw()
## Z marks drift up from the head.
@export var snoring := false:
	set(value):
		snoring = value
		queue_redraw()
## Palette role of the heart.
@export var heart_role := &"pink"
## Width of the heart, in pixels.
@export_range(4.0, 60.0, 0.5) var heart_size := 15.0
## Beats a second. Like breathing, the beat steps with the page's boil.
@export_range(0.1, 4.0, 0.05) var heart_rate := 1.1
## How much the heart swells on a beat, as a fraction of its size.
@export_range(0.0, 1.0, 0.01) var heart_swell := 0.25
## Gap between the top of the head and anything floating over it, in pixels.
@export_range(0.0, 80.0, 0.5) var float_gap := 12.0
## Seconds each z mark takes to drift up and fade.
@export_range(0.2, 10.0, 0.05) var snore_period := 2.4
## How far each z mark drifts, in pixels: out to the right and up.
@export var snore_drift := Vector2(22.0, -42.0)
## Height of a z mark as it leaves the head and once it has drifted, in pixels.
@export var snore_size := Vector2(7.0, 13.0)
## Palette role of the z marks.
@export var snore_role := &"ink"

@export_group("Dying")
## The steps of the fold, in order: each pose says how long the figure takes to reach it.
## Leave it empty for a soul already lying down, which only dissolves.
@export var fold_steps: Array[FigurePose] = []

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


## Walks along the ground to [param x], in the parent's space, turned the way it goes, and stands back in
## its pose there. The feet take turns to step and stay planted while they bear the weight, the knees
## bend, the hips bob, the arms swing against the legs and the body leans into the walk. It walks at its
## own pace, a [member stride] every [member step_time] seconds, unless [param speed] asks for so many
## pixels a second in the parent's space: each step still covers a stride, only quicker or slower. Like a
## fall, a walk moves at the full frame rate. Await it, or wait for [signal arrived] at the end.
func walk_to(x: float, speed := 0.0) -> void:
	_kill_motion()
	var from_x := position.x
	if is_equal_approx(x, from_x):
		arrived.emit()
		return
	var way := signf(x - from_x)
	facing = Facing.RIGHT if way > 0.0 else Facing.LEFT
	var own_scale := maxf(absf(scale.x), 0.0001)
	var end_pose := pose if pose != null else FigurePose.new()
	var walk := FigureWalk.new(self, _shown.duplicate() as FigurePose, end_pose, absf(x - from_x) / own_scale, way)
	var seconds_per_step := step_time if speed <= 0.0 else stride * own_scale / speed
	_motion = create_tween()
	_motion.tween_method(_walk_step.bind(walk, from_x, own_scale), 0.0, float(walk.steps),
			walk.steps * seconds_per_step)
	await _motion.finished
	position.x = x
	_shown.blend(end_pose, end_pose, 1.0)
	queue_redraw()
	arrived.emit()


## Where something floating over the figure sits, such as a plea: just above the top of its head,
## in the figure's own space.
func head_top() -> Vector2:
	var hips := Vector2(0.0, -leg_length) + _shown.hip_offset
	var neck := hips + Vector2.UP.rotated(deg_to_rad(_shown.spine_angle)) * spine_length
	var head_dir := Vector2.UP.rotated(deg_to_rad(_shown.spine_angle + _shown.head_tilt))
	return neck + head_dir * (neck_length + head_radius * 2.0) + Vector2.UP * float_gap


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
	# Facing the player, the knees bend outward. Turned, both bend the way the figure faces.
	var turn := _turn()
	var left_knee := 1.0 if turn == 0.0 else -turn
	var right_knee := -1.0 if turn == 0.0 else -turn
	lines.append(InkLine.along(InkBrush.resample_polyline(
			PackedVector2Array([hips, _knee(hips, left_foot, left_knee, lying), left_foot]), spacing), ink))
	lines.append(InkLine.along(InkBrush.resample_polyline(
			PackedVector2Array([hips, _knee(hips, right_foot, right_knee, lying), right_foot]), spacing), ink))
	var eye_gap := lerpf(eye_spread, turned_eye_spread, absf(turn))
	for side: float in [-1.0, 1.0]:
		var eye := head + Vector2(turned_eye_shift * turn + eye_gap * side, -eye_height).rotated(head_angle)
		match eyes:
			Eyes.OPEN:
				lines.append(InkLine.dot(eye, eye_radius, ink))
			Eyes.CLOSED:
				var lid := PackedVector2Array([Vector2(-0.85, -0.1), Vector2(0.0, 0.55), Vector2(0.85, -0.1)])
				for i in lid.size():
					lid[i] = eye + (lid[i] * eye_radius).rotated(head_angle)
				lines.append(InkLine.along(InkBrush.resample_smooth(lid, false, spacing * 0.5), ink, 0.7))
	if belly > 0.0:
		lines.append(InkLine.along(_belly(hips, neck, spine_dir, spacing), ink))
	if cane:
		lines.append(InkLine.along(_cane(right_hand, spacing), ink, 0.85))
	if hair:
		# A bald crown with a tuft over each ear.
		for side: float in [-1.0, 1.0]:
			var tuft := PackedVector2Array([Vector2(0.88, -0.5), Vector2(1.2, -0.62), Vector2(1.12, -0.22), Vector2(1.42, -0.18)])
			for i in tuft.size():
				tuft[i] = head + (Vector2(tuft[i].x * side, tuft[i].y) * head_radius).rotated(head_angle)
			lines.append(InkLine.along(InkBrush.resample_smooth(tuft, false, spacing * 0.5), ink, 0.55))
	if heart:
		lines.append(_heart(head + head_dir * (head_radius + float_gap), palette.color(heart_role), spacing))
	if snoring:
		for i in 3:
			_add_z(lines, head + Vector2(head_radius * 0.8, -head_radius), _clock() / snore_period + i / 3.0,
					palette.color(snore_role), spacing)
	return lines


## A pregnant belly: a round bulge out from the lower spine, toward the screen right, or the left for a
## figure turned that way.
func _belly(hips: Vector2, neck: Vector2, spine_dir: Vector2, spacing: float) -> PackedVector2Array:
	var low := hips.lerp(neck, 0.02)
	var high := hips.lerp(neck, 0.6)
	var middle := low.lerp(high, 0.5)
	var half := low.distance_to(high) * 0.5
	var out := -spine_dir.orthogonal() * (-1.0 if facing == Facing.LEFT else 1.0)
	var points := PackedVector2Array()
	var steps := maxi(6, ceili(PI * maxf(half, belly) / spacing))
	for i in steps + 1:
		var angle := lerpf(-PI * 0.5, PI * 0.5, float(i) / steps)
		points.append(middle + spine_dir * sin(angle) * half + out * cos(angle) * belly)
	return points


## A cane: a straight shaft from the ground up into the hand, hooked over at the top.
func _cane(hand: Vector2, spacing: float) -> PackedVector2Array:
	var top := hand + Vector2(0.0, -4.0)
	var shaft := InkBrush.resample_polyline(PackedVector2Array([Vector2(hand.x + 2.0, 0.0), top]), spacing)
	var hook := InkBrush.resample_smooth(PackedVector2Array([top, top + Vector2(-3.0, -3.0), top + Vector2(-6.5, -0.5),
			top + Vector2(-7.0, 3.0)]), false, spacing * 0.5)
	shaft.append_array(hook.slice(1))
	return shaft


## A small heart centred above [param top], washed in its own colour, swelling on each beat.
func _heart(top: Vector2, color: Color, spacing: float) -> InkLine:
	var beat := pow(maxf(sin(_clock() * TAU * heart_rate), 0.0), 4.0)
	var size := heart_size * (1.0 + heart_swell * beat) / 32.0
	var points := PackedVector2Array()
	var steps := 24
	for i in steps:
		var t := TAU * i / steps
		var x := 16.0 * pow(sin(t), 3.0)
		var y := 13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t)
		points.append(top + Vector2(x, -y - 4.0) * size)
	var line := InkLine.along(InkBrush.resample_smooth(points, true, spacing * 0.5), color, 0.8, true)
	line.fill = Color(color, 0.4)
	return line


## One z mark, [param phase] of the way through its drift up from [param start]. Phases wrap at 1.
func _add_z(lines: Array[InkLine], start: Vector2, phase: float, color: Color, spacing: float) -> void:
	var t := fposmod(phase, 1.0)
	var half := lerpf(snore_size.x, snore_size.y, t) * 0.5
	var centre := start + snore_drift * t
	var corners := PackedVector2Array([centre + Vector2(-half, -half), centre + Vector2(half, -half),
			centre + Vector2(-half, half), centre + Vector2(half, half)])
	lines.append(InkLine.along(InkBrush.resample_polyline(corners, spacing * 0.5), Color(color, sin(t * PI)), 0.6))


## Which way the figure is turned: -1 to the screen left, 1 to the right, 0 facing the player.
func _turn() -> float:
	match facing:
		Facing.LEFT:
			return -1.0
		Facing.RIGHT:
			return 1.0
	return 0.0


## Seconds on the page clock, for details that move. The editor holds still.
func _clock() -> float:
	return 0.0 if Engine.is_editor_hint() else Ink.time


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


func _walk_step(progress: float, walk: FigureWalk, from_x: float, own_scale: float) -> void:
	position.x = from_x + walk.way * walk.travel_at(progress) * own_scale
	walk.pose_at(progress, _shown)
	queue_redraw()


func _kill_motion() -> void:
	if _motion != null and _motion.is_valid():
		_motion.kill()
	_motion = null
