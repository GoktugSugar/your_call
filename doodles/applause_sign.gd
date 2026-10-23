@tool
class_name ApplauseSign
extends InkDrawing
## A doodle: the studio's applause sign. A wide sign with rounded corners standing on two thin posts: a
## frame round its edge set with a row of small round bulbs, and a panel in its middle with the word on
## it. Lit, the frame's wash, the bulbs and the word turn amber and the panel glows faintly; unlit, they
## are quiet grey ink. Its line is ink. Its origin is the ground under its middle, between the posts.

## Whether the sign is lit: its frame's wash, its bulbs and its word take [member lit_role] while it
## is, and [member unlit_role] while it is not.
@export var lit := false:
	set(value):
		lit = value
		_refresh()
## The word on the sign.
@export var word := "APPLAUSE":
	set(value):
		word = value
		_write_word()
## Size of the word's letters, at natural size.
@export_range(8, 160) var word_size := 54:
	set(value):
		word_size = value
		_write_word()
## How big the sign is drawn, as a multiple of its natural size.
@export_range(0.2, 3.0, 0.01) var sign_scale := 1.0:
	set(value):
		sign_scale = value
		_refresh()
## How high the posts hold the sign's bottom edge off the ground, at natural size.
@export_range(0.0, 120.0, 0.5) var post_height := 56.0:
	set(value):
		post_height = value
		_refresh()

@export_group("Bulbs")
## Radius of each bulb, at natural size.
@export_range(1.0, 12.0, 0.1) var bulb_radius := 5.0:
	set(value):
		bulb_radius = value
		queue_redraw()
## Distance between neighbouring bulbs along the middle of the frame, at natural size. The bulbs share
## the frame out evenly, as near this far apart as they can.
@export_range(8.0, 80.0, 0.5) var bulb_spacing := 30.0:
	set(value):
		bulb_spacing = value
		queue_redraw()

@export_group("Colour")
## Palette role of the sign's lines.
@export var role := &"ink":
	set(value):
		role = value
		queue_redraw()
## Palette role of the frame's wash, the bulbs and the word while the sign is lit.
@export var lit_role := &"amber":
	set(value):
		lit_role = value
		_refresh()
## Palette role of the frame's wash, the bulbs and the word while the sign is unlit, and of the posts.
@export var unlit_role := &"secondary":
	set(value):
		unlit_role = value
		_refresh()
## How strongly the frame's and the posts' wash takes its colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()
## How strongly the panel takes the lit colour over the paper while the sign is lit, as if it glowed.
@export_range(0.0, 1.0, 0.01) var glow := 0.12:
	set(value):
		glow = value
		queue_redraw()

## The sign at natural size: its width and height, the radius of its rounded corners, how wide the frame
## round its panel is, and the radius of the panel's corners.
const _SIGN_SIZE := Vector2(320.0, 120.0)
const _CORNER := 24.0
const _FRAME := 26.0
const _PANEL_CORNER := 8.0
## The posts at natural size: how far each stands from the middle, how wide it is and the radius of its
## corners. Each reaches up behind the sign to its middle.
const _POST_SPREAD := 104.0
const _POST_WIDTH := 10.0
const _POST_CORNER := 2.0
## Width of the panel's line, as a multiple of the drawing's line width.
const _PANEL_LINE := 0.7
## How finely the frame is measured out to space the bulbs evenly along it, in pixels.
const _BULB_SAMPLING := 1.0
## The fewest bulbs the frame carries, however far apart they are asked to be.
const _FEWEST_BULBS := 4

var _word_label: Label


func _ready() -> void:
	super._ready()
	_word_label = Label.new()
	_word_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_word_label, false, Node.INTERNAL_MODE_FRONT)
	_write_word()


