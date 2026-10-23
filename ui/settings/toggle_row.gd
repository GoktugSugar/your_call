class_name ToggleRow
extends HBoxContainer
## One switch on the settings page: its name, then its two words, the one that holds in ink and the
## other faded. The current row's name is amber. Enter or a click flips it, the left and right keys pick
## a side, and clicking one of its words picks that one. Pointing at the row makes it the current one.

## Emitted when the player flips the switch.
signal changed(on: bool)

## The row's name.
@export var label: Label
## The line under the name while the row is current.
@export var underline: InkUnderline
## The word for on.
@export var on_word: Label
## The word for off.
@export var off_word: Label
## Seconds a colour change takes.
@export_range(0.0, 1.0, 0.01) var recolor_duration := 0.12
## Seconds the underline takes to draw on.
@export_range(0.0, 1.0, 0.01) var underline_duration := 0.14

@export_group("Look")
## Palette role of the name at rest.
@export var resting_role := &"muted"
## Palette role of the name while the row is current.
@export var current_role := &"amber"
## Palette role of the word that holds.
@export var chosen_role := &"ink"
## Palette role of the word that does not.
@export var unchosen_role := &"faded"

## Whether the switch is on.
var on := false:
	set(value):
		on = value
		if on_word != null:
			_show_words()

var _tween: Tween


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(func() -> void:
		if not has_focus():
			grab_focus())
	focus_entered.connect(_show_look)
	focus_exited.connect(_show_look)
	underline.reveal = 0.0
	label.resized.connect(_fit_underline)
	_fit_underline()
	label.add_theme_color_override(&"font_color", InkPalette.get_default().color(resting_role))
	_show_words()


func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_left"):
		accept_event()
		_set_on(true)
	elif event.is_action_pressed(&"ui_right"):
		accept_event()
		_set_on(false)
	elif event.is_action_pressed(&"ui_accept"):
		accept_event()
		_set_on(not on)
	elif event.is_action_pressed(&"pick"):
		accept_event()
		var x := get_local_mouse_position().x
		if _holds(on_word, x):
			_set_on(true)
		elif _holds(off_word, x):
			_set_on(false)
		else:
			_set_on(not on)


func _set_on(value: bool) -> void:
	if value == on:
		return
	on = value
	changed.emit(on)


## Whether [param x], across the row, falls on [param word].
func _holds(word: Control, x: float) -> bool:
	return x >= word.position.x and x <= word.position.x + word.size.x


func _show_words() -> void:
	var palette := InkPalette.get_default()
	on_word.add_theme_color_override(&"font_color", palette.color(chosen_role if on else unchosen_role))
	off_word.add_theme_color_override(&"font_color", palette.color(unchosen_role if on else chosen_role))


func _show_look() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	var current := has_focus()
	_tween = create_tween().set_parallel(true)
	_tween.tween_method(func(color: Color) -> void: label.add_theme_color_override(&"font_color", color),
			label.get_theme_color(&"font_color"), InkPalette.get_default().color(current_role if current else resting_role),
			recolor_duration)
	_tween.tween_property(underline, ^"reveal", 1.0 if current else 0.0, underline_duration)


## Lays the underline under the name's words only, wherever they sit in the name's space.
func _fit_underline() -> void:
	var font := label.get_theme_font(&"font")
	var width := font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0,
			label.get_theme_font_size(&"font_size")).x
	var start := label.size.x - width if label.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT else 0.0
	underline.offset_left = start
	underline.offset_right = start + width - label.size.x
