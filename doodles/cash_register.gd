@tool
class_name CashRegister
extends InkDrawing
## A doodle: an old shop till, seen from the front and a little from above. A boxy brass body on two
## feet: a sloping deck of round keys on top, a little display box on a stalk over it, a plain panel on
## its front, and a cash drawer across its foot with a handle. Opened, the drawer slides out toward us,
## lower and a little wider, showing its shadowed tray, split into compartments, with a couple of
## banknotes standing up in it. Its line is gold, with a gold wash in the till, a stronger one in the
## handle and the stalk and a pale one on the keys and the display's window; the banknotes are green with
## a green wash. Its origin is the ground under its middle, and opening the drawer never moves the till.

## Whether the drawer is slid out, showing the money in it.
@export var drawer_open := false:
	set(value):
		drawer_open = value
		queue_redraw()
## How big the till is drawn, as a multiple of its natural size.
@export_range(0.2, 3.0, 0.01) var register_scale := 1.0:
	set(value):
		register_scale = value
		queue_redraw()
## How far the open drawer comes out toward us, at natural size: how far its front drops down the page.
@export_range(0.0, 30.0, 0.5) var drawer_travel := 14.0:
	set(value):
		drawer_travel = value
		queue_redraw()
## Palette role of the till's line.
@export var role := &"gold":
	set(value):
		role = value
		queue_redraw()
## Palette role of the banknotes.
@export var note_role := &"green":
	set(value):
		note_role = value
		queue_redraw()
## How strongly the till's wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()
## How strongly the handle and the stalk take the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var metal_wash := 0.65:
	set(value):
		metal_wash = value
		queue_redraw()
## How strongly the keys and the display's window take the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var pale_wash := 0.12:
	set(value):
		pale_wash = value
		queue_redraw()
## How dark the inside of the open drawer is: how far its wash goes from the till's wash toward the ink.
@export_range(0.0, 1.0, 0.01) var inside_shadow := 0.3:
	set(value):
		inside_shadow = value
		queue_redraw()
## How strongly the banknotes' wash takes their line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var note_wash := 0.45:
	set(value):
		note_wash = value
		queue_redraw()

## The feet at natural size, one either side, and the radius of their rounded corners.
const _FOOT := Rect2(-80.0, -10.0, 20.0, 10.0)
const _FOOT_CORNER := 3.0
## The drawer's front, shut, and the radius of its rounded corners; how much wider the open drawer's front
## is each side, coming toward us; and the size of the handle in the middle of it.
const _DRAWER := Rect2(-90.0, -44.0, 180.0, 34.0)
const _DRAWER_CORNER := 4.0
const _DRAWER_FLARE := 5.0
const _HANDLE := Vector2(36.0, 8.0)
## The front of the body over the drawer, the panel set into it, and the radius of their rounded corners.
const _FRONT := Rect2(-84.0, -86.0, 168.0, 44.0)
const _PANEL := Rect2(-70.0, -78.0, 140.0, 26.0)
const _FRONT_CORNER := 4.0
## The sloping deck on top of the body: its back edge's half width and height, and its front edge's.
const _DECK_BACK := Vector2(64.0, -122.0)
const _DECK_FRONT := Vector2(84.0, -86.0)
## The rows of keys on the deck: each row's height and the middles of its keys across it.
const _KEY_ROWS := [[-111.0, [-39.0, -13.0, 13.0, 39.0]], [-97.0, [-52.0, -26.0, 0.0, 26.0, 52.0]]]
## The half width and height of a key seen from above.
const _KEY_RADII := Vector2(8.0, 5.0)
## The stalk from the deck up to the display, its ends tucked behind both, and the radius of its corners;
## and the display box on it, its window, and the radius of their rounded corners.
const _STALK := Rect2(-5.0, -152.0, 10.0, 36.0)
const _STALK_CORNER := 2.5
const _DISPLAY := Rect2(-36.0, -180.0, 72.0, 32.0)
const _WINDOW := Rect2(-26.0, -173.0, 52.0, 17.0)
const _DISPLAY_CORNER := 5.0
## Where the dividers split the open drawer's tray, across its back edge.
const _DIVIDERS := [-60.0, 0.0, 60.0]
## The banknotes standing in the open drawer: each one's middle, from the middle of the drawer's back
## edge, and how far it leans, in degrees, clockwise.
const _NOTES := [Vector3(-30.0, 1.0, -8.0), Vector3(29.0, -1.0, 7.0)]
## The size of a banknote, and the oval on it, from its middle, with its radii.
const _NOTE_SIZE := Vector2(42.0, 28.0)
const _NOTE_OVAL := Vector2(0.0, -2.0)
const _NOTE_OVAL_RADII := Vector2(7.5, 5.5)
## Widths of the panel, the keys, the dividers and the notes' ovals, as multiples of the drawing's
## line width.
const _PANEL_LINE := 0.55
const _KEY_LINE := 0.7
const _DIVIDER_LINE := 0.6
const _OVAL_LINE := 0.6


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	# Built at natural size, so its spacing there is the page's shrunk by the till's scale.
	var spacing := style.sample_spacing / register_scale
	var color := palette.color(role)
	var wash := palette.paper.lerp(color, wash_strength)
	var metal := palette.paper.lerp(color, metal_wash)
	var pale := palette.paper.lerp(color, pale_wash)
	var lines: Array[InkLine] = []
	# Back to front: the feet, the stalk and the display on it, the deck and its keys, the body's front and
	# its panel, then the drawer.
	for side: float in [-1.0, 1.0]:
		var foot := Rect2(_FOOT.position.x if side < 0.0 else -_FOOT.end.x, _FOOT.position.y, _FOOT.size.x, _FOOT.size.y)
		lines.append(_washed(InkBrush.rounded_rect(foot, _FOOT_CORNER, spacing), color, wash))
	lines.append(_washed(InkBrush.rounded_rect(_STALK, _STALK_CORNER, spacing), color, metal))
	lines.append(_washed(InkBrush.rounded_rect(_DISPLAY, _DISPLAY_CORNER, spacing), color, wash))
	lines.append(_washed(InkBrush.rounded_rect(_WINDOW, _DISPLAY_CORNER * 0.5, spacing), color, pale, _KEY_LINE))
	var deck := PackedVector2Array([Vector2(-_DECK_BACK.x, _DECK_BACK.y), Vector2(_DECK_BACK.x, _DECK_BACK.y),
			Vector2(_DECK_FRONT.x, _DECK_FRONT.y), Vector2(-_DECK_FRONT.x, _DECK_FRONT.y)])
	lines.append(_washed(InkBrush.resample_polyline(_closed(deck), spacing), color, wash))
	for row: Array in _KEY_ROWS:
		var height: float = row[0]
		for across: float in row[1]:
			var key := InkBrush.ellipse(Vector2(across, height), _KEY_RADII, spacing * 0.5, PI)
			lines.append(_washed(key, color, pale, _KEY_LINE))
	lines.append(_washed(InkBrush.rounded_rect(_FRONT, _FRONT_CORNER, spacing), color, wash))
	lines.append(InkLine.along(InkBrush.rounded_rect(_PANEL, _FRONT_CORNER, spacing), color, _PANEL_LINE, true))
	var front := _DRAWER
	if drawer_open:
		lines.append_array(_tray(palette, color, wash, spacing))
		front = Rect2(_DRAWER.position + Vector2(-_DRAWER_FLARE, drawer_travel),
				_DRAWER.size + Vector2(_DRAWER_FLARE * 2.0, 0.0))
	lines.append(_washed(InkBrush.rounded_rect(front, _DRAWER_CORNER, spacing), color, wash))
	var handle := Rect2(front.get_center() - _HANDLE * 0.5, _HANDLE)
	lines.append(_washed(InkBrush.rounded_rect(handle, _HANDLE.y * 0.5, spacing), color, metal))
	var place := Transform2D(0.0, Vector2.ONE * register_scale, 0.0, Vector2.ZERO)
	for line in lines:
		line.path = place * line.path
		line.dot_radius *= register_scale
	return lines


