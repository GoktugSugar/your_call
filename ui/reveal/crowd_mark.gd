@tool
class_name CrowdMark
extends Control
## The line a coordination gamble's crowd had to cross, drawn on the crowd reveal: a hand-drawn ink
## line down across the bars at the share the crowd had to pass, with its name over the top, such as
## "half". Its origin is where the line meets the top of the first bar.

## The label that names the line.
@export var word: Label
## How far the line reaches past the top and bottom bars.
@export_range(0.0, 60.0, 0.5) var overhang := 10.0
## Gap between the top of the line and its name.
@export_range(0.0, 60.0, 0.5) var word_gap := 4.0
## Width of the line, as a multiple of the style's line width.
@export_range(0.1, 3.0, 0.05) var line_width := 0.8
## Palette role of the line and its name.
@export var role := &"ink"
## Size of the name's letters.
@export_range(8, 120) var word_size := 30

## How far down the line runs from its origin, to the bottom of the last bar.
var length := 0.0:
	set(value):
		length = value
		queue_redraw()

var _seed := 0


func _ready() -> void:
	_seed = InkPainter.seed_for(self)
	InkPainter.attach(self)


## Puts the line at [param at] on the canvas, running [param down] pixels, named [param name].
func place(at: Vector2, down: float, name_text: String) -> void:
	global_position = at
	length = down
	word.text = name_text
	word.visible = not name_text.is_empty()
	word.add_theme_font_size_override(&"font_size", word_size)
	word.add_theme_color_override(&"font_color", InkPalette.get_default().color(role))
	word.reset_size()
	word.position = Vector2(-word.size.x * 0.5, -overhang - word_gap - word.size.y)


func _draw() -> void:
	if length <= 0.0:
		return
	var style := InkStyle.get_default()
	var path := InkBrush.resample_polyline(PackedVector2Array([Vector2(0.0, -overhang), Vector2(0.0, length + overhang)]),
			style.sample_spacing)
	var lines: Array[InkLine] = [InkLine.along(path, InkPalette.get_default().color(role), 1.0)]
	InkPainter.paint(self, lines, style.width * line_width, _seed, InkPainter.current_variant(), style)
