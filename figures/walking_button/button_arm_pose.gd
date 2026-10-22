@tool
class_name ButtonArmPose
extends Resource
## How the walking button holds its arms. The front arm is the one on the side it faces, and the screen
## right arm while it faces out of the page, so a pose turns with it. Angles are in degrees, the way a
## [FigurePose] holds a stick figure's arms: a shoulder swings its arm away from hanging straight down,
## positive out to the side and on up over its head, and an elbow bends the forearm further out.
## Content names a pose by its file name in [code]arms/[/code], such as [code]fist[/code], so adding a pose is adding a file.

## Where each pose lives, filled with its name.
const POSE_PATH := "res://figures/walking_button/arms/%s.tres"

## Swing of the front arm away from hanging straight down.
@export_range(-180.0, 180.0, 0.5) var front_shoulder := 58.0
## Bend at the front elbow.
@export_range(-170.0, 170.0, 0.5) var front_elbow := -40.0
## Swing of the back arm away from hanging straight down.
@export_range(-180.0, 180.0, 0.5) var back_shoulder := 58.0
## Bend at the back elbow.
@export_range(-170.0, 170.0, 0.5) var back_elbow := -40.0
## Clenches the front hand into a fist.
@export var front_fist := false
## Clenches the back hand into a fist.
@export var back_fist := false
## How far the front forearm shakes either way, in degrees, stepped with the page's boil. Zero holds it still.
@export_range(0.0, 60.0, 0.5) var shake := 0.0

@export_group("Arriving")
## Seconds the arms take to move into this pose.
@export_range(0.0, 5.0, 0.01) var arrive_duration := 0.22
## The curve of that move.
@export var arrive_transition := Tween.TRANS_SINE
## Which end of the move the curve eases.
@export var arrive_ease := Tween.EASE_IN_OUT


## Whether a pose called [param id] exists.
static func exists(id: StringName) -> bool:
	return ResourceLoader.exists(POSE_PATH % id)


## The pose called [param id], or null when there is none.
static func find(id: StringName) -> ButtonArmPose:
	return load(POSE_PATH % id) as ButtonArmPose if exists(id) else null


## Sets this pose part way between [param from] and [param to]: 0 is [param from], 1 is [param to].
## A hand clenches or opens halfway through.
func blend(from: ButtonArmPose, to: ButtonArmPose, weight: float) -> void:
	front_shoulder = lerpf(from.front_shoulder, to.front_shoulder, weight)
	front_elbow = lerpf(from.front_elbow, to.front_elbow, weight)
	back_shoulder = lerpf(from.back_shoulder, to.back_shoulder, weight)
	back_elbow = lerpf(from.back_elbow, to.back_elbow, weight)
	front_fist = to.front_fist if weight >= 0.5 else from.front_fist
	back_fist = to.back_fist if weight >= 0.5 else from.back_fist
	shake = lerpf(from.shake, to.shake, weight)
