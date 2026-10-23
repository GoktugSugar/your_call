@tool
class_name GameCard
extends InkDrawing
## A doodle: a card held upright, as a contestant holds up a pick. A card with rounded corners, filled
## with the box's paper so it hides what is behind it. Face down, its back shows a diamond inside a border
## inset from its edge; face up, its word is written in the middle. Flipping it squashes it to its edge
## and out again, so a stage can turn it over: flip it to 0.5, swap its face, and flip it on to 1. Its
## line is ink, its back's pattern muted. Its origin is the middle of its bottom edge.

## Whether the card shows its face, with its word, or its back.
@export var face_up := false:
	set(value):
		face_up = value
		_refresh()
## The word on the card's face.
@export var word := "split":
	set(value):
		word = value
		_write_word()
## How far through a flip the card is: at 0 and at 1 it faces the player, at 0.5 it is edge on.
@export_range(0.0, 1.0, 0.001) var flip := 0.0:
	set(value):
		flip = value
		queue_redraw()
		_squash_word()
## How big the card is drawn, as a multiple of its natural size.
@export_range(0.2, 3.0, 0.01) var card_scale := 1.0:
	set(value):
		card_scale = value
		_refresh()
## Size of the word's letters, at natural size. A word too long for the card is written smaller, to fit.
@export_range(8, 160) var word_size := 40:
	set(value):
		word_size = value
		_write_word()

@export_group("Colour")
## Palette role of the card's line.
@export var role := &"ink":
	set(value):
		role = value
		queue_redraw()
## Palette role of the word.
@export var word_role := &"ink":
	set(value):
		word_role = value
		_write_word()
## Palette role of the pattern on the back.
@export var back_role := &"secondary":
	set(value):
		back_role = value
		queue_redraw()
## How strongly the back's diamond takes its colour over the paper.
@export_range(0.0, 1.0, 0.01) var back_wash := 0.45:
	set(value):
		back_wash = value
		queue_redraw()

## The card at natural size, standing on the middle of its bottom edge, and the radius of its corners.
const _CARD := Rect2(-45.0, -130.0, 90.0, 130.0)
const _CARD_CORNER := 9.0
## The border on the back, at natural size: how far in from the card's edge it runs, and the radius of
## its corners.
const _BORDER_INSET := 8.0
const _BORDER_CORNER := 5.0
## The diamond on the back, at natural size: its half width and half height, round the card's middle.
const _DIAMOND := Vector2(22.0, 40.0)
## Width of the back's lines, as a multiple of the drawing's line width.
const _BACK_LINE := 0.6
## How far in from the card's sides its word keeps, at natural size.
const _WORD_MARGIN := 11.0
## The narrowest the card gets edge on, as a share of its width, so its outline never folds flat.
const _EDGE_ON := 0.03

var _word_label: Label


func _ready() -> void:
	super._ready()
	_word_label = Label.new()
	_word_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_word_label, false, Node.INTERNAL_MODE_FRONT)
	_write_word()


## The middle of the card, where its word is, in this node's space.
func card_middle() -> Vector2:
	return _scaled_rect(_CARD).get_center()


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var squash := Transform2D(Vector2(_squash(), 0.0), Vector2(0.0, 1.0), Vector2.ZERO)
	var card := _scaled_rect(_CARD)
	var lines: Array[InkLine] = []
	var outline := InkLine.along(squash * InkBrush.rounded_rect(card, _CARD_CORNER * card_scale, spacing),
			palette.color(role), 1.0, true)
	outline.fill = palette.box_paper
	lines.append(outline)
	if face_up:
		return lines
	# The back: a border inset from the edge, and a diamond in the middle.
	var back := palette.color(back_role)
	var border := InkBrush.rounded_rect(card.grow(-_BORDER_INSET * card_scale), _BORDER_CORNER * card_scale, spacing)
	lines.append(InkLine.along(squash * border, back, _BACK_LINE, true))
	var middle := card.get_center()
	var half := _DIAMOND * card_scale
	var corners := PackedVector2Array([middle + Vector2(0.0, -half.y), middle + Vector2(half.x, 0.0),
			middle + Vector2(0.0, half.y), middle + Vector2(-half.x, 0.0), middle + Vector2(0.0, -half.y)])
	var diamond := InkLine.along(squash * InkBrush.resample_polyline(corners, spacing), back, _BACK_LINE, true)
	diamond.fill = palette.paper.lerp(back, back_wash)
	lines.append(diamond)
	return lines


## How wide the card is drawn now, as a share of its width: it narrows to its edge halfway through a flip.
func _squash() -> float:
	return maxf(absf(cos(flip * PI)), _EDGE_ON)


func _scaled_rect(rect: Rect2) -> Rect2:
	return Rect2(rect.position * card_scale, rect.size * card_scale)


func _refresh() -> void:
	queue_redraw()
	_write_word()


## Writes the word in the middle of the card, smaller when it would not fit, shown only while the card
## is face up.
func _write_word() -> void:
	if _word_label == null:
		return
	_word_label.text = word
	_word_label.visible = face_up
	_word_label.add_theme_color_override(&"font_color", InkPalette.get_default().color(word_role))
	var letters := roundi(word_size * card_scale)
	_word_label.add_theme_font_size_override(&"font_size", letters)
	_word_label.reset_size()
	var room := (_CARD.size.x - _WORD_MARGIN * 2.0) * card_scale
	if _word_label.size.x > room:
		_word_label.add_theme_font_size_override(&"font_size", floori(letters * room / _word_label.size.x))
		_word_label.reset_size()
	_word_label.pivot_offset = _word_label.size * 0.5
	_word_label.position = card_middle() - _word_label.size * 0.5
	_squash_word()
	_fade_word()


## Narrows the word with the card as it flips.
func _squash_word() -> void:
	if _word_label != null:
		_word_label.scale = Vector2(_squash(), 1.0)


## The word goes with the card as it is drawn on or dissolves away.
func _draw() -> void:
	super._draw()
	_fade_word()


func _apply_dissolve() -> void:
	super._apply_dissolve()
	_fade_word()


func _fade_word() -> void:
	if _word_label != null:
		_word_label.modulate.a = minf(reveal, 1.0 - dissolve)
