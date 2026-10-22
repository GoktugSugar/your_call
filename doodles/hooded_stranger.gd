@tool
class_name HoodedStranger
extends InkDrawing
## A doodle: the stranger on the road. A figure standing facing out, all cloak: the cloak falls from its
## shoulders and flares out to a wavy hem on the ground, parted down the front with a fold either side,
## and a deep hood with a soft peak tipped to one side sits over it, fastened at the throat with a round
## clasp. Inside the hood is only shadow and two dot eyes. Its line is purple, with a purple wash in the
## cloak and the hood, a stronger one in the clasp, and a dark wash in the hood's shadow. Its origin is
## the ground under its middle.

## Palette role of its line.
@export var role := &"purple":
	set(value):
		role = value
		queue_redraw()
## Palette role of its eyes.
@export var eye_role := &"ink":
	set(value):
		eye_role = value
		queue_redraw()
## How strongly the cloak's and the hood's wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()
## How strongly the clasp's wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var clasp_wash := 0.8:
	set(value):
		clasp_wash = value
		queue_redraw()
## How dark the shadow in the hood is: how far its wash goes from the cloak's wash toward the ink.
@export_range(0.0, 1.0, 0.01) var shadow_darkness := 0.5:
	set(value):
		shadow_darkness = value
		queue_redraw()
## Radius of each dot eye.
@export_range(0.5, 10.0, 0.1) var eye_radius := 4.6:
	set(value):
		eye_radius = value
		queue_redraw()

## The cloak at natural size, from under the hood at the left of the neck, down its left side to the hem,
## along the wavy hem on the ground and up its right side.
const _CLOAK := [Vector2(-34.0, -150.0), Vector2(-56.0, -138.0), Vector2(-64.0, -112.0), Vector2(-70.0, -70.0),
		Vector2(-78.0, -30.0), Vector2(-86.0, -6.0), Vector2(-66.0, -1.0), Vector2(-44.0, -5.0), Vector2(-22.0, 0.0),
		Vector2(0.0, -4.0), Vector2(22.0, 0.0), Vector2(44.0, -5.0), Vector2(66.0, -1.0), Vector2(86.0, -6.0),
		Vector2(78.0, -30.0), Vector2(70.0, -70.0), Vector2(64.0, -112.0), Vector2(56.0, -138.0), Vector2(34.0, -150.0)]
## Where the cloak parts down its front, from under the clasp to the hem, and a fold either side rising
## from the hem.
const _CLOAK_LINES := [[Vector2(0.0, -112.0), Vector2(2.0, -72.0), Vector2(-2.0, -34.0), Vector2(0.0, -6.0)],
		[Vector2(-44.0, -7.0), Vector2(-40.0, -40.0), Vector2(-43.0, -72.0)],
		[Vector2(44.0, -7.0), Vector2(42.0, -44.0), Vector2(46.0, -78.0)]]
## The hood, in smooth runs that meet in its corners: up its left side from where it drapes on the left
## shoulder to the peak, down its right side to the right shoulder, and back along its lower edge across
## the chest.
const _HOOD := [
	[Vector2(-52.0, -132.0), Vector2(-58.0, -158.0), Vector2(-54.0, -186.0), Vector2(-40.0, -208.0),
			Vector2(-18.0, -222.0), Vector2(12.0, -228.0)],
	[Vector2(12.0, -228.0), Vector2(30.0, -216.0), Vector2(46.0, -198.0), Vector2(56.0, -174.0),
			Vector2(58.0, -152.0), Vector2(52.0, -132.0)],
	[Vector2(52.0, -132.0), Vector2(34.0, -122.0), Vector2(12.0, -117.0), Vector2(-12.0, -117.0),
			Vector2(-34.0, -122.0), Vector2(-52.0, -132.0)],
]
## The opening of the hood, all shadow, from its top round its left side, under the chin and up its right.
const _OPENING := [Vector2(0.0, -206.0), Vector2(-20.0, -197.0), Vector2(-30.0, -175.0), Vector2(-28.0, -151.0),
		Vector2(-16.0, -135.0), Vector2(0.0, -131.0), Vector2(16.0, -135.0), Vector2(28.0, -151.0),
		Vector2(30.0, -175.0), Vector2(20.0, -197.0)]
const _EYES := [Vector2(-11.0, -168.0), Vector2(11.0, -168.0)]
## The clasp at the throat: its middle and its radius.
const _CLASP := Vector2(0.0, -118.0)
const _CLASP_RADIUS := 7.0
## Width of the cloak's parting and folds, and of the clasp's line, as multiples of the drawing's line width.
const _CLOAK_LINE := 0.7
const _CLASP_LINE := 0.8


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var wash := palette.paper.lerp(color, wash_strength)
	var lines: Array[InkLine] = []
	lines.append(_washed(InkBrush.resample_smooth(PackedVector2Array(_CLOAK), true, spacing), color, wash))
	for mark: Array in _CLOAK_LINES:
		lines.append(InkLine.along(InkBrush.resample_smooth(PackedVector2Array(mark), false, spacing), color, _CLOAK_LINE))
	var hood := PackedVector2Array()
	for run: Array in _HOOD:
		var part := InkBrush.resample_smooth(PackedVector2Array(run), false, spacing)
		hood.append_array(part if hood.is_empty() else part.slice(1))
	lines.append(_washed(hood, color, wash))
	var shadow := wash.lerp(palette.ink, shadow_darkness)
	lines.append(_washed(InkBrush.resample_smooth(PackedVector2Array(_OPENING), true, spacing), color, shadow))
	for eye: Vector2 in _EYES:
		lines.append(InkLine.dot(eye, eye_radius, palette.color(eye_role)))
	var clasp := InkBrush.ellipse(_CLASP, Vector2.ONE * _CLASP_RADIUS, spacing * 0.5, -PI * 0.5)
	lines.append(_washed(clasp, color, palette.paper.lerp(color, clasp_wash), _CLASP_LINE))
	return lines


## A closed line along [param path] with [param wash] inside it, [param width] times the drawing's
## line width.
static func _washed(path: PackedVector2Array, color: Color, wash: Color, width := 1.0) -> InkLine:
	var line := InkLine.along(path, color, width, true)
	line.fill = wash
	return line
