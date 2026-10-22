@tool
class_name SoulKind
extends Resource
## One kind of soul a stage can put in harm's way, such as a stranger, a guilty one or a sleeper:
## the drawing it is made from and the few details that set it apart. Content names a kind by its
## file name in this folder, so adding a kind is adding a file.

## Where each kind lives, filled with its name.
const KIND_PATH := "res://figures/kinds/%s.tres"

## The drawing the soul is made from.
@export var scene: PackedScene
## Palette role the whole soul is drawn in, such as red for the guilty. Empty keeps the ink.
@export var color_role := &""
## Size against a grown stranger.
@export_range(0.2, 2.0, 0.01) var size := 1.0

@export_group("Stick figure")
## The pose the figure holds. Empty keeps the scene's.
@export var pose: FigurePose
## Open eyes, eyes closed in sleep, or none for a figure turned away.
@export var eyes := StickFigure.Eyes.OPEN
## How far a pregnant belly bulges, in pixels. Zero for none.
@export_range(0.0, 40.0, 0.5) var belly := 0.0
## Leans on a cane.
@export var cane := false
## Sparse wisps of hair, for the old.
@export var hair := false
## A small beating heart over the head, for the one the player loved.
@export var heart := false
## Z marks drifting up from the head.
@export var snoring := false
## A small crown on the head, for the best life.
@export var crown := false
## A pistol in the hand, for a soul that is armed. The pose says which way it points.
@export var pistol := false
## Falls when the trolley hits. Off for a soul already lying down, which only dissolves.
@export var falls := true


## Whether a kind called [param id] exists.
static func exists(id: StringName) -> bool:
	return ResourceLoader.exists(KIND_PATH % id)


## The kind called [param id], or null when there is none.
static func find(id: StringName) -> SoulKind:
	return load(KIND_PATH % id) as SoulKind if exists(id) else null


## Makes a soul of this kind, ready to be added to a stage.
func make() -> Soul:
	var soul := scene.instantiate() as Soul
	soul.scale = Vector2.ONE * size
	soul.color_override = color_role
	var figure := soul as StickFigure
	if figure != null:
		if pose != null:
			figure.pose = pose
		figure.eyes = eyes
		figure.belly = belly
		figure.cane = cane
		figure.hair = hair
		figure.heart = heart
		figure.snoring = snoring
		figure.crown = crown
		figure.pistol = pistol
		if not falls:
			figure.fold_steps = []
	return soul
