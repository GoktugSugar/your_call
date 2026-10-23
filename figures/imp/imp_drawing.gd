@tool
class_name ImpDrawing
extends InkDrawing
## The imp's body in ink: a crude little devil, all corners, with a lumpy head, long thin horns,
## sly slanted eyes over a wide grin, a boxy body, stubby bent arms that float beside it, and a
## crooked tail with a square tip. His line is heavier and jitters more than the rest of the page.
## Unlike every soul, he has a mouth and a few faces, and each face opens its mouth its own way as he
## talks. His origin is the ground between his feet. Both arms join the body at the shoulders, and his
## legs can stand or hang loose under him as he floats.
## [Imp] animates the lean, the nod, the crouch, the arms, the tail, the legs and the jitter, and
## [ImpMouth] the mouth; this only draws them.

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
## How loose his legs hang: 0 stands him on his feet, 1 lets them dangle under him, toes down, as he
## floats.
@export_range(0.0, 1.0, 0.01) var dangle := 0.0:
	set(value):
		dangle = value
		queue_redraw()
## How far his hanging legs swing from his hips, in degrees. Positive swings them right.
@export_range(-45.0, 45.0, 0.1) var leg_swing := 0.0:
	set(value):
		leg_swing = value
		queue_redraw()
## Where his line is in its jitter, counted in shapes. [Imp] moves it along.
@export var jitter_phase := 0.0:
	set(value):
		jitter_phase = value
		queue_redraw()
## Off, his line jumps from shape to shape like hand-drawn ink. On, it melts smoothly between them.
@export var smooth_jitter := false:
	set(value):
		smooth_jitter = value
		queue_redraw()
## Palette role of his ink.
@export var tint_role: StringName = &"imp":
	set(value):
		tint_role = value
		queue_redraw()

@export_group("Mouth")
## How far his mouth is open as he talks: 0 is his face's own mouth, 1 as wide as that face opens.
@export_range(0.0, 1.0, 0.001) var mouth_open := 0.0:
	set(value):
		mouth_open = value
		queue_redraw()
## How open his mouth must be before his lips part. Below it, his mouth is drawn shut in his face's own shape.
@export_range(0.0, 1.0, 0.01) var lips_part_at := 0.12:
	set(value):
		lips_part_at = value
		queue_redraw()
## How far his lips part at the least, as a share of how far they go, so a parted mouth always shows
## its inside rather than a thickened line.
@export_range(0.0, 1.0, 0.01) var least_parting := 0.45:
	set(value):
		least_parting = value
		queue_redraw()
## Palette role of the wash inside his open mouth.
@export var mouth_wash_role: StringName = &"ink":
	set(value):
		mouth_wash_role = value
		queue_redraw()
## How strongly the wash inside his open mouth takes its colour over the paper. Zero leaves it blank.
@export_range(0.0, 1.0, 0.01) var mouth_wash := 0.0:
	set(value):
		mouth_wash = value
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
## The same legs hanging loose under him, the feet tipped toes down.
const _LEFT_LEG_HANGING := [Vector2(-10.5, -12.6), Vector2(-13.3, 0.7), Vector2(-19.7, 8.3)]
const _RIGHT_LEG_HANGING := [Vector2(8.4, -12.6), Vector2(10.5, 0.7), Vector2(16.9, 8.3)]
const _TAIL := [Vector2(22.4, -24.5), Vector2(33.6, -29.4), Vector2(38.5, -26.6), Vector2(52.5, -33.6),
		Vector2(56.0, -42.0), Vector2(61.6, -60.9)]
const _TAIL_TIP := [Vector2(56.0, -79.1), Vector2(67.9, -81.9), Vector2(72.8, -68.6), Vector2(63.0, -65.8)]

