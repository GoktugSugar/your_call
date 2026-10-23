extends GutTest
## The player's settings: they are kept in their file and read back, junk in the file leaves the
## defaults, and a volume reaches its bus, nothing at all muting it.

const SETTINGS_PATH := "user://tests/settings.cfg"

var _volumes: Dictionary[StringName, int] = {}
var _fullscreen := false
var _auto := false


func before_each() -> void:
	_volumes.assign(PlayerSettings.volumes)
	_fullscreen = PlayerSettings.fullscreen
	_auto = PlayerSettings.auto_advance
	PlayerSettings.path = SETTINGS_PATH
	DirAccess.make_dir_recursive_absolute(SETTINGS_PATH.get_base_dir())


func after_each() -> void:
	if FileAccess.file_exists(SETTINGS_PATH):
		DirAccess.remove_absolute(SETTINGS_PATH)
	PlayerSettings.path = PlayerSettings.DEFAULT_PATH
	PlayerSettings.volumes.assign(_volumes)
	PlayerSettings.fullscreen = _fullscreen
	PlayerSettings.auto_advance = _auto
	for bus in PlayerSettings.VOLUME_BUSES:
		PlayerSettings.apply_volume(bus)


func test_settings_are_kept_and_read_back() -> void:
	PlayerSettings.volumes[&"Music"] = 30
	PlayerSettings.volumes[&"Voice"] = 80
	PlayerSettings.auto_advance = true
	PlayerSettings.write()
	PlayerSettings.volumes[&"Music"] = 100
	PlayerSettings.volumes[&"Voice"] = 100
	PlayerSettings.auto_advance = false
	PlayerSettings.read()
	assert_eq(PlayerSettings.volumes[&"Music"], 30)
	assert_eq(PlayerSettings.volumes[&"Voice"], 80)
	assert_true(PlayerSettings.auto_advance)


func test_junk_in_the_file_leaves_the_settings_as_they_were() -> void:
	var file := ConfigFile.new()
	file.set_value("audio", "music", "loud")
	file.set_value("audio", "sfx", 400)
	file.set_value("play", "auto_skip", "yes")
	file.save(SETTINGS_PATH)
	PlayerSettings.volumes[&"Music"] = 70
	PlayerSettings.auto_advance = false
	PlayerSettings.read()
	assert_eq(PlayerSettings.volumes[&"Music"], 70, "a word is no volume")
	assert_eq(PlayerSettings.volumes[&"SFX"], PlayerSettings.FULL_VOLUME, "a volume past full is held at full")
	assert_false(PlayerSettings.auto_advance)


func test_a_volume_reaches_its_bus_and_nothing_mutes_it() -> void:
	var bus := AudioServer.get_bus_index(&"SFX")
	PlayerSettings.volumes[&"SFX"] = 50
	PlayerSettings.apply_volume(&"SFX")
	assert_false(AudioServer.is_bus_mute(bus))
	assert_almost_eq(AudioServer.get_bus_volume_db(bus), linear_to_db(0.5), 0.01)
	PlayerSettings.volumes[&"SFX"] = 0
	PlayerSettings.apply_volume(&"SFX")
	assert_true(AudioServer.is_bus_mute(bus))
