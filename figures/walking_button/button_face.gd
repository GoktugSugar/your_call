@tool
class_name ButtonFace
extends InkDrawing
## The walking button's face: two dot eyes on its cap and nothing else, the same bare face every figure
## has. The eyes look the way the button faces, pop wide when it is startled, and shut as curved lids,
## like a stick figure's, for a blink or a wince. [WalkingButton] keeps them on the cap; this only draws
## them. Its space is the body's.

enum Eyes { HIDDEN, CLOSED, OPEN }

## Open dot eyes, eyes shut, or none at all for a plain button.
@export var eyes := Eyes.HIDDEN:
	set(value):
		eyes = value
		queue_redraw()
## Where the middle of the cap is.
@export var cap_middle := Vector2(0.0, -95.2):
	set(value):
		cap_middle = value
		queue_redraw()
## Radius of the cap. The eyes are sized and spaced as shares of it.
@export_range(1.0, 300.0, 0.5) var cap_radius := 70.0:
	set(value):
		cap_radius = value
		queue_redraw()
## Which way the eyes look: -1 left, 0 out of the page, 1 right.
@export_range(-1.0, 1.0, 0.01) var look := 0.0:
	set(value):
		look = value
		queue_redraw()
## Size of the eyes now, as a multiple of their resting size: above 1 they are wide with a start.
@export_range(0.0, 3.0, 0.01) var eye_scale := 1.0:
	set(value):
		eye_scale = value
		queue_redraw()

@export_group("Eyes")
## Radius of each dot eye, as a share of the cap's radius.
@export_range(0.01, 0.5, 0.005) var eye_size := 0.1:
	set(value):
		eye_size = value
		queue_redraw()
## How far each eye sits from the middle of the cap, as a share of its radius.
@export_range(0.0, 0.8, 0.005) var eye_spread := 0.27:
	set(value):
		eye_spread = value
		queue_redraw()
## How far above the middle of the cap the eyes sit, as a share of its radius.
@export_range(-0.8, 0.8, 0.005) var eye_height := 0.12:
	set(value):
		eye_height = value
		queue_redraw()
## How far the eyes shift the way they look, as a share of the cap's radius.
@export_range(0.0, 0.8, 0.005) var look_shift := 0.3:
	set(value):
		look_shift = value
		queue_redraw()
## Size of a shut lid, as a multiple of the eye's radius.
@export_range(0.1, 4.0, 0.05) var lid_size := 1.5:
	set(value):
		lid_size = value
		queue_redraw()
## Width of a shut lid's line, as a multiple of the line width.
@export_range(0.1, 3.0, 0.05) var lid_width := 0.8:
	set(value):
		lid_width = value
		queue_redraw()

## A shut eye's lid, as a share of the eye's radius: the curve a stick figure closes its eyes with.
const _LID := [Vector2(-0.85, -0.1), Vector2(0.0, 0.55), Vector2(0.85, -0.1)]


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var lines: Array[InkLine] = []
	if eyes == Eyes.HIDDEN or eye_scale <= 0.0:
		return lines
	var radius := cap_radius * eye_size * eye_scale
	for side: float in [-1.0, 1.0]:
		var eye := cap_middle + Vector2(side * eye_spread + look * look_shift, -eye_height) * cap_radius
		if eyes == Eyes.OPEN:
			lines.append(InkLine.dot(eye, radius, palette.ink))
			continue
		var lid := PackedVector2Array()
		for point: Vector2 in _LID:
			lid.append(eye + point * radius * lid_size)
		lines.append(InkLine.along(InkBrush.resample_smooth(lid, false, style.sample_spacing * 0.5), palette.ink, lid_width))
	return lines
