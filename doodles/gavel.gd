@tool
class_name Gavel
extends InkDrawing
## A doodle: a judge's gavel and its round sounding block, seen from the side and a little from above.
## The block is a short drum with a groove round its side; the gavel is a barrel shaped head with a ring
## near either end, on a tapering handle with a knob at its end. Resting, the gavel leans with its head
## stood on the block and the knob of its handle on the ground; raised, it turns about the end of its
## handle until its head is lifted high over the knob and tipped back past upright, ready to come down.
## Its line is brown, with a brown wash in the wood and a paler one on the block's top. Its origin is the
## ground under the middle of the resting gavel, and raising it never moves the block or the knob.

## How far the gavel is raised: 0 rests its head on the block, 1 lifts it high and tips it back.
@export_range(0.0, 1.0, 0.001) var raised := 0.0:
	set(value):
		raised = value
		queue_redraw()
## How big the gavel and its block are drawn, as a multiple of their natural size.
@export_range(0.2, 3.0, 0.01) var gavel_scale := 1.0:
	set(value):
		gavel_scale = value
		queue_redraw()
## How far past upright the raised gavel tips back over its knob, in degrees.
@export_range(-30.0, 60.0, 0.5) var tip_back := 12.0:
	set(value):
		tip_back = value
		queue_redraw()
## Palette role of the gavel's and the block's line.
@export var role := &"brown":
	set(value):
		role = value
		queue_redraw()
## How strongly the wood's wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()
## How strongly the block's top takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var top_wash := 0.25:
	set(value):
		top_wash = value
		queue_redraw()

## The block at natural size: its radius across, how deep its round top looks seen from above, and how
## tall its side is.
const _BLOCK := Vector3(46.0, 12.0, 22.0)
## How far down the block's side its groove runs, as a share of the side.
const _GROOVE := 0.5
## The gavel, drawn from the end of its handle along the handle to the middle of its head: how far that
## is, how long the head is and how thick.
const _REACH := 128.0
const _HEAD := Vector2(68.0, 30.0)
## Radius of the head's rounded ends, and how far in from each end its rings run.
const _HEAD_CORNER := 7.0
const _RING_INSET := 11.0
## How thick the handle is where it meets the head and near its end, and the radius of the knob at its end.
const _HANDLE := Vector2(11.0, 7.5)
const _KNOB_RADIUS := 7.0
## How high the knob's middle sits off the ground while the gavel rests.
const _KNOB_HEIGHT := 10.0
## Widths of the head's rings and the block's groove, as multiples of the drawing's line width.
const _RING_LINE := 0.6
const _GROOVE_LINE := 0.55


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	# Built at natural size, so its spacing there is the page's shrunk by the gavel's scale.
	var spacing := style.sample_spacing / gavel_scale
	var color := palette.color(role)
	var wash := palette.paper.lerp(color, wash_strength)
	var lines: Array[InkLine] = []
	# The resting gavel stands its head's face on the middle of the block's top, so how far the block's top
	# lies from the knob settles how the gavel leans; the knob is set so the resting gavel is centred.
	var top_y := -_BLOCK.y - _BLOCK.z
	var face := Vector2(-_REACH, _HEAD.x * 0.5)
	var drop := top_y + _KNOB_HEIGHT
	var across := -sqrt(maxf(face.length_squared() - drop * drop, 0.0))
	var knob := Vector2((_BLOCK.x - _KNOB_RADIUS - across) * 0.5, -_KNOB_HEIGHT)
	var block := Vector2(knob.x + across, top_y)
	var rest := angle_difference(face.angle(), Vector2(across, drop).angle())
	var turn := lerpf(rest, PI * 0.5 + deg_to_rad(tip_back), raised)
	lines.append_array(_block_lines(block, palette, color, wash, spacing))
	lines.append_array(_gavel_lines(Transform2D(turn, knob), color, wash, spacing))
	var place := Transform2D(0.0, Vector2.ONE * gavel_scale, 0.0, Vector2.ZERO)
	for line in lines:
		line.path = place * line.path
		line.dot_radius *= gavel_scale
	return lines


