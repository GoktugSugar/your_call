@tool
class_name Soul
extends InkDrawing
## Anything on the stage that can die: a stick figure, a baby in its bundle. Death is the fall, not a
## mark: a soul folds down and dissolves away, with no strike lines and no blood.

## Emitted once a fold has finished and the soul has dissolved away.
signal folded

## Seconds the body takes to dissolve once it is down.
@export_range(0.0, 3.0, 0.01) var fold_fade := 0.5


## Folds the soul down dead toward [param direction] (positive is right), then dissolves it.
## Emits [signal folded]. The default only dissolves; souls with a body to fall override it.
func fold(_direction := 1.0) -> void:
	await dissolve_away(fold_fade).finished
	folded.emit()


## Where something floating over the soul sits, such as a plea, in the soul's own space. The default
## is the soul's origin; souls with a head say just above it.
func head_top() -> Vector2:
	return Vector2.ZERO
