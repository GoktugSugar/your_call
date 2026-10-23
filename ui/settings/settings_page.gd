class_name SettingsPage
extends MenuList
## The settings: how loud the music, the sound effects and the voices are, whether the game fills the
## screen, and auto skip, then Back. Every change applies at once and is kept for the next session
## ([PlayerSettings]). Turning the sound effects up or down knocks the gavel, so the player hears the new
## level. Back or Esc leaves the page.

## Emitted when the player leaves the page.
signal closed
## Emitted when the player changes a volume, so a page that has someone to speak can let it be heard.
signal volume_changed(bus: StringName, level: int)

## The volume rows, one per bus.
@export var volumes: Array[VolumeRow] = []
## The switch for filling the screen.
@export var fullscreen: ToggleRow
## The switch for auto skip.
@export var auto_skip: ToggleRow
## Leaves the page.
@export var back: MenuWord
## Plays a sound effect at the new level when the sound effects' volume changes.
@export var sample_player: AudioStreamPlayer


func _ready() -> void:
	hide()
	for row in volumes:
		row.changed.connect(_on_volume_changed.bind(row.bus))
	fullscreen.changed.connect(PlayerSettings.set_fullscreen)
	auto_skip.changed.connect(PlayerSettings.set_auto_advance)
	back.pressed.connect(close)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


## Shows the settings as they are, the first row current.
func open() -> void:
	for row in volumes:
		row.level = PlayerSettings.volumes.get(row.bus, PlayerSettings.FULL_VOLUME)
	fullscreen.on = PlayerSettings.fullscreen
	auto_skip.on = PlayerSettings.auto_advance
	show()
	link()
	focus()


## Leaves the page.
func close() -> void:
	if not visible:
		return
	hide()
	closed.emit()


func _on_volume_changed(level: int, bus: StringName) -> void:
	PlayerSettings.set_volume(bus, level)
	if bus == &"SFX" and sample_player != null and sample_player.stream != null:
		sample_player.play()
	volume_changed.emit(bus, level)