## The middle of the sign, where its word is, in this node's space.
func sign_middle() -> Vector2:
	return _board().get_center()


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var light := palette.color(lit_role if lit else unlit_role)
	var board := _board()
	var lines: Array[InkLine] = []
	# Back to front: the posts, whose tops the sign hides, then the sign, its panel and its bulbs.
	var post_wash := palette.paper.lerp(palette.color(unlit_role), wash_strength)
	for side: float in [-1.0, 1.0]:
		var post := Rect2((side * _POST_SPREAD - _POST_WIDTH * 0.5) * sign_scale, board.get_center().y,
				_POST_WIDTH * sign_scale, -board.get_center().y)
		lines.append(_washed(InkBrush.rounded_rect(post, _POST_CORNER * sign_scale, spacing), color, post_wash))
	var frame := InkBrush.rounded_rect(board, _CORNER * sign_scale, spacing)
	lines.append(_washed(frame, color, palette.paper.lerp(light, wash_strength)))
	var panel := InkBrush.rounded_rect(board.grow(-_FRAME * sign_scale), _PANEL_CORNER * sign_scale, spacing)
	lines.append(_washed(panel, color, palette.paper.lerp(light, glow) if lit else palette.paper, _PANEL_LINE))
	var track := board.grow(-_FRAME * sign_scale * 0.5)
	for bulb in _bulbs(track, (_CORNER - _FRAME * 0.5) * sign_scale):
		lines.append(InkLine.dot(bulb, bulb_radius * sign_scale, light))
	return lines


## The sign's board, in this node's space.
func _board() -> Rect2:
	var size := _SIGN_SIZE * sign_scale
	return Rect2(-size.x * 0.5, -post_height * sign_scale - size.y, size.x, size.y)


## Where the bulbs go: spread evenly round [param track], a rectangle with corners rounded by
## [param corner], from the middle of its top edge, so they sit the same either side of the middle.
func _bulbs(track: Rect2, corner: float) -> PackedVector2Array:
	var loop := InkBrush.rounded_rect(track, corner, _BULB_SAMPLING)
	var middle := track.get_center()
	var top := 0
	for i in loop.size():
		if loop[i].y < middle.y and absf(loop[i].x - middle.x) < absf(loop[top].x - middle.x):
			top = i
	loop = loop.slice(top) + loop.slice(0, top)
	loop.append(loop[0])
	var count := maxi(_FEWEST_BULBS, roundi(InkBrush.path_length(loop) / (bulb_spacing * sign_scale)))
	return _spaced(loop, count)


## [param count] points spread evenly along [param path], the first at its start.
static func _spaced(path: PackedVector2Array, count: int) -> PackedVector2Array:
	var step := InkBrush.path_length(path) / count
	var out := PackedVector2Array()
	var travelled := 0.0
	for i in range(1, path.size()):
		var length := path[i].distance_to(path[i - 1])
		while out.size() < count and out.size() * step <= travelled + length:
			out.append(path[i - 1].lerp(path[i], (out.size() * step - travelled) / maxf(length, 0.0001)))
		travelled += length
	return out


func _refresh() -> void:
	queue_redraw()
	_write_word()


## Writes the word on the panel, centred on the sign, in the colour the sign is lit in.
func _write_word() -> void:
	if _word_label == null:
		return
	_word_label.text = word
	_word_label.add_theme_font_size_override(&"font_size", roundi(word_size * sign_scale))
	_word_label.add_theme_color_override(&"font_color", InkPalette.get_default().color(lit_role if lit else unlit_role))
	_word_label.reset_size()
	_word_label.position = sign_middle() - _word_label.size * 0.5
	_fade_word()


## The word goes with the sign as it is drawn on or dissolves away.
func _draw() -> void:
	super._draw()
	_fade_word()


func _apply_dissolve() -> void:
	super._apply_dissolve()
	_fade_word()


func _fade_word() -> void:
	if _word_label != null:
		_word_label.modulate.a = minf(reveal, 1.0 - dissolve)


## A closed line along [param path] with [param wash] inside it, [param width] times the drawing's
## line width.
static func _washed(path: PackedVector2Array, color: Color, wash: Color, width := 1.0) -> InkLine:
	var line := InkLine.along(path, color, width, true)
	line.fill = wash
	return line
