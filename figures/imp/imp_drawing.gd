@tool
class_name ImpDrawing
extends InkDrawing
## The imp's body in ink: a crude little devil, all corners, with a lumpy head, long thin horns,
## sly slanted eyes over a wide grin, a boxy body, stubby bent arms that float beside it, and a
## crooked tail with a square tip. His line is heavier and jitters more than the rest of the page.
## Unlike every soul, he has a mouth and a few faces. His origin is the ground between his feet.
## Both arms join the body at the shoulders.
## [Imp] animates the lean, the nod, the crouch, the arms, the tail and the jitter; this only draws them.

enum Face { GRIN, SMUG, GLARE, SURPRISED }

## His expression.
@export var face: Face = Face.GRIN:
	set(value):
		face = value
		queue_redraw()
## How far his body leans from the hips, in degrees. Positive leans right.
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
## How far his arms lift at the shoulders, in degrees.
@export_range(-60.0, 60.0, 0.1) var arm_lift := 0.0:
	set(value):
		arm_lift = value
		queue_redraw()
## How far his tail swings from its root, in degrees. Positive swings it up.
@export_range(-45.0, 45.0, 0.1) var tail_swing := 0.0:
	set(value):
		tail_swing = value
		queue_redraw()
## Where his line is in its wavering, in shapes: between two whole numbers his line melts from one
## shape to the next. [Imp] moves it along smoothly.
@export var jitter_phase := 0.0:
	set(value):
		jitter_phase = value
		queue_redraw()
## Palette role of his ink.
@export var tint_role: StringName = &"imp":
	set(value):
		tint_role = value
		queue_redraw()

## His line: heavier and jitterier than the rest of the page.
const LINE_STYLE := preload("res://figures/imp/imp_ink_style.tres")

const _HIPS := Vector2(0.0, -12.0)
const _NECK := Vector2(0.0, -75.0)
const _TAIL_ROOT := Vector2(22.4, -24.5)
const _HEAD := [Vector2(-16.1, -122.5), Vector2(-8.4, -127.8), Vector2(0.4, -129.5), Vector2(9.1, -127.8),
		Vector2(16.8, -122.5), Vector2(24.9, -119.7), Vector2(27.7, -110.3), Vector2(27.3, -98.0),
		Vector2(24.9, -89.3), Vector2(19.6, -80.5), Vector2(12.6, -77.7), Vector2(3.9, -76.0),
		Vector2(-4.9, -75.3), Vector2(-11.2, -78.8), Vector2(-18.2, -83.3), Vector2(-24.2, -86.8),
		Vector2(-26.6, -94.5), Vector2(-28.7, -101.5), Vector2(-25.9, -112.0), Vector2(-21.7, -117.3)]
const _BODY := [Vector2(-10.5, -72.8), Vector2(-28.0, -53.9), Vector2(-23.8, -25.2), Vector2(-9.8, -12.6),
		Vector2(7.0, -12.6), Vector2(21.7, -23.8), Vector2(28.0, -51.1), Vector2(10.5, -72.8)]
const _LEFT_HORN := [Vector2(-16.8, -123.9), Vector2(-25.0, -142.0), Vector2(-32.2, -158.9)]
const _RIGHT_HORN := [Vector2(17.5, -123.9), Vector2(26.5, -141.0), Vector2(35.0, -157.5)]
const _LEFT_ARM := [Vector2(-16.0, -66.0), Vector2(-43.4, -59.5), Vector2(-44.1, -47.6)]
const _RIGHT_ARM := [Vector2(16.0, -66.0), Vector2(43.4, -59.5), Vector2(44.1, -47.6)]
const _LEFT_LEG := [Vector2(-10.5, -12.6), Vector2(-16.1, -2.1), Vector2(-25.9, -0.7)]
const _RIGHT_LEG := [Vector2(8.4, -12.6), Vector2(13.3, -2.8), Vector2(23.8, 0.0)]
const _TAIL := [Vector2(22.4, -24.5), Vector2(33.6, -29.4), Vector2(38.5, -26.6), Vector2(52.5, -33.6),
		Vector2(56.0, -42.0), Vector2(61.6, -60.9)]
const _TAIL_TIP := [Vector2(56.0, -79.1), Vector2(67.9, -81.9), Vector2(72.8, -68.6), Vector2(63.0, -65.8)]

