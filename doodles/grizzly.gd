@tool
class_name Grizzly
extends InkDrawing
## A doodle: a grizzly bear up on its hind legs, facing the player with both arms raised high. Brown
## outlines with a brown wash inside draw its heavy body on short planted legs, its round head with an
## open bump of an ear either side and dot eyes, and its two thick arms reaching up and out to wide
## paws, each tipped with three short strokes of claw. Its origin is the ground between its feet.

## Palette role of its line.
@export var role := &"brown":
	set(value):
		role = value
		queue_redraw()
## How strongly the wash inside takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()
## Palette role of the claws.
@export var claw_role := &"ink":
	set(value):
		claw_role = value
		queue_redraw()
## Radius of each dot eye.
@export_range(0.5, 10.0, 0.1) var eye_radius := 3.6:
	set(value):
		eye_radius = value
		queue_redraw()

## The body's outline, from under the head down the screen left side, round both feet and the gap
## between the legs, and up the screen right side.
const _BODY := [Vector2(-40.0, -146.0), Vector2(-56.0, -126.0), Vector2(-64.0, -96.0), Vector2(-64.0, -64.0),
		Vector2(-58.0, -36.0), Vector2(-58.0, -14.0), Vector2(-62.0, -2.0), Vector2(-44.0, 0.0), Vector2(-24.0, -2.0),
		Vector2(-20.0, -16.0), Vector2(0.0, -26.0), Vector2(20.0, -16.0), Vector2(24.0, -2.0), Vector2(44.0, 0.0),
		Vector2(62.0, -2.0), Vector2(58.0, -14.0), Vector2(58.0, -36.0), Vector2(64.0, -64.0), Vector2(64.0, -96.0),
		Vector2(56.0, -126.0), Vector2(40.0, -146.0), Vector2(0.0, -152.0)]
## The head's outline, from the chin round the screen left cheek, over both ears and back down, the
## ears open bumps on it.
const _HEAD := [Vector2(0.0, -139.0), Vector2(-16.0, -142.0), Vector2(-28.0, -154.0), Vector2(-32.0, -170.0),
		Vector2(-31.0, -184.0), Vector2(-28.0, -192.0), Vector2(-32.0, -202.0), Vector2(-26.0, -212.0),
		Vector2(-15.0, -212.0), Vector2(-10.0, -203.0), Vector2(0.0, -205.0), Vector2(10.0, -203.0),
		Vector2(15.0, -212.0), Vector2(26.0, -212.0), Vector2(32.0, -202.0), Vector2(28.0, -192.0),
		Vector2(31.0, -184.0), Vector2(32.0, -170.0), Vector2(28.0, -154.0), Vector2(16.0, -142.0)]
const _EYES := [Vector2(-11.0, -174.0), Vector2(11.0, -174.0)]
## The screen left arm, from inside the shoulder up its inner edge, round the paw and back down its
## outer edge; the right mirrors it.
const _ARM := [Vector2(-30.0, -136.0), Vector2(-46.0, -160.0), Vector2(-62.0, -186.0), Vector2(-66.0, -200.0),
		Vector2(-80.0, -210.0), Vector2(-96.0, -204.0), Vector2(-102.0, -188.0), Vector2(-94.0, -172.0),
		Vector2(-78.0, -146.0), Vector2(-62.0, -118.0)]
## The claws on the screen left paw, each from its root on the paw to its tip; the right mirror them.
const _CLAWS := [[Vector2(-68.0, -204.0), Vector2(-66.0, -216.0)], [Vector2(-80.0, -211.0), Vector2(-82.0, -224.0)],
		[Vector2(-93.0, -207.0), Vector2(-100.0, -218.0)]]
## Width of a claw's line, as a multiple of the line's width.
const _CLAW_WIDTH := 0.7


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var wash := palette.paper.lerp(color, wash_strength)
	var lines: Array[InkLine] = []
	# The arms come first, so the body's wash hides where they join it.
	for side: float in [1.0, -1.0]:
		lines.append(_washed(InkBrush.resample_smooth(_mirrored(_ARM, side), true, spacing), color, wash))
	lines.append(_washed(InkBrush.resample_smooth(PackedVector2Array(_BODY), true, spacing), color, wash))
	lines.append(_washed(InkBrush.resample_smooth(PackedVector2Array(_HEAD), true, spacing), color, wash))
	var claw_color := palette.color(claw_role)
	for side: float in [1.0, -1.0]:
		for claw: Array in _CLAWS:
			lines.append(InkLine.along(InkBrush.resample_polyline(_mirrored(claw, side), spacing), claw_color, _CLAW_WIDTH))
	for eye: Vector2 in _EYES:
		lines.append(InkLine.dot(eye, eye_radius, palette.ink))
	return lines


## A closed line along [param path] with [param wash] inside.
static func _washed(path: PackedVector2Array, color: Color, wash: Color) -> InkLine:
	var line := InkLine.along(path, color, 1.0, true)
	line.fill = wash
	return line


static func _mirrored(points: Array, side: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point: Vector2 in points:
		out.append(Vector2(point.x * side, point.y))
	return out