## The sounding block, the middle of its top at [param top]: its side, its groove and its top.
func _block_lines(top: Vector2, palette: InkPalette, color: Color, wash: Color, spacing: float) -> Array[InkLine]:
	var lines: Array[InkLine] = []
	var radii := Vector2(_BLOCK.x, _BLOCK.y)
	var foot := top + Vector2(0.0, _BLOCK.z)
	# The side: over the back of the top from its left end, down the right, round the front of the foot
	# and up the left.
	var side := _half_ellipse(top, radii, PI, spacing)
	side.append_array(_half_ellipse(foot, radii, 0.0, spacing))
	lines.append(_washed(InkBrush.resample_polyline(_closed(side), spacing), color, wash))
	var groove := _half_ellipse(top + Vector2(0.0, _BLOCK.z * _GROOVE), radii, 0.0, spacing)
	lines.append(InkLine.along(groove, color, _GROOVE_LINE))
	lines.append(_washed(InkBrush.ellipse(top, radii, spacing, PI), color, palette.paper.lerp(color, top_wash)))
	return lines


## The gavel placed by [param lay], which takes it from its own frame: the end of its handle at the origin,
## the handle running back along -x to the middle of the head, the head's face toward +y.
func _gavel_lines(lay: Transform2D, color: Color, wash: Color, spacing: float) -> Array[InkLine]:
	var lines: Array[InkLine] = []
	var head_back := -_REACH + _HEAD.y * 0.5
	var handle := PackedVector2Array([Vector2(head_back - _HEAD_CORNER, -_HANDLE.x * 0.5),
			Vector2(-_KNOB_RADIUS, -_HANDLE.y * 0.5), Vector2(-_KNOB_RADIUS, _HANDLE.y * 0.5),
			Vector2(head_back - _HEAD_CORNER, _HANDLE.x * 0.5)])
	lines.append(_washed(lay * InkBrush.resample_polyline(_closed(handle), spacing), color, wash))
	lines.append(_washed(lay * InkBrush.ellipse(Vector2.ZERO, Vector2.ONE * _KNOB_RADIUS, spacing * 0.5), color, wash))
	var head := Rect2(-_REACH - _HEAD.y * 0.5, -_HEAD.x * 0.5, _HEAD.y, _HEAD.x)
	lines.append(_washed(lay * InkBrush.rounded_rect(head, _HEAD_CORNER, spacing), color, wash))
	for way: float in [-1.0, 1.0]:
		var y := way * (_HEAD.x * 0.5 - _RING_INSET)
		var ring := PackedVector2Array([Vector2(head.position.x, y), Vector2(head.end.x, y)])
		lines.append(InkLine.along(lay * InkBrush.resample_polyline(ring, spacing), color, _RING_LINE))
	return lines


## Half the ellipse round [param middle] with [param radii], from [param from] (radians) on through half
## a turn, as points about [param spacing] apart, both ends included.
static func _half_ellipse(middle: Vector2, radii: Vector2, from: float, spacing: float) -> PackedVector2Array:
	var steps := maxi(2, ceili(PI * sqrt((radii.x * radii.x + radii.y * radii.y) * 0.5) / spacing))
	var out := PackedVector2Array()
	for k in steps + 1:
		var angle := from + PI * k / steps
		out.append(middle + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	return out


## [param corners] with the first repeated at the end, to draw them as a closed polyline.
static func _closed(corners: PackedVector2Array) -> PackedVector2Array:
	var out := corners.duplicate()
	out.append(corners[0])
	return out


## A closed line along [param path] with [param wash] inside it.
static func _washed(path: PackedVector2Array, color: Color, wash: Color) -> InkLine:
	var line := InkLine.along(path, color, 1.0, true)
	line.fill = wash
	return line
