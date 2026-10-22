class_name FigureWalk
extends RefCounted
## One walk of a [StickFigure] along the ground, planned before it sets off: where each foot comes down,
## how the body carries over the planted feet, and the figure's pose at any moment of the way. The
## trailing foot steps first and the feet take turns. A planted foot never slides: it stays put until it
## lifts for its own step. The figure sets off from its pose, walks upright, and stands back into its
## pose as it stops. Lengths are in the figure's own pixels, along the way it walks from where it set off.

## How many steps the walk takes. Always even, so the leading foot takes the last step.
var steps := 0
## How far the walk carries the figure.
var distance := 0.0
## Which way the figure walks: 1 toward the screen right, -1 toward the left.
var way := 1.0

var _figure: StickFigure
var _from: FigurePose
var _to: FigurePose
## Where the feet come down along the way, in order. The first two are where the trailing and the
## leading foot stand at the start; after them, step k puts its foot down at index k + 2.
var _plants := PackedFloat32Array()
## How far along the way the body is as each step starts, and once the last step ends.
var _body := PackedFloat32Array()
## Whether the trailing foot, the one that steps first, is the screen left foot.
var _left_first := true
## The walking posture at the moment asked for, before it is blended with the standing poses.
var _gait := FigurePose.new()


## Plans a walk of [param walk_distance] pixels toward [param walk_way] (positive is right), setting off
## from [param from] and stopping in [param to]. The gait comes from [param figure]'s walking exports.
func _init(figure: StickFigure, from: FigurePose, to: FigurePose, walk_distance: float, walk_way: float) -> void:
	_figure = figure
	_from = from
	_to = to
	distance = absf(walk_distance)
	way = -1.0 if walk_way < 0.0 else 1.0
	var spread := figure.foot_spread
	var start_left := (from.left_foot.x - spread) * way
	var start_right := (from.right_foot.x + spread) * way
	_left_first = start_left <= start_right
	var trailing := minf(start_left, start_right)
	var leading := maxf(start_left, start_right)
	var end_left := distance + (to.left_foot.x - spread) * way
	var end_right := distance + (to.right_foot.x + spread) * way
	var first_end := end_left if _left_first else end_right
	var second_end := end_right if _left_first else end_left
	# The steps between setting off and stopping land evenly, as near a stride apart as an even count allows.
	var span := first_end - leading
	steps = maxi(2, 2 * roundi((span / maxf(figure.stride, 1.0) + 1.0) * 0.5))
	_plants.append(trailing)
	_plants.append(leading)
	for k in steps - 1:
		_plants.append(lerpf(leading, first_end, float(k + 1) / (steps - 1)))
	_plants.append(second_end)
	# Whenever both feet are down, the body is midway between them.
	_body.append(0.0)
	for k in range(1, steps):
		_body.append((_plants[k] + _plants[k + 1]) * 0.5)
	_body.append(distance)


## How far along the way the body is, [param progress] steps into the walk. It eases off from standing
## still, carries on at an even pace, and eases to a stop.
func travel_at(progress: float) -> float:
	var p := clampf(progress, 0.0, float(steps))
	var k := clampi(floori(p), 0, steps - 1)
	var u := p - k
	var u2 := u * u
	var u3 := u2 * u
	return (2.0 * u3 - 3.0 * u2 + 1.0) * _body[k] + (u3 - 2.0 * u2 + u) * _pace(k) \
			+ (3.0 * u2 - 2.0 * u3) * _body[k + 1] + (u3 - u2) * _pace(k + 1)


## Sets [param pose] to the figure's pose [param progress] steps into the walk, its feet placed relative
## to where the body is at that moment.
func pose_at(progress: float, pose: FigurePose) -> void:
	var p := clampf(progress, 0.0, float(steps))
	var k := clampi(floori(p), 0, steps - 1)
	var u := p - k
	var figure := _figure
	# The walking posture: hips that dip just after each foot lands, a lean into the walk, and arms
	# swinging against the legs. It takes over from the standing pose through the first step and gives
	# way back to it through the last. Arm angles here are how far forward each arm swings.
	var swing := figure.arm_swing * cos(PI * p)
	var left_swing := swing if _left_first else -swing
	var dip := cos(PI * (p - figure.bob_lag))
	_gait.hip_offset = Vector2(0.0, figure.walk_crouch + figure.hip_bob * dip * dip)
	_gait.spine_angle = way * figure.walk_lean
	_gait.head_tilt = 0.0
	_gait.left_shoulder = -way * (figure.arm_carry + left_swing)
	_gait.right_shoulder = way * (figure.arm_carry - left_swing)
	_gait.left_elbow = -way * figure.walk_elbow
	_gait.right_elbow = way * figure.walk_elbow
	var weight := smoothstep(0.0, 1.0, p) * smoothstep(0.0, 1.0, steps - p)
	pose.blend(_from if p < steps * 0.5 else _to, _gait, weight)

	# The stepping foot lifts and swings from where it stood to where it lands; the other stays planted.
	# A short step, like the first or the last, lifts the foot less.
	var body := travel_at(p)
	var lift_from := _plants[k]
	var land := _plants[k + 2]
	var swing_x := lerpf(lift_from, land, smoothstep(0.0, 1.0, u))
	var lift := figure.foot_lift * sin(PI * u) * minf(absf(land - lift_from) / (2.0 * maxf(figure.stride, 1.0)), 1.0)
	var swinging := Vector2(way * (swing_x - body), -lift)
	var planted := Vector2(way * (_plants[k + 1] - body), 0.0)
	# Even steps move the foot that stepped first, odd steps the other.
	var first := swinging if k % 2 == 0 else planted
	var second := planted if k % 2 == 0 else swinging
	var left := first if _left_first else second
	var right := second if _left_first else first
	pose.left_foot = left + Vector2(figure.foot_spread, 0.0)
	pose.right_foot = right - Vector2(figure.foot_spread, 0.0)


## How fast the body moves as step [param k] starts, in pixels a step: still at both ends of the walk.
func _pace(k: int) -> float:
	if k <= 0 or k >= steps:
		return 0.0
	return (_body[k + 1] - _body[k - 1]) * 0.5
