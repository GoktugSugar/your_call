@tool
class_name Forms
extends InkDrawing
## A doodle: official forms on a clipboard, standing upright as if held up. A board with a metal clip at
## its top holding a neat stack of papers, the two under the top one set a little off square so their edges
## show. The top form has a heading, a couple of lines to fill in, three boxes to tick with a line beside
## each, two of them ticked, and a signature scribbled over the line at its foot. A pen is clipped on down
## the board's right margin. Its line is ink, with a muted wash in the board, a grey one in the clip and
## pale paper in the forms; the form's printing is muted, the ticks and the signature ink. Its origin is
## the ground under its middle.

## How big the clipboard is drawn, as a multiple of its natural size.
@export_range(0.2, 3.0, 0.01) var forms_scale := 1.0:
	set(value):
		forms_scale = value
		queue_redraw()
## Palette role of every line.
@export var line_role := &"ink":
	set(value):
		line_role = value
		queue_redraw()
## Palette role of the board's wash.
@export var board_role := &"muted":
	set(value):
		board_role = value
		queue_redraw()
## Palette role of the clip's and the pen's wash.
@export var metal_role := &"secondary":
	set(value):
		metal_role = value
		queue_redraw()
## Palette role of the form's printing: its heading, its lines and its boxes.
@export var print_role := &"muted":
	set(value):
		print_role = value
		queue_redraw()
## How strongly the board's wash takes its colour over the paper.
@export_range(0.0, 1.0, 0.01) var board_wash := 0.45:
	set(value):
		board_wash = value
		queue_redraw()
## How strongly the clip's and the pen cap's wash takes its colour over the paper.
@export_range(0.0, 1.0, 0.01) var metal_wash := 0.55:
	set(value):
		metal_wash = value
		queue_redraw()
## How strongly the pen's body takes its colour over the paper.
@export_range(0.0, 1.0, 0.01) var pen_wash := 0.2:
	set(value):
		pen_wash = value
		queue_redraw()

## The board at natural size, and the radius of its rounded corners.
const _BOARD := Rect2(-72.0, -182.0, 144.0, 182.0)
const _BOARD_CORNER := 9.0
## The top form, and the radius of its corners.
const _SHEET := Rect2(-58.0, -164.0, 112.0, 150.0)
const _SHEET_CORNER := 2.0
## The forms under the top one, lowest first: how far each one is moved from the top form, and how far it
## is turned, in degrees, clockwise.
const _UNDER := [Vector3(-1.0, 4.0, 2.0), Vector3(2.0, 2.0, -1.5)]
## The clip's plate, over the top of the forms, and the lever rolled across its top, with the radius of
## their rounded corners.
const _PLATE := Rect2(-34.0, -188.0, 68.0, 32.0)
const _LEVER := Rect2(-22.0, -196.0, 44.0, 12.0)
const _CLIP_CORNER := 6.0
## The form's heading, and the lines to fill in under it, each from its left end to its right.
const _HEADING := [Vector2(-46.0, -140.0), Vector2(6.0, -140.0)]
const _FIELDS := [[Vector2(-46.0, -124.0), Vector2(42.0, -124.0)], [Vector2(-46.0, -110.0), Vector2(42.0, -110.0)]]
## The boxes to tick: where each one's top left corner is, how long the line beside it runs, and whether
## it is ticked; and the size of a box, and the gap between a box and its line.
const _BOXES := [Vector3(-46.0, -97.0, 62.0), Vector3(-46.0, -79.0, 46.0), Vector3(-46.0, -61.0, 54.0)]
const _TICKED := [true, false, true]
const _BOX := 11.0
const _BOX_GAP := 8.0
## A tick, from a box's top left corner: down into the box, to the bottom of its stroke, then up and out
## past the box's corner.
const _TICK := [Vector2(1.5, 5.0), Vector2(5.0, 10.0), Vector2(15.0, -5.0)]
## The line at the form's foot to sign on, and the signature scribbled over it, a looping run of points.
const _SIGN_LINE := [Vector2(-12.0, -28.0), Vector2(44.0, -28.0)]
const _SIGNATURE := [Vector2(-8.0, -31.0), Vector2(-3.0, -46.0), Vector2(1.0, -37.0), Vector2(-5.0, -31.0),
		Vector2(5.0, -34.0), Vector2(9.0, -41.0), Vector2(12.0, -31.0), Vector2(17.0, -37.0), Vector2(20.0, -31.0),
		Vector2(25.0, -38.0), Vector2(28.0, -30.0), Vector2(33.0, -36.0), Vector2(37.0, -31.0), Vector2(44.0, -37.0)]