const _SLY_LEFT_EYE := [Vector2(-16.1, -109.2), Vector2(-4.2, -101.5)]
const _SLY_RIGHT_EYE := [Vector2(16.1, -109.2), Vector2(4.2, -101.5)]
const _HOODED_RIGHT_EYE := [Vector2(4.0, -103.0), Vector2(17.0, -104.5)]
const _GLARE_LEFT_EYE := [Vector2(-17.5, -112.5), Vector2(-4.0, -100.5)]
const _GLARE_RIGHT_EYE := [Vector2(17.5, -112.5), Vector2(4.0, -100.5)]
const _GRIN := [Vector2(-13.0, -94.5), Vector2(-8.0, -88.5), Vector2(0.0, -86.0), Vector2(8.0, -88.5), Vector2(13.0, -94.5)]
const _SMIRK := [Vector2(-10.0, -89.5), Vector2(0.0, -87.5), Vector2(9.0, -89.5), Vector2(14.0, -95.5)]
const _FROWN := [Vector2(-11.0, -86.5), Vector2(0.0, -90.5), Vector2(11.0, -86.5)]
const _SURPRISED_EYES := [Vector2(-10.0, -105.0), Vector2(10.0, -105.0)]
const _SURPRISED_EYE_RADIUS := 5.0
## His eyes are bold marks, heavier than the rest of him, so they read at any size. His grin is finer.
const _EYE_WIDTH := 1.35
const _GLARE_EYE_WIDTH := 1.45
const _MOUTH_WIDTH := 0.95
const _SURPRISED_MOUTH := Vector2(0.0, -88.5)
const _SURPRISED_MOUTH_RADII := Vector2(5.0, 6.5)
const _SURPRISED_MOUTH_WIDTH := 0.8

## Each face's mouth open as wide as it goes while he talks, as its upper and lower lip, which share
## their corners. Each fills the room between his eyes and his chin. The grin opens into a wide
## grinning mouth, flat across the top.
const _GRIN_OPEN_TOP := [Vector2(-15.0, -96.0), Vector2(-8.0, -94.0), Vector2(0.0, -93.5), Vector2(8.0, -94.0), Vector2(15.0, -96.0)]
const _GRIN_OPEN_BOTTOM := [Vector2(-15.0, -96.0), Vector2(-10.0, -86.0), Vector2(0.0, -82.0), Vector2(10.0, -86.0), Vector2(15.0, -96.0)]
## The smirk opens on its curled side and stays shut at the other corner.
const _SMIRK_OPEN_TOP := [Vector2(-11.0, -89.5), Vector2(-2.0, -91.0), Vector2(7.0, -94.5), Vector2(15.0, -96.5)]
const _SMIRK_OPEN_BOTTOM := [Vector2(-11.0, -89.5), Vector2(-2.0, -86.5), Vector2(8.0, -84.0), Vector2(15.0, -96.5)]
## The frown opens into a squared snarl, its corners pulled down.
const _SNARL_TOP := [Vector2(-12.5, -84.5), Vector2(-6.0, -93.5), Vector2(6.0, -93.5), Vector2(12.5, -84.5)]
const _SNARL_BOTTOM := [Vector2(-12.5, -84.5), Vector2(-5.0, -82.0), Vector2(5.0, -82.0), Vector2(12.5, -84.5)]
## The O grows from its middle as it opens, out to a wider, taller O than the one it rests in.
const _SURPRISED_OPEN_MOUTH := Vector2(0.0, -90.5)
const _SURPRISED_OPEN_RADII := Vector2(6.5, 8.5)
## The open mouth's outline is finer than the closed one, so the dark inside shows at his size.
const _OPEN_MOUTH_WIDTH := 0.75


## The face called [param face_name], such as [code]smug[/code], or his grin when it names none he has.
static func face_named(face_name: StringName) -> Face:
	var key := String(face_name).to_upper() if face_name != &"" else "GRIN"
	return Face.get(key, Face.GRIN)


func _init() -> void:
	style_override = LINE_STYLE


func _variant() -> float:
	var phase := fposmod(jitter_phase, float(maxi(style_override.boil_variants if style_override != null else 1, 1)))
	return phase if smooth_jitter else floorf(phase)


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
	# Standing, his feet keep to the ground whatever his body does; hanging, they go where his hips do.
	var hanging := body * _rotation_about(_HIPS, leg_swing)
	for leg: Array in [[_LEFT_LEG, _LEFT_LEG_HANGING], [_RIGHT_LEG, _RIGHT_LEG_HANGING]]:
		var standing: Array = leg[0]
		var loose: Array = leg[1]
		var points := PackedVector2Array([body * (standing[0] as Vector2)])
		for i in range(1, standing.size()):
			points.append((standing[i] as Vector2).lerp(hanging * (loose[i] as Vector2), dangle))
		lines.append(InkLine.along(InkBrush.resample_polyline(points, spacing), tint))
	lines.append(_line(tail, _TAIL, tint, spacing))
	lines.append(_closed_line(tail, _TAIL_TIP, tint, spacing, 0.85))
	_add_face(lines, head, tint, palette.paper.lerp(palette.color(mouth_wash_role), mouth_wash), spacing)
	return lines


