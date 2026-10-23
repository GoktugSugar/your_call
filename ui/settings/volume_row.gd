class_name VolumeRow
extends HBoxContainer
## One volume on the settings page: its name, then an ink bar as long as the volume with its bare number
## past the end, like a bar of the crowd reveal. The current row's name and bar are amber. The left and
## right keys turn it down and up a step at a time, and clicking or dragging along the bar sets it there.
## Pointing at the row makes it the current one.

## Emitted when the player changes the volume, from 0 to [constant PlayerSettings.FULL_VOLUME].
signal changed(level: int)

## The audio bus the row sets: [code]Music[/code], [code]SFX[/code] or [code]Voice[/code].
@export var bus := &"Music"
## The row's name.
@export var label: Label
## The line under the name while the row is current.
@export var underline: InkUnderline
## The bar as long as the volume.
@export var bar: CrowdBar
## How far one press of a key, or one notch of the bar, moves the volume.
@export_range(1, 50) var step := 10
## Seconds a colour change takes.
@export_range(0.0, 1.0, 0.01) var recolor_duration := 0.12
## Seconds the underline takes to draw on.
@export_range(0.0, 1.0, 0.01) var underline_duration := 0.14
## Played as the player makes the row current, with the keys or the pointer.
@export var point_sound: SoundCue = preload("res://game/audio/cues/menu_point.tres")

@export_group("Look")
## Palette role of the name at rest.
@export var resting_role := &"muted"
## Palette role of the bar at rest.
@export var bar_role := &"crowd"
## Palette role of the name and the bar while the row is current.
@export var current_role := &"amber"

## The volume shown, from 0 to [constant PlayerSettings.FULL_VOLUME].
var level := PlayerSettings.FULL_VOLUME:
	set(value):
		level = clampi(value, 0, PlayerSettings.FULL_VOLUME)
		if bar != null:
			bar.value = level * 100.0 / PlayerSettings.FULL_VOLUME

var _dragging := false
var _tween: Tween


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(func() -> void:
		if not has_focus():
			grab_focus())
	focus_entered.connect(func() -> void:
		_show_look()
		if not MenuList.focusing:
			Sfx.play(point_sound))
	focus_exited.connect(_show_look)
	underline.reveal = 0.0
	label.resized.connect(_fit_underline)
	_fit_underline()
	label.add_theme_color_override(&"font_color", InkPalette.get_default().color(resting_role))
	bar.color_role = bar_role
	level = level


func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_left", true):
		accept_event()
		_set_level(level - step)
	elif event.is_action_pressed(&"ui_right", true):
		accept_event()
		_set_level(level + step)
	elif event.is_action_pressed(&"pick"):
		accept_event()
		_dragging = true
		_set_from_pointer()
	elif event.is_action_released(&"pick"):
		_dragging = false
	elif event is InputEventMouseMotion and _dragging:
		accept_event()
		_set_from_pointer()


func _set_from_pointer() -> void:
	var along := clampf(bar.get_local_mouse_position().x / bar.full_length, 0.0, 1.0)
	_set_level(roundi(along * PlayerSettings.FULL_VOLUME / step) * step)


func _set_level(value: int) -> void:
	var before := level
	level = value
	if level != before:
		changed.emit(level)


func _show_look() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	var palette := InkPalette.get_default()
	var current := has_focus()
	_tween = create_tween().set_parallel(true)
	_tween.tween_method(func(color: Color) -> void: label.add_theme_color_override(&"font_color", color),
			label.get_theme_color(&"font_color"), palette.color(current_role if current else resting_role), recolor_duration)
	_tween.tween_property(underline, ^"reveal", 1.0 if current else 0.0, underline_duration)
	bar.color_role = current_role if current else bar_role
	if not current:
		_dragging = false


## Lays the underline under the name's words only, wherever they sit in the name's space.
func _fit_underline() -> void:
	var font := label.get_theme_font(&"font")
	var width := font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0,
			label.get_theme_font_size(&"font_size")).x
	var start := label.size.x - width if label.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT else 0.0
	underline.offset_left = start
	underline.offset_right = start + width - label.size.x