## The open drawer's tray as it shows between the till and the drawer's front: its shadowed inside, the
## dividers splitting it and the banknotes standing in it, which the drawer's front hides the foot of.
func _tray(palette: InkPalette, color: Color, wash: Color, spacing: float) -> Array[InkLine]:
	var lines: Array[InkLine] = []
	var back := _DRAWER.position.y
	var front := back + drawer_travel
	var reach := _DRAWER.size.x * 0.5
	var spread := (reach + _DRAWER_FLARE) / reach
	var inside := PackedVector2Array([Vector2(-reach, back), Vector2(reach, back), Vector2(reach * spread, front),
			Vector2(-reach * spread, front)])
	lines.append(_washed(InkBrush.resample_polyline(_closed(inside), spacing), color, wash.lerp(palette.ink, inside_shadow)))
	for across: float in _DIVIDERS:
		var divider := PackedVector2Array([Vector2(across, back), Vector2(across * spread, front)])
		lines.append(InkLine.along(InkBrush.resample_polyline(divider, spacing), color, _DIVIDER_LINE))
	var green := palette.color(note_role)
	var note_fill := palette.paper.lerp(green, note_wash)
	for note: Vector3 in _NOTES:
		var lay := Transform2D(deg_to_rad(note.z), Vector2(note.x, back + note.y))
		var corners := PackedVector2Array()
		for corner: Vector2 in [Vector2(-0.5, -0.5), Vector2(0.5, -0.5), Vector2(0.5, 0.5), Vector2(-0.5, 0.5)]:
			corners.append(corner * _NOTE_SIZE)
		lines.append(_washed(lay * InkBrush.resample_polyline(_closed(corners), spacing), green, note_fill))
		var oval := InkBrush.ellipse(_NOTE_OVAL, _NOTE_OVAL_RADII, spacing * 0.5)
		lines.append(InkLine.along(lay * oval, green, _OVAL_LINE, true))
	return lines


## [param corners] with the first repeated at the end, to draw them as a closed polyline.
static func _closed(corners: PackedVector2Array) -> PackedVector2Array:
	var out := corners.duplicate()
	out.append(corners[0])
	return out


## A closed line along [param path] with [param wash] inside it, [param width] times the drawing's
## line width.
static func _washed(path: PackedVector2Array, color: Color, wash: Color, width := 1.0) -> InkLine:
	var line := InkLine.along(path, color, width, true)
	line.fill = wash
	return line
