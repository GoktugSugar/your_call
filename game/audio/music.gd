extends Node
## The background music (autoload [code]Music[/code]): one quiet track looping under everything,
## carried unbroken from scene to scene. It fades in when it starts, and dips while someone talks so
## the voice stays clear. A missing track is simply silence.

## The track to loop. Kept as a path, so a missing file means silence rather than an error.
@export_file("*.mp3", "*.ogg", "*.wav") var track_path := "res://assets/audio/music/bgm_placeholder.mp3"
## How loud the track plays, in decibels, before the Music bus and the player's settings.
@export_range(-60.0, 6.0, 0.5) var volume_db := -14.0
## Seconds the track takes to fade in when it starts.
@export_range(0.0, 10.0, 0.1) var fade_in := 2.5
## How much quieter the track goes while someone talks, in decibels.
@export_range(0.0, 30.0, 0.5) var duck_db := 6.0
## Seconds the track takes to dip or come back up.
@export_range(0.0, 3.0, 0.05) var duck_fade := 0.5

## Silence, in decibels.
const _SILENT_DB := -60.0

var _player := AudioStreamPlayer.new()
var _ducked := false
var _level: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player.bus = &"Music"
	add_child(_player)
	play_track(track_path)


## Starts looping the track at [param path], fading it in. Does nothing if there is no such track.
func play_track(path: String) -> void:
	if not ResourceLoader.exists(path):
		return
	var stream := load(path) as AudioStream
	if stream == null:
		return
	if "loop" in stream:
		stream.set(&"loop", true)
	_player.stream = stream
	_player.volume_db = _SILENT_DB
	_player.play()
	_fade_to(_target_db(), fade_in)


## Dips the track while someone talks, and brings it back up when they stop.
func duck(talking: bool) -> void:
	if talking == _ducked:
		return
	_ducked = talking
	_fade_to(_target_db(), duck_fade)


func _target_db() -> float:
	return volume_db - (duck_db if _ducked else 0.0)


func _fade_to(level: float, seconds: float) -> void:
	if _level != null and _level.is_valid():
		_level.kill()
	_level = create_tween()
	_level.tween_property(_player, ^"volume_db", level, seconds).set_trans(Tween.TRANS_SINE)
