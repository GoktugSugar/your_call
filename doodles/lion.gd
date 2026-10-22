@tool
class_name Lion
extends InkDrawing
## A doodle: a lion, its body side on and facing right and its face turned to the player. One orange
## outline runs along its back, round its rump, down and up its near legs and along its belly, with a
## wash inside; its far legs stand just behind, its tail ends in a tuft, and a big shaggy mane with a
## deeper wash rings its round face, which has two small ears and dot eyes.
## Its origin is the ground under its middle.

## Palette role of its line.
@export var role := &"orange":
	set(value):
		role = value
		queue_redraw()
## How strongly the wash inside its body and face takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()
## How strongly the wash inside its mane and the tuft of its tail takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var mane_wash_strength := 0.7:
	set(value):
		mane_wash_strength = value
		queue_redraw()
## Radius of each dot eye.
@export_range(0.5, 10.0, 0.1) var eye_radius := 3.6:
	set(value):
		eye_radius = value
		queue_redraw()

## The body's outline, from where its back leaves the mane, round the rump, down the near hind leg and
## back up it, along the belly, down the near foreleg and back up the chest under the mane.
const _BODY := [Vector2(40.0, -134.0), Vector2(2.0, -132.0), Vector2(-38.0, -128.0), Vector2(-78.0, -126.0),
		Vector2(-100.0, -114.0), Vector2(-112.0, -92.0), Vector2(-108.0, -66.0), Vector2(-94.0, -48.0),
		Vector2(-90.0, -14.0), Vector2(-92.0, -2.0), Vector2(-78.0, 0.0), Vector2(-64.0, -2.0), Vector2(-64.0, -14.0),
		Vector2(-68.0, -40.0), Vector2(-60.0, -64.0), Vector2(-38.0, -70.0), Vector2(2.0, -68.0), Vector2(22.0, -64.0),
		Vector2(26.0, -30.0), Vector2(24.0, -12.0), Vector2(22.0, -2.0), Vector2(38.0, 0.0), Vector2(54.0, -2.0),
		Vector2(54.0, -14.0), Vector2(54.0, -40.0), Vector2(60.0, -68.0), Vector2(68.0, -96.0)]
## The far hind leg and far foreleg, each a closed shape whose top hides behind the body.
const _FAR_LEGS := [
	[Vector2(-62.0, -72.0), Vector2(-54.0, -34.0), Vector2(-52.0, -8.0), Vector2(-54.0, -1.0), Vector2(-40.0, 0.0),
			Vector2(-28.0, -1.0), Vector2(-30.0, -10.0), Vector2(-34.0, -36.0), Vector2(-38.0, -72.0)],
	[Vector2(0.0, -72.0), Vector2(0.0, -36.0), Vector2(-2.0, -8.0), Vector2(-4.0, -1.0), Vector2(10.0, 0.0),
			Vector2(22.0, -1.0), Vector2(20.0, -8.0), Vector2(20.0, -36.0), Vector2(22.0, -72.0)],
]
## The tail, from the rump out and up to its tuft.
const _TAIL := [Vector2(-106.0, -106.0), Vector2(-126.0, -110.0), Vector2(-138.0, -128.0), Vector2(-136.0, -150.0)]
## The tuft at the end of the tail.
const _TUFT := [Vector2(-136.0, -146.0), Vector2(-148.0, -154.0), Vector2(-146.0, -170.0), Vector2(-134.0, -172.0),
		Vector2(-126.0, -160.0)]
## The middle of the mane.
const _MANE_CENTER := Vector2(88.0, -142.0)
## How far the mane reaches from its middle, going round clockwise from straight up: a tuft, then the
## notch after it, and so on round. Uneven, and further behind than in front, so it sweeps back shaggily.
const _MANE_REACH := [64.0, 50.0, 60.0, 46.0, 62.0, 50.0, 56.0, 46.0, 58.0, 50.0, 60.0, 48.0, 66.0, 54.0, 70.0,
		52.0, 64.0, 56.0, 74.0, 54.0, 68.0, 56.0, 70.0, 50.0]
const _FACE_CENTER := Vector2(90.0, -140.0)
const _FACE_RADII := Vector2(31.0, 33.0)
## The two ears, peeking over the top of the face. The face hides their lower halves.
const _EARS := [Vector2(72.0, -168.0), Vector2(108.0, -168.0)]
const _EAR_RADIUS := 9.0
const _EYES := [Vector2(80.0, -144.0), Vector2(100.0, -144.0)]


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var wash := palette.paper.lerp(color, wash_strength)
	var mane_wash := palette.paper.lerp(color, mane_wash_strength)
	var lines: Array[InkLine] = []
	for leg: Array in _FAR_LEGS:
		lines.append(_washed(InkBrush.resample_smooth(PackedVector2Array(leg), true, spacing), color, wash))
	lines.append(InkLine.along(InkBrush.resample_smooth(PackedVector2Array(_TAIL), false, spacing), color))
	lines.append(_washed(InkBrush.resample_smooth(PackedVector2Array(_TUFT), true, spacing), color, mane_wash))
	lines.append(_washed(InkBrush.resample_smooth(PackedVector2Array(_BODY), true, spacing), color, wash))
	lines.append(_washed(InkBrush.resample_smooth(_mane(), true, spacing), color, mane_wash))
	for ear: Vector2 in _EARS:
		lines.append(_washed(InkBrush.ellipse(ear, Vector2.ONE * _EAR_RADIUS, spacing * 0.5, PI), color, wash))
	lines.append(_washed(InkBrush.ellipse(_FACE_CENTER, _FACE_RADII, spacing, -PI * 0.75), color, wash))
	for eye: Vector2 in _EYES:
		lines.append(InkLine.dot(eye, eye_radius, palette.ink))
	return lines


## The mane's tufts and notches, round its middle.
static func _mane() -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in _MANE_REACH.size():
		var angle := -PI * 0.5 + TAU * i / _MANE_REACH.size()
		points.append(_MANE_CENTER + Vector2.from_angle(angle) * float(_MANE_REACH[i]))
	return points


## A closed line along [param path] with [param wash] inside.
static func _washed(path: PackedVector2Array, color: Color, wash: Color) -> InkLine:
	var line := InkLine.along(path, color, 1.0, true)
	line.fill = wash
	return line