## The pen down the board's right margin: how far across its middle is, where its cap's top is, where the
## cap ends, where its body ends and where its point is, and how thick it is.
const _PEN := Vector4(63.0, -176.0, -140.0, -72.0)
const _PEN_POINT := -60.0
const _PEN_WIDTH := 11.0
## The clip on the pen's cap, down its left side: how far in from the cap's edge, and how far down it runs.
const _PEN_CLIP := Vector2(2.5, 26.0)
## Widths of the printing, the boxes, the ticks, the signature and the pen's clip, as multiples of the
## drawing's line width.
const _PRINT_LINE := 0.5
const _HEADING_LINE := 0.9
const _BOX_LINE := 0.55
const _TICK_LINE := 0.8
const _SIGNATURE_LINE := 0.6
const _PEN_CLIP_LINE := 0.6


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	# Built at natural size, so its spacing there is the page's shrunk by the clipboard's scale.
	var spacing := style.sample_spacing / forms_scale
	var ink := palette.color(line_role)
	var print_color := palette.color(print_role)
	var metal := palette.paper.lerp(palette.color(metal_role), metal_wash)
	var sheet_fill := palette.box_paper
	var lines: Array[InkLine] = []
	# Back to front: the board, the forms under the top one, the top form and what is on it, the clip
	# holding them, then the pen.
	lines.append(_washed(InkBrush.rounded_rect(_BOARD, _BOARD_CORNER, spacing), ink,
			palette.paper.lerp(palette.color(board_role), board_wash)))
	var sheet := InkBrush.rounded_rect(_SHEET, _SHEET_CORNER, spacing)
	for under: Vector3 in _UNDER:
		var lay := Transform2D(deg_to_rad(under.z), _SHEET.get_center() + Vector2(under.x, under.y)) \
				* Transform2D(0.0, -_SHEET.get_center())
		lines.append(_washed(lay * sheet, ink, sheet_fill, _BOX_LINE))
	lines.append(_washed(sheet, ink, sheet_fill))
	lines.append(InkLine.along(InkBrush.resample_polyline(PackedVector2Array(_HEADING), spacing), print_color, _HEADING_LINE))
	for field: Array in _FIELDS:
		lines.append(InkLine.along(InkBrush.resample_polyline(PackedVector2Array(field), spacing), print_color, _PRINT_LINE))
	for i in _BOXES.size():
		var box: Vector3 = _BOXES[i]
		var corner := Vector2(box.x, box.y)
		lines.append(InkLine.along(InkBrush.resample_polyline(_rect(Rect2(corner, Vector2.ONE * _BOX)), spacing * 0.5),
				print_color, _BOX_LINE, true))
		var beside := corner + Vector2(_BOX + _BOX_GAP, _BOX * 0.5)
		var line := PackedVector2Array([beside, beside + Vector2(box.z, 0.0)])
		lines.append(InkLine.along(InkBrush.resample_polyline(line, spacing), print_color, _PRINT_LINE))
	lines.append(InkLine.along(InkBrush.resample_polyline(PackedVector2Array(_SIGN_LINE), spacing), print_color, _PRINT_LINE))
	for i in _BOXES.size():
		if _TICKED[i]:
			var box: Vector3 = _BOXES[i]
			var tick := PackedVector2Array()
			for point: Vector2 in _TICK:
				tick.append(Vector2(box.x, box.y) + point)
			lines.append(InkLine.along(InkBrush.resample_polyline(tick, spacing * 0.5), ink, _TICK_LINE))
	lines.append(InkLine.along(InkBrush.resample_smooth(PackedVector2Array(_SIGNATURE), false, spacing * 0.5), ink,
			_SIGNATURE_LINE))
	lines.append(_washed(InkBrush.rounded_rect(_PLATE, _CLIP_CORNER, spacing), ink, metal))
	lines.append(_washed(InkBrush.rounded_rect(_LEVER, _CLIP_CORNER, spacing), ink, metal))
	lines.append_array(_pen(ink, palette.paper.lerp(palette.color(metal_role), pen_wash), metal, spacing))
	var place := Transform2D(0.0, Vector2.ONE * forms_scale, 0.0, Vector2.ZERO)
	for line in lines:
		line.path = place * line.path
	return lines


## The pen clipped on down the board's right margin: its point, its body, then its cap with the clip on it.
func _pen(ink: Color, body: Color, cap: Color, spacing: float) -> Array[InkLine]:
	var lines: Array[InkLine] = []
	var half := _PEN_WIDTH * 0.5
	var across := _PEN.x
	var point := PackedVector2Array([Vector2(across - half * 0.7, _PEN.w), Vector2(across + half * 0.7, _PEN.w),
			Vector2(across, _PEN_POINT), Vector2(across - half * 0.7, _PEN.w)])
	lines.append(_washed(InkBrush.resample_polyline(point, spacing * 0.5), ink, ink.lerp(body, 0.5)))
	var stick := Rect2(across - half, _PEN.z - _CLIP_CORNER, _PEN_WIDTH, _PEN.w - _PEN.z + _CLIP_CORNER)
	lines.append(_washed(InkBrush.rounded_rect(stick, half * 0.4, spacing), ink, body))
	var top := Rect2(across - half, _PEN.y, _PEN_WIDTH, _PEN.z - _PEN.y)
	lines.append(_washed(InkBrush.rounded_rect(top, half * 0.8, spacing), ink, cap))
	var clip := PackedVector2Array([Vector2(across - half + _PEN_CLIP.x, _PEN.y + _PEN_CLIP.x),
			Vector2(across - half + _PEN_CLIP.x, _PEN.y + _PEN_CLIP.y)])
	lines.append(InkLine.along(InkBrush.resample_polyline(clip, spacing * 0.5), ink, _PEN_CLIP_LINE))
	return lines


## The corners of [param rect] as a closed polyline.
static func _rect(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end,
			Vector2(rect.position.x, rect.end.y), rect.position])


## A closed line along [param path] with [param wash] inside it, [param width] times the drawing's
## line width.
static func _washed(path: PackedVector2Array, color: Color, wash: Color, width := 1.0) -> InkLine:
	var line := InkLine.along(path, color, width, true)
	line.fill = wash
	return line
