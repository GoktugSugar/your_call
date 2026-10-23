class_name PlayerSettings
extends RefCounted
## The player's settings, read wherever they apply: how loud the music, the sound effects and the voices
## are, whether the game fills the screen, and whether dialogue moves on by itself. The settings page
## changes them; each change applies at once and is kept between sessions in [member path]. The first
## scene to start, the menu or the run, loads them once per launch ([method load_saved]).

## Where the settings are kept between sessions.
const DEFAULT_PATH := "user://settings.cfg"
## The loudest a volume goes. Volumes run from 0, silent, to this.
const FULL_VOLUME := 100
## The buses the player sets the volume of, each with its key in the settings file.
const VOLUME_BUSES: Dictionary[StringName, String] = {&"Music": "music", &"SFX": "sfx", &"Voice": "voice"}

const _AUDIO := "audio"
const _DISPLAY := "display"
const _PLAY := "play"

## Where the settings are kept. Tests point it elsewhere so they never touch the player's own.
static var path := DEFAULT_PATH
## Whether each page of dialogue moves on by itself once it has been said, instead of waiting for a
## click. The page a choice follows still stays up while the player chooses.
static var auto_advance := false
## Whether the game fills the screen. Off, it runs in a maximized window.
static var fullscreen := false
## How loud each of [constant VOLUME_BUSES] plays, from 0 to [constant FULL_VOLUME].
static var volumes: Dictionary[StringName, int] = {&"Music": FULL_VOLUME, &"SFX": FULL_VOLUME, &"Voice": FULL_VOLUME}

static var _loaded := false


## Loads the kept settings and applies them, once per launch; later calls do nothing. Missing or
## unreadable settings leave the defaults.
static func load_saved() -> void:
	if _loaded:
		return
	_loaded = true
	read()
	apply_all()


## Reads the kept settings from [member path] without applying them. A missing or unreadable file
## leaves the settings as they are.
static func read() -> void:
	var file := ConfigFile.new()
	if file.load(path) != OK:
		return
	for bus in VOLUME_BUSES:
		var level: Variant = file.get_value(_AUDIO, VOLUME_BUSES[bus], volumes[bus])
		if level is int or level is float:
			volumes[bus] = clampi(int(level), 0, FULL_VOLUME)
	var screen: Variant = file.get_value(_DISPLAY, "fullscreen", fullscreen)
	if screen is bool:
		fullscreen = screen
	var auto: Variant = file.get_value(_PLAY, "auto_skip", auto_advance)
	if auto is bool:
		auto_advance = auto


## Keeps the settings in [member path] for the next session.
static func write() -> void:
	var file := ConfigFile.new()
	for bus in VOLUME_BUSES:
		file.set_value(_AUDIO, VOLUME_BUSES[bus], volumes[bus])
	file.set_value(_DISPLAY, "fullscreen", fullscreen)
	file.set_value(_PLAY, "auto_skip", auto_advance)
	var error := file.save(path)
	if error != OK:
		push_error("PlayerSettings: could not keep the settings in %s (%s)" % [path, error_string(error)])


## Applies every setting: the volumes, and the screen when it should be filled. A window left as the
## project opens it is not touched, so a forced window size for checking stays as it is.
static func apply_all() -> void:
	for bus in VOLUME_BUSES:
		apply_volume(bus)
	if fullscreen:
		apply_screen()


## Sets [param bus] to [param level], applies it and keeps it.
static func set_volume(bus: StringName, level: int) -> void:
	volumes[bus] = clampi(level, 0, FULL_VOLUME)
	apply_volume(bus)
	write()


## Fills the screen or not, applies it and keeps it.
static func set_fullscreen(on: bool) -> void:
	fullscreen = on
	apply_screen()
	write()


## Turns auto skip on or off and keeps it.
static func set_auto_advance(on: bool) -> void:
	auto_advance = on
	write()


## Sets [param bus] to its volume. Nothing at all is silence: the bus is muted rather than set to an
## endless fall in decibels.
static func apply_volume(bus: StringName) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index < 0:
		return
	var level := float(volumes.get(bus, FULL_VOLUME)) / FULL_VOLUME
	AudioServer.set_bus_mute(index, level <= 0.0)
	if level > 0.0:
		AudioServer.set_bus_volume_db(index, linear_to_db(level))


## Fills the screen with the game's window, or gives it back as a maximized window.
static func apply_screen() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or DisplayServer.get_name() == "headless":
		return
	tree.root.mode = Window.MODE_FULLSCREEN if fullscreen else Window.MODE_MAXIMIZED
