@tool
class_name TinyDragon
extends InkDrawing
## A doodle: a pet dragon the size of a cat, smug and fireproof. It sits up proudly side on, facing
## right with its chin up: a purple outline runs round its rump, up its back and neck and down its
## chest, and its head with two little horns, its small bat wing, its haunch, its front leg and its
## curling tail are shapes of their own, each with a purple wash inside. Two spikes ride the back of its
## neck, plates cross its throat, it has one dot eye, and a tiny wisp of ink smoke rises from its snout.
## Its origin is the ground under its middle.

## How big the dragon is drawn, as a multiple of its natural size.
@export_range(0.2, 3.0, 0.01) var dragon_scale := 1.0:
	set(value):
		dragon_scale = value
		queue_redraw()
## Palette role of its line.
@export var role := &"purple":
	set(value):
		role = value
		queue_redraw()
## How strongly each wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()
## Radius of the dot eye.
@export_range(0.5, 10.0, 0.1) var eye_radius := 3.6:
	set(value):
		eye_radius = value
		queue_redraw()

## The middle of the tail at natural size, from its root under the rump out along the ground and up
## into a curl.
const _TAIL := [Vector2(-30.0, -12.0), Vector2(-70.0, -6.0), Vector2(-104.0, -12.0), Vector2(-124.0, -32.0),
		Vector2(-122.0, -56.0), Vector2(-104.0, -64.0), Vector2(-92.0, -52.0), Vector2(-98.0, -40.0)]
## Width of the tail at its root. It tapers to a point at the end of the curl.
const _TAIL_WIDTH := 26.0
## The body's outline, from the front of its belly back along the ground, round its rump, up its back
## and the back of its neck, and down its throat and chest.
const _BODY := [Vector2(26.0, -6.0), Vector2(6.0, 0.0), Vector2(-30.0, 0.0), Vector2(-50.0, -14.0),
		Vector2(-58.0, -42.0), Vector2(-52.0, -76.0), Vector2(-38.0, -102.0), Vector2(-22.0, -124.0),
		Vector2(-8.0, -148.0), Vector2(6.0, -168.0), Vector2(20.0, -170.0), Vector2(32.0, -158.0),
		Vector2(32.0, -138.0), Vector2(36.0, -114.0), Vector2(40.0, -88.0), Vector2(40.0, -58.0), Vector2(34.0, -28.0)]
## The head, from the back of the skull over the top and along the snout, and back under the jaw.
const _HEAD := [Vector2(-2.0, -178.0), Vector2(6.0, -194.0), Vector2(24.0, -202.0), Vector2(42.0, -198.0),
		Vector2(60.0, -196.0), Vector2(78.0, -198.0), Vector2(86.0, -188.0), Vector2(78.0, -176.0),
		Vector2(54.0, -170.0), Vector2(30.0, -164.0), Vector2(8.0, -166.0)]
## Each horn: two corners on the head and its tip.
const _HORNS := [[Vector2(4.0, -190.0), Vector2(14.0, -198.0), Vector2(-6.0, -214.0)],
		[Vector2(18.0, -198.0), Vector2(28.0, -201.0), Vector2(14.0, -220.0)]]
## Each spike on the back of the neck: two corners on the neck and its tip.
const _SPIKES := [[Vector2(-5.0, -152.0), Vector2(2.0, -162.0), Vector2(-13.0, -165.0)],
		[Vector2(-18.0, -131.0), Vector2(-11.0, -143.0), Vector2(-26.0, -144.0)]]
## The wing, from the shoulder up its leading edge to the wrist and out to the tip, and back along
## three scallops between the tips of its fingers.
const _WING := [Vector2(-22.0, -110.0), Vector2(-36.0, -146.0), Vector2(-54.0, -178.0), Vector2(-90.0, -170.0),
		Vector2(-66.0, -150.0), Vector2(-98.0, -134.0), Vector2(-66.0, -122.0), Vector2(-82.0, -98.0),
		Vector2(-44.0, -96.0)]
## The wing's finger bones, from its wrist out to the tips between the scallops.
const _FINGERS := [[Vector2(-54.0, -176.0), Vector2(-96.0, -134.0)], [Vector2(-54.0, -176.0), Vector2(-80.0, -100.0)]]
## The middle and half the width and height of the haunch, and of the hind foot in front of it.
const _HAUNCH := [Vector2(-24.0, -36.0), Vector2(32.0, 30.0)]
const _FOOT := [Vector2(4.0, -7.0), Vector2(22.0, 7.0)]
## The near front leg, standing straight down in front of its chest to the paw.
const _FRONT_LEG := [Vector2(24.0, -100.0), Vector2(40.0, -92.0), Vector2(46.0, -62.0), Vector2(48.0, -30.0),
		Vector2(52.0, -12.0), Vector2(64.0, -6.0), Vector2(62.0, 0.0), Vector2(36.0, 0.0), Vector2(31.0, -14.0),
		Vector2(28.0, -46.0), Vector2(22.0, -76.0)]
