@tool
class_name Gorilla
extends InkDrawing
## A doodle: a silverback gorilla, side on and facing right, down on its knuckles. Grey outlines with a
## wash inside draw its body, from the great hump of its shoulders down its sloping back to its rump
## and short near leg; its massive near arm, reaching down to a curled fist on the ground; and its low
## head in front of the hump, with its high crest, heavy brow and jutting muzzle and a single dot eye.
## Its far arm and far leg stand just behind. [GorillaKnife] is the same gorilla holding a knife.
## Its origin is the ground under its middle.

## Palette role of its line.
@export var role := &"secondary":
	set(value):
		role = value
		queue_redraw()
## How strongly the wash inside takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()
## Radius of the dot eye.
@export_range(0.5, 10.0, 0.1) var eye_radius := 3.6:
	set(value):
		eye_radius = value
		queue_redraw()

## The body's outline, from the front of the shoulders over the hump and down the back, round the
## rump, down the bent near leg to its foot and back up it, and along the low belly. The arm and head cover its
## front.
const _BODY := [Vector2(70.0, -150.0), Vector2(54.0, -184.0), Vector2(20.0, -194.0), Vector2(-20.0, -182.0),
		Vector2(-58.0, -156.0), Vector2(-88.0, -128.0), Vector2(-106.0, -102.0), Vector2(-116.0, -78.0),
		Vector2(-112.0, -58.0), Vector2(-100.0, -42.0), Vector2(-102.0, -24.0), Vector2(-106.0, -8.0),
		Vector2(-102.0, 0.0), Vector2(-84.0, 0.0), Vector2(-64.0, 0.0), Vector2(-58.0, -6.0),
		Vector2(-64.0, -14.0), Vector2(-66.0, -28.0), Vector2(-58.0, -46.0), Vector2(-46.0, -58.0),
		Vector2(-20.0, -60.0), Vector2(14.0, -62.0), Vector2(42.0, -70.0), Vector2(60.0, -84.0),
		Vector2(76.0, -110.0)]
## The near arm, from the back of the shoulder down to the curled fist on the ground, round the
## knuckles and back up the front of the arm. The head covers its top.
const _ARM := [Vector2(50.0, -150.0), Vector2(44.0, -120.0), Vector2(52.0, -84.0), Vector2(58.0, -50.0),
		Vector2(62.0, -24.0), Vector2(60.0, -10.0), Vector2(66.0, -1.0), Vector2(86.0, 0.0), Vector2(104.0, -2.0),
		Vector2(110.0, -12.0), Vector2(104.0, -24.0), Vector2(100.0, -48.0), Vector2(104.0, -84.0),
		Vector2(108.0, -118.0), Vector2(100.0, -146.0)]
## The head, from under the jaw round the chin and the muzzle, up over the brow to the crest, and
## down the back of the head.
const _HEAD := [Vector2(80.0, -126.0), Vector2(100.0, -120.0), Vector2(118.0, -124.0), Vector2(130.0, -136.0),
		Vector2(128.0, -148.0), Vector2(120.0, -153.0), Vector2(128.0, -162.0), Vector2(118.0, -172.0),
		Vector2(98.0, -190.0), Vector2(82.0, -186.0), Vector2(70.0, -166.0), Vector2(70.0, -144.0)]
## The far arm and the far leg, each a closed shape just behind its near twin, whose top hides behind the body.
const _FAR_LIMBS := [
	[Vector2(36.0, -96.0), Vector2(32.0, -50.0), Vector2(36.0, -24.0), Vector2(32.0, -8.0), Vector2(38.0, -1.0),
			Vector2(58.0, 0.0), Vector2(74.0, -2.0), Vector2(78.0, -12.0), Vector2(72.0, -24.0), Vector2(74.0, -50.0),
			Vector2(72.0, -96.0)],
	[Vector2(-78.0, -70.0), Vector2(-66.0, -40.0), Vector2(-62.0, -16.0), Vector2(-66.0, -2.0), Vector2(-50.0, 0.0),
			Vector2(-36.0, -1.0), Vector2(-38.0, -12.0), Vector2(-44.0, -40.0), Vector2(-50.0, -70.0)],
]
const _EYE := Vector2(114.0, -156.0)


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var wash := palette.paper.lerp(color, wash_strength)
	var lines: Array[InkLine] = []
	for shape: Array in _FAR_LIMBS + [_BODY, _ARM, _HEAD]:
		var line := InkLine.along(InkBrush.resample_smooth(PackedVector2Array(shape), true, spacing), color, 1.0, true)
		line.fill = wash
		lines.append(line)
	lines.append(InkLine.dot(_EYE, eye_radius, palette.ink))
	return lines