const _SLY_LEFT_EYE := [Vector2(-16.1, -109.2), Vector2(-4.2, -101.5)]
const _SLY_RIGHT_EYE := [Vector2(16.1, -109.2), Vector2(4.2, -101.5)]
const _HOODED_RIGHT_EYE := [Vector2(4.0, -103.0), Vector2(17.0, -104.5)]
const _GLARE_LEFT_EYE := [Vector2(-17.5, -112.5), Vector2(-4.0, -100.5)]
const _GLARE_RIGHT_EYE := [Vector2(17.5, -112.5), Vector2(4.0, -100.5)]
const _GRIN := [Vector2(-18.9, -94.5), Vector2(-13.0, -86.0), Vector2(0.0, -81.0), Vector2(13.0, -86.0), Vector2(18.9, -94.5)]
const _SMIRK := [Vector2(-14.0, -88.5), Vector2(0.0, -85.5), Vector2(12.0, -88.0), Vector2(19.0, -96.0)]
const _FROWN := [Vector2(-15.0, -84.0), Vector2(0.0, -89.0), Vector2(15.0, -84.0)]
const _SURPRISED_EYES := [Vector2(-10.0, -105.0), Vector2(10.0, -105.0)]
const _SURPRISED_EYE_RADIUS := 5.0
## His eyes are bold marks, heavier than the rest of him, so they read at any size. His grin is finer.
const _EYE_WIDTH := 1.35
const _GLARE_EYE_WIDTH := 1.45
const _MOUTH_WIDTH := 0.75
const _SURPRISED_MOUTH := Vector2(0.0, -88.0)
const _SURPRISED_MOUTH_RADII := Vector2(5.0, 6.5)


func _init() -> void:
	style_override = LINE_STYLE


func _variant() -> float:
	return fposmod(jitter_phase, float(maxi(style_override.boil_variants if style_override != null else 1, 1)))


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var tint := palette.color(tint_role)
	var sink := Transform2D(0.0, Vector2(0.0, crouch))
	var body := sink * _rotation_about(_HIPS, lean)
	var head := body * _rotation_about(_NECK, head_tilt)
	var tail := body * _rotation_about(_TAIL_ROOT, -tail_swing)
	var lines: Array[InkLine] = []

	lines.append(_closed_line(head, _HEAD, tint, spacing))
	lines.append(_closed_line(body, _BODY, tint, spacing))
	lines.append(_line(head, _LEFT_HORN, tint, spacing))
	lines.append(_line(head, _RIGHT_HORN, tint, spacing))
	lines.append(_line(body * _rotation_about(_LEFT_ARM[0], arm_lift), _LEFT_ARM, tint, spacing))
	lines.append(_line(body * _rotation_about(_RIGHT_ARM[0], -arm_lift), _RIGHT_ARM, tint, spacing))
	for leg: Array in [_LEFT_LEG, _RIGHT_LEG]:
		var points := PackedVector2Array(leg)
		points[0] = body * points[0]
		lines.append(InkLine.along(InkBrush.resample_polyline(points, spacing), tint))
	lines.append(_line(tail, _TAIL, tint, spacing))
	lines.append(_closed_line(tail, _TAIL_TIP, tint, spacing, 0.85))
	_add_face(lines, head, tint, spacing)
	return lines


func _add_face(lines: Array[InkLine], head: Transform2D, tint: Color, spacing: float) -> void:
	match face:
		Face.GRIN:
			lines.append(_line(head, _SLY_LEFT_EYE, tint, spacing, _EYE_WIDTH))
			lines.append(_line(head, _SLY_RIGHT_EYE, tint, spacing, _EYE_WIDTH))
			lines.append(_smooth_line(head, _GRIN, tint, spacing))
		Face.SMUG:
			lines.append(_line(head, _SLY_LEFT_EYE, tint, spacing, _EYE_WIDTH))
			lines.append(_line(head, _HOODED_RIGHT_EYE, tint, spacing, _EYE_WIDTH))
			lines.append(_smooth_line(head, _SMIRK, tint, spacing))
		Face.GLARE:
			lines.append(_line(head, _GLARE_LEFT_EYE, tint, spacing, _GLARE_EYE_WIDTH))
			lines.append(_line(head, _GLARE_RIGHT_EYE, tint, spacing, _GLARE_EYE_WIDTH))
			lines.append(_smooth_line(head, _FROWN, tint, spacing))
		Face.SURPRISED:
			for eye: Vector2 in _SURPRISED_EYES:
				lines.append(InkLine.along(InkBrush.ellipse(head * eye, Vector2.ONE * _SURPRISED_EYE_RADIUS, spacing * 0.5),
						tint, 0.7, true))
			lines.append(InkLine.along(InkBrush.ellipse(head * _SURPRISED_MOUTH, _SURPRISED_MOUTH_RADII, spacing * 0.5),
					tint, 0.8, true))


static func _line(xform: Transform2D, points: Array, tint: Color, spacing: float, width := 1.0) -> InkLine:
	return InkLine.along(InkBrush.resample_polyline(_transformed(xform, points), spacing), tint, width)


static func _closed_line(xform: Transform2D, points: Array, tint: Color, spacing: float, width := 1.0) -> InkLine:
	var corners := _transformed(xform, points)
	corners.append(corners[0])
	return InkLine.along(InkBrush.resample_polyline(corners, spacing), tint, width, true)


static func _smooth_line(xform: Transform2D, points: Array, tint: Color, spacing: float) -> InkLine:
	return InkLine.along(InkBrush.resample_smooth(_transformed(xform, points), false, spacing), tint, _MOUTH_WIDTH)


static func _transformed(xform: Transform2D, points: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point: Vector2 in points:
		out.append(xform * point)
	return out


static func _rotation_about(pivot: Vector2, degrees: float) -> Transform2D:
	return Transform2D(0.0, pivot) * Transform2D(deg_to_rad(degrees), Vector2.ZERO) * Transform2D(0.0, -pivot)
