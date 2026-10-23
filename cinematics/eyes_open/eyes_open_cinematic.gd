class_name EyesOpenCinematic
extends CanvasLayer
## A continued run opens on this: the eyes, shut since the menu, open on the empty page the way they do
## after the crash ([Eyelids]), and the beat the run was saved at begins. An advance press skips to the end.

## Emitted when the eyes are open, or the opening was skipped.
signal finished

## The shut eyes that open on the page.
@export var eyelids: Eyelids

@export_group("Dark")
## Seconds the eyes stay shut before they open.
@export_range(0.0, 10.0, 0.05) var dark_hold := 0.4

@export_group("Skipping")
## Seconds after it starts before a press can skip it, so the click that picked Continue does not throw
## the opening away.
@export_range(0.0, 5.0, 0.05) var skip_grace := 0.6

var _running := false
var _clock := 0.0


func _ready() -> void:
	visible = false
	set_process(false)


func _process(delta: float) -> void:
	_clock += delta


func _unhandled_input(event: InputEvent) -> void:
	if _running and _clock >= skip_grace and event.is_action_pressed(&"advance"):
		get_viewport().set_input_as_handled()
		_finish()


## Plays the opening. Returns when the eyes are open or it is skipped.
func play() -> void:
	_clock = 0.0
	visible = true
	_running = true
	set_process(true)
	eyelids.shut()
	_open()
	await finished


func _open() -> void:
	await get_tree().create_timer(dark_hold, false).timeout
	if not _running:
		return
	await eyelids.open(_clock)
	_finish()


func _finish() -> void:
	if not _running:
		return
	_running = false
	eyelids.stop()
	eyelids.hide()
	set_process(false)
	visible = false
	finished.emit()
