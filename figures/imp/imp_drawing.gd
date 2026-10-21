@tool
class_name ImpDrawing
extends InkDrawing
## The imp's body in ink: a small devil with horns, a grin and a spade tipped tail, drawn in his own tint.
## Unlike every soul, he has a mouth and a few expressions. His origin is the ground between his feet.
## [Imp] animates the lean, the nod and the expression; this only draws them.

enum Face { GRIN, SMUG, GLARE, SURPRISED }

## His expression.
@export var face: Face = Face.GRIN:
	set(value):
		face = value
		queue_redraw()
## How far his upper body leans from the hips, in degrees. Positive leans right.
@export_range(-30.0, 30.0, 0.1) var lean := 0.0:
	set(value):
		lean = value
		queue_redraw()
## How far his head tips on his neck, in degrees. Positive tips right.
@export_range(-30.0, 30.0, 0.1) var head_tilt := 0.0:
	set(value):
		head_tilt = value
		queue_redraw()
## How far his body sinks at the knees, in pixels.
@export_range(-10.0, 10.0, 0.1) var crouch := 0.0:
	set(value):
		crouch = value
		queue_redraw()
## Palette role of his ink.
@export var tint_role: StringName = &"imp":
	set(value):
		tint_role = value
		queue_redraw()
## Radius of his dot eyes.
@export_range(1.0, 8.0, 0.1) var eye_radius := 3.4:
	set(value):
		eye_radius = value
		queue_redraw()

const _HIPS := Vector2(0.0, -24.0)
const _NECK := Vector2(0.0, -64.0)
const _BODY_CENTER := Vector2(0.0, -43.0)
const _BODY_RADII := Vector2(16.0, 21.0)
const _HEAD_CENTER := Vector2(0.0, -86.0)
const _HEAD_RADII := Vector2(24.0, 22.0)
const _LEFT_LEG := [Vector2(-6.0, -24.0), Vector2(-9.0, -3.0), Vector2(-17.0, -1.0)]
const _LEFT_ARM := [Vector2(-13.0, -56.0), Vector2(-29.0, -46.0), Vector2(-16.0, -37.0)]
const _LEFT_HORN := [Vector2(-17.0, -102.0), Vector2(-22.0, -112.0), Vector2(-25.0, -127.0), Vector2(-17.0, -114.0), Vector2(-9.0, -107.0)]
const _TAIL := [Vector2(10.0, -30.0), Vector2(24.0, -26.0), Vector2(34.0, -34.0), Vector2(35.0, -48.0), Vector2(41.0, -58.0)]
const _TAIL_TIP := [Vector2(46.0, -70.0), Vector2(50.0, -56.0), Vector2(43.0, -59.0), Vector2(36.0, -61.0)]
const _GRIN := [Vector2(-17.0, -83.0), Vector2(-14.0, -79.0), Vector2(-7.0, -75.0), Vector2(0.0, -74.0), Vector2(7.0, -75.0), Vector2(14.0, -79.0), Vector2(17.0, -83.0)]
const _SMIRK := [Vector2(-11.0, -77.0), Vector2(-3.0, -76.0), Vector2(6.0, -77.0), Vector2(13.0, -81.0), Vector2(15.0, -85.0)]
const _FLAT_MOUTH := [Vector2(-9.0, -77.0), Vector2(0.0, -77.5), Vector2(9.0, -77.0)]
const _EYE := Vector2(9.0, -89.0)


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var tint := palette.color(tint_role)
	var sink := Transform2D(0.0, Vector2(0.0, crouch))
	var upper := sink * _rotation_about(_HIPS, lean)
	var head := upper * _rotation_about(_NECK, head_tilt)
	var lines: Array[InkLine] = []

	lines.append(InkLine.along(_ellipse(head, _HEAD_CENTER, _HEAD_RADII, spacing), tint, 1.0, true))
	lines.append(InkLine.along(_ellipse(upper, _BODY_CENTER, _BODY_RADII, spacing), tint, 1.0, true))
	for side: float in [1.0, -1.0]:
		lines.append(_polyline(head, _mirror(_LEFT_HORN, side), tint, spacing))
	for side: float in [1.0, -1.0]:
		lines.append(_polyline(upper, _mirror(_LEFT_ARM, side), tint, spacing))
	for side: float in [1.0, -1.0]:
		var leg := _mirror(_LEFT_LEG, side)
		leg[0] = sink * leg[0]
		lines.append(InkLine.along(InkBrush.resample_polyline(leg, spacing), tint))
	lines.append(InkLine.along(InkBrush.resample_smooth(_transformed(upper, _TAIL), false, spacing), tint))
	var tip := InkLine.along(InkBrush.resample_polyline(_closed(_transformed(upper, _TAIL_TIP)), spacing), tint, 0.8, true)
	tip.fill = tint
	lines.append(tip)
	_add_face(lines, head, tint, spacing)
	return lines


