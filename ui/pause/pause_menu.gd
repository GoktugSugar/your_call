class_name PauseMenu
extends CanvasLayer
## The pause: Esc holds the run still under a veil of paper and offers Resume, Save, Settings and Quit to
## Menu, the current one in amber. The ink behind keeps boiling and the music plays on, as everywhere the
## game holds still. Save keeps the moment the beat under way began, again, and says so; with nothing to
## keep, once an ending has been reached, it is greyed out. Quit to Menu closes the eyes on the page, then
## asks to go. Esc, or Resume, lets the run carry on.

## Emitted once the eyes have closed on the page after Quit to Menu.
signal quit_requested

## The paper laid over the page while the run holds still.
@export var veil: ColorRect
## The column of entries.
@export var column: MenuList
## Lets the run carry on.
@export var resume_word: MenuWord
## Keeps the moment the beat under way began.
@export var save_word: MenuWord
## Opens the settings.
@export var settings_word: MenuWord
## Leaves the run for the main menu.
@export var quit_word: MenuWord
## The settings, opened from the column.
@export var settings: SettingsPage
## The eyes that close on the page before the run is left.
@export var eyelids: Eyelids
## What Save keeps.
@export var auto_save: AutoSave

@export_group("Words")
## What Save says for a moment once it has kept the run.
@export var saved_text := "Saved"
## Seconds Save says so before it goes back to its own word.
@export_range(0.0, 10.0, 0.05) var saved_hold := 1.4

@export_group("Look")
## Palette role of the veil.
@export var veil_role := &"paper"
## How much of the page the veil hides.
@export_range(0.0, 1.0, 0.01) var veil_alpha := 0.84
## Seconds the veil takes to come down and lift.
@export_range(0.0, 2.0, 0.01) var fade_duration := 0.18

## Whether Esc may pause the run now. Main turns it on while a run plays.
var active := false

var _open := false
var _leaving := false
var _save_text := ""
var _fade: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	veil.color = Color(InkPalette.get_default().color(veil_role), 0.0)
	veil.hide()
	column.hide()
	_save_text = save_word.text
	resume_word.pressed.connect(resume)
	save_word.pressed.connect(_on_save)
	settings_word.pressed.connect(_open_settings)
	quit_word.pressed.connect(_on_quit)
	settings.closed.connect(_close_settings)


func _unhandled_input(event: InputEvent) -> void:
	if _leaving or not (event.is_action_pressed(&"pause") or event.is_action_pressed(&"ui_cancel")):
		return
	if _open:
		get_viewport().set_input_as_handled()
		resume()
	elif active and not get_tree().paused:
		get_viewport().set_input_as_handled()
		open()


## Holds the run still and offers the entries, Resume current.
func open() -> void:
	_open = true
	get_tree().paused = true
	save_word.text = _save_text
	save_word.set_greyed(auto_save == null or not auto_save.can_save())
	_show_veil(true)
	column.show()
	column.link()
	column.focus(resume_word)


## Lifts the veil and lets the run carry on.
func resume() -> void:
	if not _open or _leaving:
		return
	_open = false
	settings.close()
	column.hide()
	_show_veil(false)
	get_tree().paused = false


## Whether the run is paused here.
func is_open() -> bool:
	return _open


func _on_save() -> void:
	if auto_save == null or not auto_save.save_now():
		return
	save_word.text = saved_text
	await get_tree().create_timer(saved_hold, true).timeout
	if is_instance_valid(save_word):
		save_word.text = _save_text


func _open_settings() -> void:
	column.hide()
	settings.open()


func _close_settings() -> void:
	if not _open:
		return
	column.show()
	column.focus(settings_word)


## The eyes close on the page, still held, and then the run may be left.
func _on_quit() -> void:
	_leaving = true
	column.hide()
	await eyelids.close()
	quit_requested.emit()


func _show_veil(shown: bool) -> void:
	if _fade != null and _fade.is_valid():
		_fade.kill()
	veil.show()
	_fade = create_tween()
	_fade.tween_property(veil, ^"color:a", veil_alpha if shown else 0.0, fade_duration)
	if not shown:
		_fade.tween_callback(veil.hide)
