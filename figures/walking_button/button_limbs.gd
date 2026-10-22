@tool
class_name ButtonLimbs
extends InkDrawing
## The walking button's stick limbs: two legs from under its base and two arms from its sides. It sits
## behind the body, so every limb comes out from under the base's paper. A leg bends at the knee to reach
## its foot, the knee toward the way the button faces (out to the side while it faces out of the page),
## and ends in a little foot. An arm swings from its shoulder and bends at the elbow; a clenched hand is a dot.
## [WalkingButton] poses it; this only draws it. Its space is the body's: the origin is the middle of
## the bottom of the base.

## How far the limbs have grown out of the body: 0 is not at all, 1 is full length.
@export_range(0.0, 1.5, 0.001) var growth := 1.0:
	set(value):
		growth = value
		queue_redraw()
## Which way the button faces: -1 left, 0 out of the page, 1 right. The knees, the toes and which arm is
## in front follow it, swapping over halfway through a turn.
@export_range(-1.0, 1.0, 0.01) var facing := 0.0:
	set(value):
		facing = value
		queue_redraw()
## Where the screen left foot is.
@export var left_foot := Vector2(-46.0, 54.0):
	set(value):
		left_foot = value
		queue_redraw()
## Where the screen right foot is.
@export var right_foot := Vector2(46.0, 54.0):
	set(value):
		right_foot = value
		queue_redraw()
## How the arms are held. Empty hangs them at rest.
@export var arms: ButtonArmPose:
	set(value):
		arms = value
		queue_redraw()
## Width and height of the base the limbs come out of.
@export var base_size := Vector2(200.0, 36.0):
	set(value):
		base_size = value
		queue_redraw()

@export_group("Legs")
## Hip to foot with the leg straight. The thigh and the shin are half of it each.
@export_range(10.0, 300.0, 0.5) var leg_length := 64.0:
	set(value):
		leg_length = value
		queue_redraw()
## How far each leg joins from the middle of the base.
@export_range(0.0, 200.0, 0.5) var hip_spread := 46.0:
	set(value):
		hip_spread = value
		queue_redraw()
## How far up inside the base the legs start, so the base hides their tops.
@export_range(0.0, 40.0, 0.5) var hip_inset := 4.0:
	set(value):
		hip_inset = value
		queue_redraw()
## Length of each foot, from the ankle to the toe.
@export_range(0.0, 40.0, 0.5) var foot_length := 12.0:
	set(value):
		foot_length = value
		queue_redraw()

@export_group("Arms")
## Shoulder to elbow.
@export_range(5.0, 150.0, 0.5) var upper_arm_length := 28.0:
	set(value):
		upper_arm_length = value
		queue_redraw()
## Elbow to hand.
@export_range(5.0, 150.0, 0.5) var forearm_length := 24.0:
	set(value):
		forearm_length = value
		queue_redraw()
## How far in from the ends of the base the arms start, so the base hides their roots.
@export_range(0.0, 40.0, 0.5) var shoulder_inset := 4.0:
	set(value):
		shoulder_inset = value
		queue_redraw()
## How far up the sides of the base the arms join, as a share of its height.
@export_range(0.0, 1.0, 0.01) var shoulder_height := 0.5:
	set(value):
		shoulder_height = value
		queue_redraw()
## Radius of a clenched fist.
@export_range(0.5, 20.0, 0.1) var fist_size := 8.0:
	set(value):
		fist_size = value
		queue_redraw()

## How far through a turn the knees, the toes and the front arm swap over to the other side.
const _TURNED := 0.5

## The arms at rest, for when no pose is given.
var _resting := ButtonArmPose.new()


## The furthest any limb can reach out from the middle, sideways, at full length.
func reach() -> float:
	var arm := base_size.x * 0.5 - shoulder_inset + upper_arm_length + forearm_length + fist_size
	var leg := hip_spread + leg_length + foot_length
	return maxf(arm, leg)


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var lines: Array[InkLine] = []
	if growth <= 0.0:
		return lines
	var spacing := style.sample_spacing
	var ink := palette.ink
	var pose := arms if arms != null else _resting
	for side: float in [-1.0, 1.0]:
		var hip := Vector2(hip_spread * side, -hip_inset)
		var foot := right_foot if side > 0.0 else left_foot
		var toward := _bend_side(side)
		var toe := foot + Vector2(foot_length * toward, 0.0)
		var leg := _grown([hip, _knee(hip, foot, toward), foot, toe], hip)
		lines.append(InkLine.along(InkBrush.resample_polyline(leg, spacing), ink))
	for side: float in [-1.0, 1.0]:
		var front := _is_front(side)
		var shoulder := Vector2((base_size.x * 0.5 - shoulder_inset) * side, -base_size.y * shoulder_height)
		var swing := deg_to_rad(pose.front_shoulder if front else pose.back_shoulder)
		var bend := deg_to_rad(pose.front_elbow if front else pose.back_elbow)
		# The same turns a stick figure's arms make: the screen left arm swings out one way, the right the other.
		var elbow := shoulder + Vector2.DOWN.rotated(-side * swing) * upper_arm_length
		var hand := elbow + Vector2.DOWN.rotated(-side * (swing + bend)) * forearm_length
		var arm := _grown([shoulder, elbow, hand], shoulder)
		lines.append(InkLine.along(InkBrush.resample_polyline(arm, spacing), ink))
		if (pose.front_fist if front else pose.back_fist):
			lines.append(InkLine.dot(arm[arm.size() - 1], fist_size * minf(growth, 1.0), ink))
	return lines


## [param points] pulled in toward [param root] as far as the limbs have yet to grow.
func _grown(points: Array, root: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point: Vector2 in points:
		out.append(root + (point - root) * growth)
	return out


## Where the knee sits on a leg from [param hip] to [param foot], bent out toward [param side]
## (positive is right). A foot out of reach pulls the leg straight and long, like a cartoon leg.
func _knee(hip: Vector2, foot: Vector2, side: float) -> Vector2:
	var half := leg_length * 0.5
	var to_foot := foot - hip
	var along := to_foot.normalized() if not to_foot.is_zero_approx() else Vector2.DOWN
	var bend := acos(clampf(to_foot.length() / leg_length, 0.0, 1.0))
	return hip + along.rotated(-bend * side) * half


## Which way the knee and the toes of the leg on [param side] point: the way the button faces, or out
## to that leg's own side while it faces out of the page.
func _bend_side(side: float) -> float:
	return signf(facing) if absf(facing) >= _TURNED else side


## Whether the arm on [param side] is the front arm.
func _is_front(side: float) -> bool:
	return side < 0.0 if facing <= -_TURNED else side > 0.0
