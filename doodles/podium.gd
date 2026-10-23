@tool
class_name Podium
extends InkDrawing
## A doodle: a contestant's podium, seen from the front. A stand that narrows a little toward the ground,
## with a thin ledge along its top and a panel on its front, a band of muted colour across the top of
## the panel where a name could go. It is filled with the box's paper, so it hides whoever stands behind
## it. Its line is ink. Its origin is the ground under its middle.

## How big the podium is drawn, as a multiple of its natural size.
@export_range(0.2, 3.0, 0.01) var podium_scale := 1.0:
	set(value):
		podium_scale = value
		queue_redraw()
## Palette role of every line.
@export var role := &"ink":
	set(value):
		role = value
		queue_redraw()
## Palette role of the band across the panel.
@export var panel_role := &"secondary":
	set(value):
		panel_role = value
		queue_redraw()
## How strongly the band's wash takes its colour over the box's paper.
@export_range(0.0, 1.0, 0.01) var band_wash := 0.45:
	set(value):
		band_wash = value
		queue_redraw()

## The podium at natural size: the stand, from its top left corner, which the ledge hides, round to its
## bottom left; the ledge along its top, with the radius of its rounded corners; and the panel on the
## stand's front, narrowing as the stand does, from its top left corner round to its bottom left.
const _STAND := [Vector2(-76.0, -140.0), Vector2(76.0, -140.0), Vector2(60.0, 0.0), Vector2(-60.0, 0.0)]
const _LEDGE := Rect2(-86.0, -150.0, 172.0, 12.0)
const _LEDGE_CORNER := 4.0
const _PANEL := [Vector2(-60.0, -124.0), Vector2(60.0, -124.0), Vector2(48.0, -22.0), Vector2(-48.0, -22.0)]
## How far down the panel the band across its top reaches, as a share of the way from the panel's top
## to its bottom.
const _BAND_DEPTH := 0.34
## Width of the panel's line and the band's edge, as a multiple of the drawing's line width.
const _PANEL_LINE := 0.7


## The middle of the band across the panel, in this node's space, where a name written on the podium goes.
func band_middle() -> Vector2:
	return _on_panel(0.5, _BAND_DEPTH * 0.5) * podium_scale


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var lines: Array[InkLine] = []
	# Back to front: the stand; the band's wash and the line along its bottom edge, then the panel's
	# line round it, over the band's top and ends; then the ledge over the stand's top. Everything but
	# the band is filled with the box's paper.
	lines.append(_washed(InkBrush.resample_polyline(_closed(_scaled(_STAND)), spacing), color, palette.box_paper))
	var band := [_on_panel(0.0, 0.0), _on_panel(1.0, 0.0), _on_panel(1.0, _BAND_DEPTH), _on_panel(0.0, _BAND_DEPTH)]
	var band_color := palette.box_paper.lerp(palette.color(panel_role), band_wash)
	lines.append(_washed(InkBrush.resample_polyline(_closed(_scaled(band)), spacing), Color.TRANSPARENT, band_color))
	var edge := _scaled([_on_panel(0.0, _BAND_DEPTH), _on_panel(1.0, _BAND_DEPTH)])
	lines.append(InkLine.along(InkBrush.resample_polyline(edge, spacing), color, _PANEL_LINE))
	lines.append(InkLine.along(InkBrush.resample_polyline(_closed(_scaled(_PANEL)), spacing), color, _PANEL_LINE, true))
	lines.append(_washed(InkBrush.rounded_rect(_scaled_rect(_LEDGE), _LEDGE_CORNER * podium_scale, spacing), color,
			palette.box_paper))
	return lines


## A point on the panel at natural size: [param across] it from its left side (0) to its right (1), and
## [param down] from its top edge (0) to its bottom (1).
static func _on_panel(across: float, down: float) -> Vector2:
	var top_left: Vector2 = _PANEL[0]
	var top_right: Vector2 = _PANEL[1]
	var bottom_right: Vector2 = _PANEL[2]
	var bottom_left: Vector2 = _PANEL[3]
	return top_left.lerp(top_right, across).lerp(bottom_left.lerp(bottom_right, across), down)


func _scaled(points: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point: Vector2 in points:
		out.append(point * podium_scale)
	return out


func _scaled_rect(rect: Rect2) -> Rect2:
	return Rect2(rect.position * podium_scale, rect.size * podium_scale)


## A closed line along [param path] with [param wash] inside it. A transparent [param color] leaves the
## wash with no line of its own.
static func _washed(path: PackedVector2Array, color: Color, wash: Color) -> InkLine:
	var line := InkLine.along(path, color, 1.0, true)
	line.fill = wash
	return line


## [param corners] with the first repeated at the end, to draw them as a closed polyline.
static func _closed(corners: PackedVector2Array) -> PackedVector2Array:
	var out := corners.duplicate()
	out.append(corners[0])
	return out