func _add_face(lines: Array[InkLine], head: Transform2D, tint: Color, spacing: float) -> void:
	var left_eye := head * Vector2(-_EYE.x, _EYE.y)
	var right_eye := head * _EYE
	match face:
		Face.GRIN:
			lines.append(InkLine.dot(left_eye, eye_radius, tint))
			lines.append(InkLine.dot(right_eye, eye_radius, tint))
			lines.append(InkLine.along(InkBrush.resample_smooth(_transformed(head, _GRIN), false, spacing), tint, 0.9))
		Face.SMUG:
			lines.append(InkLine.dot(left_eye + head.basis_xform(Vector2(0.0, 1.0)), eye_radius * 0.85, tint))
			lines.append(InkLine.dot(right_eye + head.basis_xform(Vector2(0.0, 1.0)), eye_radius * 0.85, tint))
			for eye: Vector2 in [left_eye, right_eye]:
				var lid := PackedVector2Array([eye + head.basis_xform(Vector2(-6.0, -2.0)), eye + head.basis_xform(Vector2(6.0, -3.0))])
				lines.append(InkLine.along(InkBrush.resample_polyline(lid, spacing), tint, 0.7))
			lines.append(InkLine.along(InkBrush.resample_smooth(_transformed(head, _SMIRK), false, spacing), tint, 0.9))
		Face.GLARE:
			lines.append(InkLine.dot(left_eye, eye_radius, tint))
			lines.append(InkLine.dot(right_eye, eye_radius, tint))
			for side: float in [-1.0, 1.0]:
				var brow := PackedVector2Array([head * Vector2(side * 15.0, -98.0), head * Vector2(side * 4.0, -94.0)])
				lines.append(InkLine.along(InkBrush.resample_polyline(brow, spacing), tint, 0.8))
			lines.append(InkLine.along(InkBrush.resample_smooth(_transformed(head, _FLAT_MOUTH), false, spacing), tint, 0.9))
		Face.SURPRISED:
			for eye: Vector2 in [left_eye, right_eye]:
				lines.append(InkLine.along(InkBrush.ellipse(eye, Vector2.ONE * eye_radius * 1.6, spacing * 0.5), tint, 0.6, true))
			lines.append(InkLine.along(InkBrush.ellipse(head * Vector2(0.0, -76.0), Vector2(4.0, 5.0), spacing * 0.5), tint, 0.8, true))


func _polyline(xform: Transform2D, points: Variant, tint: Color, spacing: float) -> InkLine:
	return InkLine.along(InkBrush.resample_polyline(_transformed(xform, points), spacing), tint)


func _ellipse(xform: Transform2D, center: Vector2, radii: Vector2, spacing: float) -> PackedVector2Array:
	return _transformed(xform, InkBrush.ellipse(center, radii, spacing, -PI * 0.7))


## [param points] may be an Array of Vector2 or a PackedVector2Array.
static func _transformed(xform: Transform2D, points: Variant) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point: Vector2 in points:
		out.append(xform * point)
	return out


static func _mirror(points: Variant, side: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point: Vector2 in points:
		out.append(Vector2(point.x * side, point.y))
	return out


static func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var out := points.duplicate()
	out.append(points[0])
	return out


static func _rotation_about(pivot: Vector2, degrees: float) -> Transform2D:
	return Transform2D(0.0, pivot) * Transform2D(deg_to_rad(degrees), Vector2.ZERO) * Transform2D(0.0, -pivot)
