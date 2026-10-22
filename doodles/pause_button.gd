@tool
class_name PauseButton
extends RewindButton
## A doodle: the same round push button as [RewindButton], with a pause symbol on its cap.

## Width and height of each pause bar.
@export var bar_size := Vector2(16.0, 46.0):
	set(value):
		bar_size = value
		queue_redraw()
## Gap between the two bars.
@export_range(0.0, 60.0, 0.5) var bar_gap := 14.0:
	set(value):
		bar_gap = value
		queue_redraw()
## Radius of each bar's rounded corners.
@export_range(0.0, 20.0, 0.5) var bar_corner := 4.0:
	set(value):
		bar_corner = value
		queue_redraw()

## Sample spacing for the small rounded bars, finer than a whole line's.
const _BAR_SPACING := 2.0


func _symbol(middle: Vector2) -> Array[PackedVector2Array]:
	var shapes: Array[PackedVector2Array] = []
	for side: float in [-1.0, 1.0]:
		var left := middle.x + (bar_gap * 0.5 if side > 0.0 else -bar_gap * 0.5 - bar_size.x)
		var bar := Rect2(left, middle.y - bar_size.y * 0.5, bar_size.x, bar_size.y)
		shapes.append(InkBrush.rounded_rect(bar, bar_corner, _BAR_SPACING))
	return shapes