func _add_face(lines: Array[InkLine], head: Transform2D, tint: Color, wash: Color, spacing: float) -> void:
	var parted := mouth_open > 0.0 and mouth_open >= lips_part_at
	match face:
		Face.GRIN:
			lines.append(_line(head, _SLY_LEFT_EYE, tint, spacing, _EYE_WIDTH))
			lines.append(_line(head, _SLY_RIGHT_EYE, tint, spacing, _EYE_WIDTH))
			lines.append(_open_mouth(head, _GRIN_OPEN_TOP, _GRIN_OPEN_BOTTOM, tint, wash, spacing, true) if parted
					else _smooth_line(head, _GRIN, tint, spacing))
		Face.SMUG:
			lines.append(_line(head, _SLY_LEFT_EYE, tint, spacing, _EYE_WIDTH))
			lines.append(_line(head, _HOODED_RIGHT_EYE, tint, spacing, _EYE_WIDTH))
			lines.append(_open_mouth(head, _SMIRK_OPEN_TOP, _SMIRK_OPEN_BOTTOM, tint, wash, spacing, true) if parted
					else _smooth_line(head, _SMIRK, tint, spacing))
		Face.GLARE:
			lines.append(_line(head, _GLARE_LEFT_EYE, tint, spacing, _GLARE_EYE_WIDTH))
			lines.append(_line(head, _GLARE_RIGHT_EYE, tint, spacing, _GLARE_EYE_WIDTH))
			lines.append(_open_mouth(head, _SNARL_TOP, _SNARL_BOTTOM, tint, wash, spacing, false) if parted
					else _smooth_line(head, _FROWN, tint, spacing))
		Face.SURPRISED:
			for eye: Vector2 in _SURPRISED_EYES:
				lines.append(InkLine.along(InkBrush.ellipse(head * eye, Vector2.ONE * _SURPRISED_EYE_RADIUS, spacing * 0.5),
						tint, 0.7, true))
			if parted:
				# Open, the O grows from its middle as the lips part, like every other mouth.
				var o := InkLine.along(InkBrush.ellipse(head * _SURPRISED_OPEN_MOUTH, _SURPRISED_OPEN_RADII * _parting(),
						spacing * 0.5), tint, _OPEN_MOUTH_WIDTH, true)
				o.fill = wash
				lines.append(o)
			else:
				lines.append(InkLine.along(InkBrush.ellipse(head * _SURPRISED_MOUTH, _SURPRISED_MOUTH_RADII, spacing * 0.5),
						tint, _SURPRISED_MOUTH_WIDTH, true))


## How far his lips are parted, from [member least_parting] as they first part to 1 at their widest.
func _parting() -> float:
	var share := clampf((mouth_open - lips_part_at) / maxf(1.0 - lips_part_at, 0.001), 0.0, 1.0)
	return lerpf(least_parting, 1.0, share)


## His mouth open: one ink outline round lips parted [method _parting] of the way from their shared
## middle line to [param top] and [param bottom], with [param wash] inside. [param smooth] curves the
## lips; otherwise they keep their corners.
func _open_mouth(head: Transform2D, top: Array, bottom: Array, tint: Color, wash: Color, spacing: float, smooth: bool) -> InkLine:
	var parting := _parting()
	var upper := PackedVector2Array()
	var lower := PackedVector2Array()
	for i in top.size():
		var top_point: Vector2 = top[i]
		var bottom_point: Vector2 = bottom[i]
		var middle := (top_point + bottom_point) * 0.5
		upper.append(head * middle.lerp(top_point, parting))
		lower.append(head * middle.lerp(bottom_point, parting))
	lower.reverse()
	# Round the upper lip from corner to corner, then back along the lower one to where it started.
	var outline := _lip(upper, spacing, smooth)
	outline.append_array(_lip(lower, spacing, smooth).slice(1))
	var line := InkLine.along(outline, tint, _OPEN_MOUTH_WIDTH, true)
	line.fill = wash
	return line


static func _lip(points: PackedVector2Array, spacing: float, smooth: bool) -> PackedVector2Array:
	return InkBrush.resample_smooth(points, false, spacing) if smooth else InkBrush.resample_polyline(points, spacing)


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
