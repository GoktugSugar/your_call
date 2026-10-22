@tool
class_name Toddler
extends InkDrawing
## A doodle: a toddler, facing the player. A big round head with dot eyes and a single curl of hair
## sits on a chubby little body with a wash inside; its short arms are flung up and its stubby legs
## splay out to little round feet, and it leans a touch to one side, wobbling. All of it is drawn in
## one colour. Many of them stand in for a crowd. Its origin is the ground between its feet.

## Palette role of its line.
@export var role := &"orange":
	set(value):
		role = value
		queue_redraw()
## How strongly the wash inside its body, hands and feet takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()
## Radius of its head.
@export_range(4.0, 60.0, 0.5) var head_radius := 36.0:
	set(value):
		head_radius = value
		queue_redraw()
## Radius of each dot eye.
@export_range(0.5, 10.0, 0.1) var eye_radius := 3.6:
	set(value):
		eye_radius = value
		queue_redraw()
## How far it leans over from its feet, in degrees, positive to the screen right.
@export_range(-20.0, 20.0, 0.5) var lean := 4.0:
	set(value):
		lean = value
		queue_redraw()

## Everything above the hips leans about this point, between its feet.
const _PIVOT := Vector2(0.0, -6.0)
const _HEAD := Vector2(0.0, -112.0)
const _EYES := [Vector2(-12.0, -108.0), Vector2(12.0, -108.0)]
## The curl of hair, from the top of the head up and round.
const _CURL := [Vector2(0.0, -147.0), Vector2(3.0, -160.0), Vector2(-4.0, -168.0), Vector2(-11.0, -161.0),
		Vector2(-5.0, -154.0)]
## The body's outline, round from the screen left of the neck. Its top tucks under the head.
const _BODY := [Vector2(-18.0, -74.0), Vector2(-30.0, -64.0), Vector2(-36.0, -44.0), Vector2(-32.0, -26.0),
		Vector2(-16.0, -18.0), Vector2(0.0, -17.0), Vector2(16.0, -18.0), Vector2(32.0, -26.0), Vector2(36.0, -44.0),
		Vector2(30.0, -64.0), Vector2(18.0, -74.0), Vector2(0.0, -77.0)]
## Each arm, shoulder to elbow to hand, screen left first, flung up: one out wide for balance, one high.
const _ARMS := [[Vector2(-24.0, -62.0), Vector2(-42.0, -72.0), Vector2(-56.0, -92.0)],
		[Vector2(24.0, -62.0), Vector2(36.0, -78.0), Vector2(44.0, -98.0)]]
const _HAND_RADIUS := 6.0
## Each leg, hip to knee to ankle, screen left first, splayed and bowed.
const _LEGS := [[Vector2(-14.0, -22.0), Vector2(-22.0, -12.0), Vector2(-24.0, -6.0)],
		[Vector2(14.0, -22.0), Vector2(19.0, -12.0), Vector2(26.0, -6.0)]]
## Each foot's middle and its half width and height, screen left first. The feet stay on the ground
## as it leans.
const _FEET := [Vector2(-27.0, -5.0), Vector2(29.0, -5.0)]
const _FOOT_RADII := Vector2(10.0, 5.0)


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var wash := palette.paper.lerp(color, wash_strength)
	var lines: Array[InkLine] = []
	for i in _LEGS.size():
		# The hips lean with the body; the knees and ankles stay where they stand.
		var leg_points: Array = _LEGS[i]
		var leg := PackedVector2Array(leg_points)
		leg[0] = _leaned(leg[0])
		lines.append(InkLine.along(InkBrush.resample_polyline(leg, spacing), color))
		var foot: Vector2 = _FEET[i]
		lines.append(_washed(InkBrush.ellipse(foot, _FOOT_RADII, spacing * 0.5, PI), color, wash))
	for arm: Array in _ARMS:
		var limb := _all_leaned(arm)
		lines.append(InkLine.along(InkBrush.resample_polyline(limb, spacing), color))
		var hand := InkBrush.ellipse(limb[limb.size() - 1], Vector2.ONE * _HAND_RADIUS, spacing * 0.5)
		lines.append(_washed(hand, color, wash))
	lines.append(_washed(InkBrush.resample_smooth(_all_leaned(_BODY), true, spacing), color, wash))
	var head := InkLine.along(InkBrush.ellipse(_leaned(_HEAD), Vector2.ONE * head_radius, spacing, -PI * 0.75), color, 1.0, true)
	head.fill = palette.paper
	lines.append(head)
	lines.append(InkLine.along(InkBrush.resample_smooth(_all_leaned(_CURL), false, spacing * 0.5), color, 0.9))
	for eye: Vector2 in _EYES:
		lines.append(InkLine.dot(_leaned(eye), eye_radius, palette.ink))
	return lines


## [param point] leaned over about the pivot by [member lean].
func _leaned(point: Vector2) -> Vector2:
	return _PIVOT + (point - _PIVOT).rotated(deg_to_rad(lean))


## Every one of [param points], leaned over.
func _all_leaned(points: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point: Vector2 in points:
		out.append(_leaned(point))
	return out


## A closed line along [param path] with [param wash] inside.
static func _washed(path: PackedVector2Array, color: Color, wash: Color) -> InkLine:
	var line := InkLine.along(path, color, 1.0, true)
	line.fill = wash
	return line
