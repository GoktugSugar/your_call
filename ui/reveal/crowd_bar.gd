@tool
class_name CrowdBar
extends Control
## One bar of the crowd reveal: a solid ink bar with a living edge, as long as its share of the crowd,
## with its bare number just past its end. It inks in from the left as [member fill] goes from 0 to 1.

## Emitted when the number past the bar's end changes, as it counts up while the bar inks in.
signal counted(number: int)

## The share of the crowd, from 0 to 100.
@export_range(0.0, 100.0, 0.1) var value := 50.0:
	set(new_value):
		value = new_value
		_refresh()
## How much of the bar has inked in: 0 is none, 1 is its full length.
@export_range(0.0, 1.0, 0.001) var fill := 1.0:
	set(new_value):
		fill = new_value
		_refresh()
## Length of a bar for the whole crowd.
@export_range(10.0, 1600.0, 1.0) var full_length := 720.0:
	set(new_value):
		full_length = new_value
		_refresh()
## Height of the bar.
@export_range(2.0, 80.0, 0.5) var bar_height := 24.0:
	set(new_value):
		bar_height = new_value
		_refresh()
## Gap between the end of the bar and its number.
@export_range(0.0, 80.0, 0.5) var number_gap := 14.0:
	set(new_value):
		number_gap = new_value
		_refresh()
## Palette role of the bar and its number.
@export var color_role := &"crowd":
	set(new_value):
		color_role = new_value
		_refresh()
## The label showing the number.
@export var number_label: Label

var _seed := 0
## The ink of this control's lines, kept to lay down again while they stay as they were.
var _cache := InkCache.new()
## The number shown past the bar's end.
var _shown := -1


func _ready() -> void:
	_seed = InkPainter.seed_for(self)
	InkPainter.attach(self)
	_refresh()


func _draw() -> void:
	var length := _length()
	if length <= 0.5:
		return
	var style := InkStyle.get_default()
	var color := InkPalette.get_default().color(color_role)
	var top := (size.y - bar_height) * 0.5
	var rect := Rect2(0.0, top, length, bar_height)
	var outline := InkBrush.rounded_rect(rect, minf(bar_height * 0.25, length * 0.5), style.sample_spacing)
	var edge := InkLine.along(outline, color, 0.8, true)
	edge.fill = color
	var lines: Array[InkLine] = [edge]
	InkPainter.paint(self, lines, style.width, _seed, InkPainter.current_variant(), style, 1.0, Color.TRANSPARENT,
			_cache)


func _get_minimum_size() -> Vector2:
	var number_height := number_label.get_combined_minimum_size().y if number_label != null else 0.0
	return Vector2(full_length, maxf(bar_height, number_height))


func _refresh() -> void:
	queue_redraw()
	if number_label == null:
		return
	var number := roundi(value * fill)
	number_label.text = str(number)
	number_label.add_theme_color_override(&"font_color", InkPalette.get_default().color(color_role))
	var label_size := number_label.get_combined_minimum_size()
	number_label.size = label_size
	number_label.position = Vector2(_length() + number_gap, (size.y - label_size.y) * 0.5)
	if number != _shown:
		_shown = number
		counted.emit(number)


func _length() -> float:
	return full_length * clampf(value / 100.0, 0.0, 1.0) * fill
