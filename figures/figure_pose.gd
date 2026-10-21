@tool
class_name FigurePose
extends Resource
## A stick figure's pose: where its hips, spine, head, arms and feet are. Figures are reposed, never redrawn.
## Angles are in degrees. Offsets are in pixels from the standing pose, with y pointing down.
## As a step in a motion, a pose also says how the figure arrives in it.

## Where the hips sit, relative to standing.
@export var hip_offset := Vector2.ZERO
## Lean of the spine. Positive leans to the right.
@export_range(-180.0, 180.0, 0.5) var spine_angle := 0.0
## Tilt of the head on the spine. Positive tilts to the right.
@export_range(-90.0, 90.0, 0.5) var head_tilt := 0.0
## Swing of the screen left arm away from hanging straight down. Positive swings it out to the side.
@export_range(-180.0, 180.0, 0.5) var left_shoulder := 24.0
## Swing of the screen right arm away from hanging straight down. Positive swings it out to the side.
@export_range(-180.0, 180.0, 0.5) var right_shoulder := 24.0
## Bend at the screen left elbow. Positive bends the forearm further out.
@export_range(-170.0, 170.0, 0.5) var left_elbow := 12.0
## Bend at the screen right elbow. Positive bends the forearm further out.
@export_range(-170.0, 170.0, 0.5) var right_elbow := 12.0
## Where the screen left foot is planted, relative to standing.
@export var left_foot := Vector2.ZERO
## Where the screen right foot is planted, relative to standing.
@export var right_foot := Vector2.ZERO

@export_group("Arriving")
## Seconds to blend into this pose when it is a step in a motion.
@export_range(0.0, 5.0, 0.01) var arrive_duration := 0.3
## The curve of that blend.
@export var arrive_transition := Tween.TRANS_SINE
## Which end of the blend the curve eases.
@export var arrive_ease := Tween.EASE_IN_OUT
## Seconds to hold this pose before the next step starts.
@export_range(0.0, 5.0, 0.01) var hold := 0.0


## Sets this pose part way between [param from] and [param to]: 0 is [param from], 1 is [param to].
func blend(from: FigurePose, to: FigurePose, weight: float) -> void:
	hip_offset = from.hip_offset.lerp(to.hip_offset, weight)
	spine_angle = lerpf(from.spine_angle, to.spine_angle, weight)
	head_tilt = lerpf(from.head_tilt, to.head_tilt, weight)
	left_shoulder = lerpf(from.left_shoulder, to.left_shoulder, weight)
	right_shoulder = lerpf(from.right_shoulder, to.right_shoulder, weight)
	left_elbow = lerpf(from.left_elbow, to.left_elbow, weight)
	right_elbow = lerpf(from.right_elbow, to.right_elbow, weight)
	left_foot = from.left_foot.lerp(to.left_foot, weight)
	right_foot = from.right_foot.lerp(to.right_foot, weight)


## The same pose seen in a mirror, for falling the other way.
func mirrored() -> FigurePose:
	var flipped := duplicate() as FigurePose
	flipped.hip_offset.x = -hip_offset.x
	flipped.spine_angle = -spine_angle
	flipped.head_tilt = -head_tilt
	flipped.left_shoulder = right_shoulder
	flipped.right_shoulder = left_shoulder
	flipped.left_elbow = right_elbow
	flipped.right_elbow = left_elbow
	flipped.left_foot = Vector2(-right_foot.x, right_foot.y)
	flipped.right_foot = Vector2(-left_foot.x, left_foot.y)
	return flipped
