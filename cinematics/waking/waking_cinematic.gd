class_name WakingCinematic
extends CanvasLayer
## The waking that opens every chapter after the first. The eyes close on whatever is on the page, the
## dark creeping in from the edges in blotches that blur as they lose focus; the dark holds; then the
## eyes open again exactly as they did after the crash ([Eyelids]). An advance press skips to the end.

## Emitted once the eyes are shut, before the dark holds, so the page behind them can change unseen.
## A skip before then emits it on the way out, just before [signal finished].
signal eyes_closed
## Emitted when the cinematic has finished or been skipped.
signal finished

## The shut eyes that close on the page and open on it again.
@export var eyelids: Eyelids

@export_group("Dark")
## Seconds the eyes stay shut before they open again.
@export_range(0.0, 10.0, 0.05) var dark_hold := 1.0

@export_group("Skipping")
## Seconds after it starts before a press can skip it, so a click meant for whatever came before does
## not throw the waking away.
@export_range(0.0, 5.0, 0.05) var skip_grace := 0.6

var _running := false
var _shut := false
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


## Plays the waking. Returns when it ends or is skipped.
func play() -> void:
	_clock = 0.0
	_shut = false
	visible = true
	_running = true
	set_process(true)
	_wake()
	await finished


## The eyes close, the dark holds, and the eyes open. Their blotches sway on this cinematic's clock.
func _wake() -> void:
	await eyelids.close(_clock)
	if not _running:
		return
	_announce_shut()
	await get_tree().create_timer(dark_hold, false).timeout
	if not _running:
		return
	await eyelids.open(_clock)
	_finish()


func _announce_shut() -> void:
	if not _shut:
		_shut = true
		eyes_closed.emit()


func _finish() -> void:
	if not _running:
		return
	_running = false
	eyelids.stop()
	_announce_shut()
	set_process(false)
	visible = false
	finished.emit()
