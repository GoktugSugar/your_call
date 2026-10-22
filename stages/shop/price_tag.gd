@tool
class_name PriceTag
extends InkDrawing
## A hand drawn price tag: a card with one end cut to a point and a hole punched near the point, the
## price written on it. It sizes itself to its words. Its origin is the tip of the point, and the card
## runs off to the right of it.

## The words on the card.
@export var words: Label
## Palette role of the card's line.
@export var role := &"amber":
	set(value):
		role = value
		queue_redraw()
## Palette role of the words.
@export var words_role := &"amber"
## Size of the words.
@export_range(8, 200) var font_size := 52
## Room between the words and the card's edge, across and down.
@export var padding := Vector2(24.0, 6.0):
	set(value):
		padding = value
		_fit()
## How far the point reaches out from the card.
@export_range(0.0, 200.0, 0.5) var point_length := 36.0:
	set(value):
		point_length = value
		_fit()
## Radius of the hole near the point.
@export_range(0.0, 40.0, 0.5) var hole_radius := 6.5:
	set(value):
		hole_radius = value
		queue_redraw()
## Where the hole sits between the tip and the card, as a share of the point's length.
@export_range(0.0, 1.0, 0.01) var hole_at := 0.62:
	set(value):
		hole_at = value
		queue_redraw()
## Width of the card's line, as a multiple of the style's line width.
@export_range(0.2, 4.0, 0.05) var card_width := 0.85:
	set(value):
		card_width = value
		queue_redraw()

## The card's size, without the point.
var card_size := Vector2(160.0, 70.0)


func _ready() -> void:
	super._ready()
	if words != null:
		words.add_theme_font_size_override(&"font_size", font_size)
		words.add_theme_color_override(&"font_color", InkPalette.get_default().color(words_role))
	_fit()


## Writes [param text] on the card and sizes the card to it.
func set_words(text: String) -> void:
	if words == null:
		return
	words.text = text
	_fit()


func _fit() -> void:
	if words != null:
		words.reset_size()
		card_size = words.size + padding * 2.0
		words.position = Vector2(point_length + padding.x, -words.size.y * 0.5)
	queue_redraw()


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var color := palette.color(role)
	var half := card_size.y * 0.5
	var right := point_length + card_size.x
	var outline := PackedVector2Array([Vector2.ZERO, Vector2(point_length, -half), Vector2(right, -half),
			Vector2(right, half), Vector2(point_length, half), Vector2.ZERO])
	var lines: Array[InkLine] = [InkLine.along(InkBrush.resample_polyline(outline, style.sample_spacing), color, card_width)]
	lines.append(InkLine.along(InkBrush.ellipse(Vector2(point_length * hole_at, 0.0), Vector2.ONE * hole_radius,
			style.sample_spacing), color, card_width, true))
	return lines
