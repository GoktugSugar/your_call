@tool
class_name TinySauropod
extends InkDrawing
## A doodle: a pet dinosaur the size of a dog, sweet and dim. A long necked sauropod side on, facing
## left: one green outline runs from its small head down its long neck, over the round hump of its back
## and out to the tip of its long tail, and back under its belly and up its throat, with a green wash
## inside. It stands on four stumpy legs, the far two peeking out behind the near two, and has one dot
## eye. Its origin is the ground under its middle.

## How big the dinosaur is drawn, as a multiple of its natural size.
@export_range(0.2, 3.0, 0.01) var dinosaur_scale := 0.94:
	set(value):
		dinosaur_scale = value
		queue_redraw()
## Palette role of its line.
@export var role := &"green":
	set(value):
		role = value
		queue_redraw()
## How strongly each wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()
## Radius of the dot eye.
@export_range(0.5, 10.0, 0.1) var eye_radius := 3.4:
	set(value):
		eye_radius = value
		queue_redraw()

## The outline at natural size, from the tip of its nose over its head, down the back of its neck, over
## its back and out along its tail, and back under its tail and belly and up its chest and throat.
const _OUTLINE := [Vector2(-156.0, -194.0), Vector2(-152.0, -208.0), Vector2(-134.0, -216.0), Vector2(-116.0, -208.0),
		Vector2(-106.0, -186.0), Vector2(-92.0, -152.0), Vector2(-76.0, -126.0), Vector2(-52.0, -114.0),
		Vector2(-18.0, -126.0), Vector2(16.0, -130.0), Vector2(48.0, -120.0), Vector2(72.0, -100.0),
		Vector2(96.0, -80.0), Vector2(126.0, -62.0), Vector2(156.0, -48.0), Vector2(182.0, -40.0),
		Vector2(154.0, -36.0), Vector2(122.0, -42.0), Vector2(92.0, -50.0), Vector2(66.0, -48.0),
		Vector2(36.0, -42.0), Vector2(0.0, -40.0), Vector2(-32.0, -46.0), Vector2(-56.0, -62.0),
		Vector2(-70.0, -88.0), Vector2(-84.0, -120.0), Vector2(-100.0, -156.0), Vector2(-114.0, -182.0),
		Vector2(-128.0, -186.0), Vector2(-146.0, -186.0)]
## The legs, the far pair first: each from the top, hidden under the belly, down to the ground.
const _LEGS := [Rect2(-30.0, -64.0, 24.0, 64.0), Rect2(66.0, -60.0, 24.0, 60.0),
		Rect2(-46.0, -60.0, 26.0, 60.0), Rect2(46.0, -56.0, 26.0, 56.0)]
## How round the corners of each leg are.
const _LEG_CORNER := 9.0
const _EYE := Vector2(-136.0, -202.0)
## How far the whole dinosaur is moved, so that its neck and tail together are centred on the origin.
const _SHIFT := Vector2(-16.0, 0.0)


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var lines: Array[InkLine] = []
	# The legs come first, so the body's wash hides their tops.
	for leg: Rect2 in _LEGS:
		var placed := Rect2((leg.position + _SHIFT) * dinosaur_scale, leg.size * dinosaur_scale)
		lines.append(_washed(InkBrush.rounded_rect(placed, _LEG_CORNER * dinosaur_scale, spacing), color, palette, 0.9))
	lines.append(_washed(InkBrush.resample_smooth(_placed(_OUTLINE), true, spacing), color, palette))
	lines.append(InkLine.dot((_EYE + _SHIFT) * dinosaur_scale, eye_radius, palette.ink))
	return lines


## A closed line along [param path] with a wash of its own colour inside.
func _washed(path: PackedVector2Array, color: Color, palette: InkPalette, width := 1.0) -> InkLine:
	var line := InkLine.along(path, color, width, true)
	line.fill = palette.paper.lerp(color, wash_strength)
	return line


## [param points] at natural size, moved by [constant _SHIFT] and drawn [member dinosaur_scale] times as big.
func _placed(points: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point: Vector2 in points:
		out.append((point + _SHIFT) * dinosaur_scale)
	return out
