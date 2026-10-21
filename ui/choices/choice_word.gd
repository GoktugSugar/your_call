class_name ChoiceWord
extends Label
## One option in the choice row: a muted hand-lettered word. Pointed at, it turns amber and a line
## draws itself underneath. Once the player picks, the pick stays amber and the rest fade.

## Emitted when the pointer moves onto or off the word.
signal pointed(word: ChoiceWord, is_pointed: bool)
## Emitted when the word is clicked.
signal clicked(word: ChoiceWord)

enum Look { RESTING, LIFTED, PICKED, PASSED }

## The line drawn under the word when it lifts.
@export var underline: InkUnderline
## Seconds the underline takes to draw on.
@export_range(0.0, 1.0, 0.01) var underline_duration := 0.14
## Seconds a colour change takes.
@export_range(0.0, 1.0, 0.01) var recolor_duration := 0.12

## Which option this word stands for.
var index := 0
## How the word looks now.
var look := Look.RESTING:
	set(value):
		if value != look:
			look = value
			_show_look()

var _tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(func() -> void: pointed.emit(self, true))
	mouse_exited.connect(func() -> void: pointed.emit(self, false))
	underline.reveal = 0.0
	add_theme_color_override(&"font_color", _look_color(Look.RESTING))


func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pick"):
		accept_event()
		clicked.emit(self)


func _show_look() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_method(_set_color, get_theme_color(&"font_color"), _look_color(look), recolor_duration)
	var underlined := look == Look.LIFTED or look == Look.PICKED
	_tween.tween_property(underline, ^"reveal", 1.0 if underlined else 0.0, underline_duration)


func _set_color(color: Color) -> void:
	add_theme_color_override(&"font_color", color)


func _look_color(which: Look) -> Color:
	var palette := InkPalette.get_default()
	match which:
		Look.LIFTED, Look.PICKED:
			return palette.amber
		Look.PASSED:
			return palette.faded
		_:
			return palette.muted
