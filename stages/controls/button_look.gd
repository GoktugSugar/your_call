@tool
class_name ButtonLook
extends Resource
## How one kind of push button looks: the colour washed into its cap and the mark on it. Content names
## a look by its file name in [code]looks/[/code], such as [code]blue[/code], so adding a look is adding a file.

## A mark on the cap. The blue and red buttons carry a ring and a dot, so they never depend on colour alone.
enum Mark { NONE, RING, DOT, MONEY }

## Where each look lives, filled with its name.
const LOOK_PATH := "res://stages/controls/looks/%s.tres"

## Palette role of the wash in the cap.
@export var cap_role := &"secondary"
## The mark drawn on the cap.
@export var mark := Mark.NONE
## How strongly the crayon takes its colour.
@export_range(0.0, 1.0, 0.01) var wash := 0.55


## Whether a look called [param id] exists.
static func exists(id: StringName) -> bool:
	return ResourceLoader.exists(LOOK_PATH % id)


## The look called [param id], or null when there is none.
static func find(id: StringName) -> ButtonLook:
	return load(LOOK_PATH % id) as ButtonLook if exists(id) else null
