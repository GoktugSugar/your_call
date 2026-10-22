@tool
class_name BabyBundle
extends Soul
## A baby, swaddled in a bundle and lying on its back on the rails: a round head with dot eyes and a
## curl of hair, poking out of a blanket wrapped across. Its origin is the ground under the middle of it.

## Width and height of the bundle.
@export var bundle_size := Vector2(40.0, 22.0):
	set(value):
		bundle_size = value
		queue_redraw()
## Radius of the head.
@export_range(2.0, 30.0, 0.5) var head_radius := 10.5:
	set(value):
		head_radius = value
		queue_redraw()
## Radius of each dot eye.
@export_range(0.5, 6.0, 0.1) var eye_radius := 1.7:
	set(value):
		eye_radius = value
		queue_redraw()
## How far each eye sits from the middle of the face.
@export_range(0.0, 10.0, 0.1) var eye_spread := 3.2:
	set(value):
		eye_spread = value
		queue_redraw()
## Gap between the top of the head and anything floating over it, in pixels.
@export_range(0.0, 80.0, 0.5) var float_gap := 12.0


## Where something floating over the baby sits: just above the top of its head, in its own space.
func head_top() -> Vector2:
	return _head_centre() + Vector2.UP * (head_radius + float_gap)


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var lines: Array[InkLine] = []
	var body := _blanket()
	var blanket := InkLine.along(InkBrush.rounded_rect(body, bundle_size.y * 0.48, spacing), palette.ink, 1.0, true)
	blanket.fill = palette.paper
	lines.append(blanket)
	var wrap := PackedVector2Array([body.position + Vector2(body.size.x * 0.32, 0.0),
			body.position + Vector2(body.size.x * 0.5, body.size.y * 0.55), body.end - Vector2(body.size.x * 0.28, 0.0)])
	lines.append(InkLine.along(InkBrush.resample_smooth(wrap, false, spacing * 0.5), palette.ink, 0.8))
	var head := _head_centre()
	var face := InkLine.along(InkBrush.ellipse(head, Vector2.ONE * head_radius, spacing, -PI * 0.6), palette.ink, 1.0, true)
	face.fill = palette.paper
	lines.append(face)
	var curl := PackedVector2Array([head + Vector2(-2.0, -head_radius), head + Vector2(0.5, -head_radius - 4.0),
			head + Vector2(3.0, -head_radius - 2.0), head + Vector2(1.5, -head_radius - 0.5)])
	lines.append(InkLine.along(InkBrush.resample_smooth(curl, false, spacing * 0.5), palette.ink, 0.6))
	for side: float in [-1.0, 1.0]:
		lines.append(InkLine.dot(head + Vector2(eye_spread * side, -0.5), eye_radius, palette.ink))
	return lines


## The blanket the baby is wrapped in, lying on the ground, with room on its right for the head.
func _blanket() -> Rect2:
	return Rect2(-bundle_size.x * 0.5 - head_radius * 0.5, -bundle_size.y, bundle_size.x, bundle_size.y)


## The middle of the head, poking out of the right end of the blanket.
func _head_centre() -> Vector2:
	return Vector2(_blanket().end.x + head_radius * 0.55, -head_radius - 1.0)
