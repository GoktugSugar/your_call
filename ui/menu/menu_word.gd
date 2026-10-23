class_name MenuWord
extends Button
## One entry of a menu: a hand-lettered word, muted at rest, like a word of the choice row. The current
## entry, reached with the keys or pointed at, turns amber and a line draws itself underneath; pointing
## at an entry makes it the current one, so the keys and the pointer never disagree. A greyed out entry
## is faded, and neither the keys nor the pointer can reach it. A pencil ticks as the player makes an
## entry current, and a pen taps as one is pressed.

## The line drawn under the word while it is the current entry.
@export var underline: InkUnderline
## Seconds the underline takes to draw on.
@export_range(0.0, 1.0, 0.01) var underline_duration := 0.14
## Seconds a colour change takes.
@export_range(0.0, 1.0, 0.01) var recolor_duration := 0.12

@export_group("Look")
## Palette role of the word at rest.
@export var resting_role := &"muted"
## Palette role of the current entry.
@export var current_role := &"amber"
## Palette role of a greyed out entry.
@export var greyed_role := &"faded"

@export_group("Sound")
## Played as the player makes the entry current, with the keys or the pointer.
@export var point_sound: SoundCue = preload("res://game/audio/cues/menu_point.tres")
## Played as the entry is pressed.
@export var press_sound: SoundCue = preload("res://game/audio/cues/menu_press.tres")

## The font colours a button picks between by its state. All of them follow the word's look.
const _FONT_COLORS: Array[StringName] = [&"font_color", &"font_hover_color", &"font_focus_color",
		&"font_pressed_color", &"font_hover_pressed_color", &"font_disabled_color"]
## The boxes a button draws behind itself by its state. None is drawn: the word stands on the page.
const _BOXES: Array[StringName] = [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled", &"focus"]

var _tween: Tween


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	var nothing := StyleBoxEmpty.new()
	for box in _BOXES:
		add_theme_stylebox_override(box, nothing)
	mouse_entered.connect(_on_pointed)
	focus_entered.connect(_on_focused)
	focus_exited.connect(_show_look)
	pressed.connect(func() -> void: Sfx.play(press_sound))
	underline.reveal = 0.0
	_set_color(_look_color())
	_set_greyed_cursor()


## Greys the entry out, or brings it back. A greyed out entry cannot be reached or pressed.
func set_greyed(greyed: bool) -> void:
	disabled = greyed
	focus_mode = Control.FOCUS_NONE if greyed else Control.FOCUS_ALL
	if greyed and has_focus():
		release_focus()
	_set_greyed_cursor()
	_show_look()


## Whether it is the current entry.
func is_current() -> bool:
	return has_focus() and not disabled


func _on_pointed() -> void:
	if not disabled and not has_focus():
		grab_focus()


func _on_focused() -> void:
	_show_look()
	if not MenuList.focusing:
		Sfx.play(point_sound)


func _show_look() -> void:
	if not is_inside_tree():
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_method(_set_color, get_theme_color(&"font_color"), _look_color(), recolor_duration)
	_tween.tween_property(underline, ^"reveal", 1.0 if is_current() else 0.0, underline_duration)


func _set_color(color: Color) -> void:
	for state in _FONT_COLORS:
		add_theme_color_override(state, color)


func _look_color() -> Color:
	var palette := InkPalette.get_default()
	if disabled:
		return palette.color(greyed_role)
	return palette.color(current_role if is_current() else resting_role)


func _set_greyed_cursor() -> void:
	mouse_default_cursor_shape = Control.CURSOR_ARROW if disabled else Control.CURSOR_POINTING_HAND
