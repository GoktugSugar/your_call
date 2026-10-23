@tool
class_name CigarettePack
extends InkDrawing
## A doodle: a pack of cigarettes, seen from the front with its lid flipped open behind it and three
## cigarettes poking out of it at different heights. The pack is red with a red wash and a blank band
## across its front; each cigarette is an ink tube with paper inside and a line round its filter.
## Its origin is the ground under its middle.

## Width and height of the pack, below its open lid.
@export var pack_size := Vector2(120.0, 156.0):
	set(value):
		pack_size = value
		queue_redraw()
## How far the open lid rises above the pack.
@export_range(0.0, 120.0, 0.5) var lid_height := 48.0:
	set(value):
		lid_height = value
		queue_redraw()
## Width of each cigarette.
@export_range(4.0, 60.0, 0.5) var cigarette_width := 28.0:
	set(value):
		cigarette_width = value
		queue_redraw()
## Palette role of the pack and its lid.
@export var role := &"red":
	set(value):
		role = value
		queue_redraw()
## How strongly the pack's wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()

## Radius of the pack's rounded corners.
const _CORNER := 6.0
## How much wider the open lid's far edge is than the pack, each side, as it leans back.
const _LID_FLARE := 5.0
## How far down from the open lid's far edge the fold of its top runs across it.
const _LID_FOLD := 12.0
## Width of the cigarettes' lines and of the line round each filter, as multiples of the drawing's
## line width: finer than the pack's, so they stay apart when the pack is drawn small.
const _CIGARETTE_LINE := 0.85
const _FILTER_LINE := 0.6
## Each cigarette: how far its middle sits right of the pack's middle, and how far it pokes out above the pack.
const _CIGARETTES := [Vector2(-32.0, 44.0), Vector2(-3.0, 64.0), Vector2(27.0, 30.0)]
## How far each cigarette reaches down into the pack, out of sight.
const _TUCK := 16.0
## Radius of the rounded corners of each cigarette's tip.
const _TIP_CORNER := 5.0
## Length of each filter, from the tip down.
const _FILTER := 24.0
## The band across the pack's front: its lower and upper edge, as fractions of the pack's height.
const _BAND := Vector2(0.38, 0.62)


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var wash := palette.paper.lerp(color, wash_strength)
	var ink := palette.ink
	var half := pack_size.x * 0.5
	var top := -pack_size.y
	var lines: Array[InkLine] = []
	# The lid is behind everything, the cigarettes stand in front of it, and the pack hides their feet.
	# The lid's line stops at its hinge, which the top of the pack draws.
	var hinge := PackedVector2Array([Vector2(-half, top), Vector2(-half - _LID_FLARE, top - lid_height),
			Vector2(half + _LID_FLARE, top - lid_height), Vector2(half, top)])
	var lid := InkLine.along(InkBrush.resample_polyline(hinge, spacing), color)
	lid.fill = wash
	lines.append(lid)
	if lid_height > _LID_FOLD:
		# The fold runs from side to side of the lid, whose sides lean out as they rise.
		var fold_half := half + _LID_FLARE * (1.0 - _LID_FOLD / lid_height)
		var fold_y := top - lid_height + _LID_FOLD
		var fold := PackedVector2Array([Vector2(-fold_half, fold_y), Vector2(fold_half, fold_y)])
		lines.append(InkLine.along(InkBrush.resample_polyline(fold, spacing), color, 0.7))
	for cigarette: Vector2 in _CIGARETTES:
		var left := cigarette.x - cigarette_width * 0.5
		var tip := top - cigarette.y
		var tube := InkLine.along(InkBrush.rounded_rect(Rect2(left, tip, cigarette_width, cigarette.y + _TUCK),
				_TIP_CORNER, spacing), ink, _CIGARETTE_LINE, true)
		tube.fill = palette.paper
		lines.append(tube)
		var filter := PackedVector2Array([Vector2(left, tip + _FILTER), Vector2(left + cigarette_width, tip + _FILTER)])
		lines.append(InkLine.along(InkBrush.resample_polyline(filter, spacing), ink, _FILTER_LINE))
	var pack := Rect2(-half, top, pack_size.x, pack_size.y)
	lines.append(_washed(InkBrush.rounded_rect(pack, _CORNER, spacing), color, wash))
	for edge: float in [_BAND.x, _BAND.y]:
		var band := PackedVector2Array([Vector2(-half, -pack_size.y * edge), Vector2(half, -pack_size.y * edge)])
		lines.append(InkLine.along(InkBrush.resample_polyline(band, spacing), color, 0.8))
	return lines


## A closed line along [param path] with [param wash] inside.
static func _washed(path: PackedVector2Array, color: Color, wash: Color) -> InkLine:
	var line := InkLine.along(path, color, 1.0, true)
	line.fill = wash
	return line