## The plates across its throat, top to bottom.
const _PLATES := [[Vector2(18.0, -143.0), Vector2(25.0, -146.0), Vector2(32.0, -146.0)],
		[Vector2(19.0, -129.0), Vector2(26.0, -132.0), Vector2(33.0, -132.0)],
		[Vector2(21.0, -115.0), Vector2(28.0, -118.0), Vector2(35.0, -118.0)]]
const _EYE := Vector2(34.0, -186.0)
## The wisp of smoke rising off the end of its snout.
const _SMOKE := [Vector2(88.0, -199.0), Vector2(96.0, -209.0), Vector2(90.0, -220.0), Vector2(97.0, -231.0)]
## How far the whole dragon is moved, so that it, its tail and its smoke are centred on the origin.
const _SHIFT := Vector2(16.0, 0.0)


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var lines: Array[InkLine] = []
	var spine := InkBrush.resample_smooth(_placed(_TAIL), false, spacing)
	lines.append(_washed(_tapered(spine, _TAIL_WIDTH * dragon_scale), color, palette))
	# The spikes and horns come before the body and head, so their washes hide the roots.
	for spike: Array in _SPIKES:
		lines.append(_washed(InkBrush.resample_polyline(_closed(_placed(spike)), spacing), color, palette, 0.8))
	lines.append(_washed(InkBrush.resample_smooth(_placed(_BODY), true, spacing), color, palette))
	lines.append(_washed(InkBrush.resample_smooth(_placed(_WING), true, spacing), color, palette, 0.9))
	for finger: Array in _FINGERS:
		lines.append(InkLine.along(InkBrush.resample_polyline(_placed(finger), spacing), color, 0.7))
	lines.append(_washed(_oval(_HAUNCH, spacing), color, palette, 0.9))
	lines.append(_washed(_oval(_FOOT, spacing), color, palette, 0.9))
	lines.append(_washed(InkBrush.resample_smooth(_placed(_FRONT_LEG), true, spacing), color, palette, 0.9))
	for plate: Array in _PLATES:
		lines.append(InkLine.along(InkBrush.resample_smooth(_placed(plate), false, spacing), color, 0.6))
	for horn: Array in _HORNS:
		lines.append(_washed(InkBrush.resample_polyline(_closed(_placed(horn)), spacing), color, palette, 0.8))
	lines.append(_washed(InkBrush.resample_smooth(_placed(_HEAD), true, spacing), color, palette))
	lines.append(InkLine.dot((_EYE + _SHIFT) * dragon_scale, eye_radius, palette.ink))
	lines.append(InkLine.along(InkBrush.resample_smooth(_placed(_SMOKE), false, spacing), palette.ink, 0.75))
	return lines


## A closed line along [param path] with a wash of its own colour inside.
func _washed(path: PackedVector2Array, color: Color, palette: InkPalette, width := 1.0) -> InkLine:
	var line := InkLine.along(path, color, width, true)
	line.fill = palette.paper.lerp(color, wash_strength)
	return line


## An oval given as its middle and its half width and height, at natural size.
func _oval(shape: Array, spacing: float) -> PackedVector2Array:
	var middle: Vector2 = shape[0]
	var radii: Vector2 = shape[1]
	return InkBrush.ellipse((middle + _SHIFT) * dragon_scale, radii * dragon_scale, spacing, -PI * 0.75)


## [param points] at natural size, moved by [constant _SHIFT] and drawn [member dragon_scale] times as big.
func _placed(points: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point: Vector2 in points:
		out.append((point + _SHIFT) * dragon_scale)
	return out


## [param corners] with the first repeated at the end, to draw them as a closed polyline.
static func _closed(corners: PackedVector2Array) -> PackedVector2Array:
	var out := corners.duplicate()
	out.append(corners[0])
	return out


## A closed outline round [param spine], [param root_width] wide at its start and tapering to a point at its end.
static func _tapered(spine: PackedVector2Array, root_width: float) -> PackedVector2Array:
	var count := spine.size()
	var near := PackedVector2Array()
	var far := PackedVector2Array()
	for i in count:
		var along := spine[mini(i + 1, count - 1)] - spine[maxi(i - 1, 0)]
		var across := along.normalized().orthogonal() * root_width * 0.5 * (1.0 - float(i) / (count - 1))
		near.append(spine[i] + across)
		far.append(spine[i] - across)
	far.reverse()
	near.append_array(far)
	return near
