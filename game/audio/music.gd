extends Node
## The background music (autoload [code]Music[/code]): one quiet track looping under everything,
## carried unbroken from scene to scene. The main theme plays on the menu and in every chapter that names
## no track of its own; a chapter that names one crossfades to it as it starts, and back again after.
## It fades in when it starts, and dips while someone talks so the voice stays clear. A missing track is
## simply silence. A browser lets no sound play until the player first clicks or presses a key, so in
## one the music waits for that and fades in then; anything else that should wait for sound can too
## ([signal sound_allowed]).

## Emitted when sound may play: in a browser, at the player's first click or key.
signal sound_allowed

## Where the tracks are: a track called [code]campaign[/code] is [code]campaign.ogg[/code] there.
@export_dir var tracks_dir := "res://assets/audio/music"
## The track played on the menu and in every chapter that names none.
@export var main_track := &"main"
## How loud the music plays, in decibels, before the Music bus and the player's settings.
@export_range(-60.0, 6.0, 0.5) var volume_db := -14.0
## Seconds the music takes to fade in when it first starts.
@export_range(0.0, 10.0, 0.1) var fade_in := 2.5
## Seconds one track takes to give way to another.
@export_range(0.0, 10.0, 0.1) var crossfade := 2.0
## How much quieter the music goes while someone talks, in decibels.
@export_range(0.0, 30.0, 0.5) var duck_db := 6.0
## Seconds the music takes to dip or come back up.
@export_range(0.0, 3.0, 0.05) var duck_fade := 0.5

## Silence, in decibels.
const _SILENT_DB := -60.0
## The file a track is kept in, by its name.
const _TRACK_FILE := "%s/%s.ogg"

## The track playing, or giving way to the next, by name. Empty when none is.
var playing := &""
## Whether sound may play yet. Always, but in a browser before the player's first click or key.
var can_sound := not OS.has_feature("web")

var _players: Array[AudioStreamPlayer] = []
## How far each player is faded in, from 0 to 1, by player. Tweened.
var _fades := {}
var _fading := {}
var _ducked := false
## How far the music is dipped right now, in decibels. Tweened.
var _dip := 0.0
var _dipping: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.bus = &"Music"
		# Streamed, a little at a time: a browser would otherwise decode a whole track before it played,
		# holding the game still for half a second and keeping minutes of sound in memory.
		player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
		add_child(player)
		_players.append(player)
		_fades[player] = 0.0
	set_process_input(not can_sound)
	play(main_track)


func _input(event: InputEvent) -> void:
	var gesture := event is InputEventMouseButton or event is InputEventKey or event is InputEventScreenTouch
	if can_sound or not gesture or not event.is_pressed():
		return
	can_sound = true
	set_process_input(false)
	var waiting := playing
	playing = &""
	play(waiting)
	sound_allowed.emit()


func _process(_delta: float) -> void:
	for player in _players:
		var fade: float = _fades[player]
		player.volume_db = volume_db - _dip + (linear_to_db(fade) if fade > 0.0001 else _SILENT_DB)


## Plays the track called [param track] ([member main_track] when empty), crossfading from whatever
## plays now, or fading it in when nothing does. Does nothing when it is playing already, or when there
## is no such track.
func play(track: StringName = &"") -> void:
	if track == &"":
		track = main_track
	if track == playing:
		return
	var path := _TRACK_FILE % [tracks_dir, track]
	if not ResourceLoader.exists(path):
		return
	var stream := load(path) as AudioStream
	if stream == null:
		return
	if "loop" in stream:
		stream.set(&"loop", true)
	var first := playing == &""
	playing = track
	if not can_sound:
		# Asked for before the browser lets sound play: it starts, faded in, at the first gesture.
		return
	var incoming := _players[0] if not _players[0].playing or _fades[_players[0]] < _fades[_players[1]] else _players[1]
	var outgoing := _players[1] if incoming == _players[0] else _players[0]
	incoming.stream = stream
	_fades[incoming] = 0.0
	incoming.play()
	_fade(incoming, 1.0, fade_in if first else crossfade)
	if outgoing.playing:
		_fade(outgoing, 0.0, crossfade)


## Dips the music while someone talks, and brings it back up when they stop.
func duck(talking: bool) -> void:
	if talking == _ducked:
		return
	_ducked = talking
	if _dipping != null and _dipping.is_valid():
		_dipping.kill()
	_dipping = create_tween()
	_dipping.tween_method(func(value: float) -> void: _dip = value, _dip, duck_db if talking else 0.0, duck_fade) \
			.set_trans(Tween.TRANS_SINE)


func _fade(player: AudioStreamPlayer, to: float, seconds: float) -> void:
	var running: Tween = _fading.get(player)
	if running != null and running.is_valid():
		running.kill()
	var tween := create_tween()
	tween.tween_method(func(value: float) -> void: _fades[player] = value, _fades[player], to, seconds) \
			.set_trans(Tween.TRANS_SINE)
	if to <= 0.0:
		tween.tween_callback(player.stop)
	_fading[player] = tween
