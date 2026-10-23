extends Node
## The sound effects (autoload [code]Sfx[/code]): plays a [SoundCue] on the SFX bus from a small pool of
## players, one of its takes at a time with its pitch wandering a little, so nothing heard often repeats
## exactly or piles up. Everything it plays dips while someone talks, the way the music does, so the
## voices stay on top. A sound held on, such as a loop, plays until it is let go by the number it was
## played under.

## The bus every sound plays on, which the player's sound effects volume sets.
@export var bus := &"SFX"
## How many sounds can play at once. Past that, the one that has played longest gives way.
@export_range(1, 64) var pool_size := 16
## How much quieter every sound goes while someone talks, in decibels.
@export_range(0.0, 30.0, 0.5) var duck_db := 4.0
## Seconds the sounds take to dip or come back up.
@export_range(0.0, 3.0, 0.05) var duck_fade := 0.3
## Seconds a sound let go takes to fade, unless the caller says.
@export_range(0.0, 3.0, 0.01) var release_fade := 0.2

var _players: Array[AudioStreamPlayer] = []
## When each player started, by player, so the oldest gives way when every one is busy.
var _started := {}
## The number of the sound each busy player is playing, by player, as [method play] handed it out.
var _plays := {}
## The number the next sound played is handed.
var _next_play := 1
## Each playing player's own level before the dip, by player.
var _levels := {}
## The fade of each player being let go, by player.
var _fades := {}
## The take each cue played last, by cue, so it picks another next time.
var _last_take := {}
## When each cue last played, in milliseconds, by cue.
var _played_at := {}
var _ducked := false
## How far everything is dipped right now, in decibels. Tweened.
var _dip := 0.0
var _dipping: Tween
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	for i in pool_size:
		var player := AudioStreamPlayer.new()
		player.bus = bus
		player.finished.connect(func() -> void:
			_levels.erase(player)
			_plays.erase(player))
		add_child(player)
		_players.append(player)


## Plays [param cue] once, [param volume_offset] decibels louder or quieter than it sets, and returns the
## number it plays under, for the sound to be let go later; 0 when the cue has nothing to play or is
## cooling down.
func play(cue: SoundCue, volume_offset := 0.0) -> int:
	if cue == null or cue.takes.is_empty():
		return 0
	var now := Time.get_ticks_msec()
	if cue.cool_down > 0.0 and now - int(_played_at.get(cue, -1000000)) < cue.cool_down * 1000.0:
		return 0
	_played_at[cue] = now
	var player := _free_player()
	var fade: Tween = _fades.get(player)
	if fade != null and fade.is_valid():
		fade.kill()
	_fades.erase(player)
	player.stop()
	player.process_mode = Node.PROCESS_MODE_ALWAYS if cue.through_pause else Node.PROCESS_MODE_PAUSABLE
	player.stream = _pick(cue)
	player.pitch_scale = 1.0 + _rng.randf_range(-cue.pitch_spread, cue.pitch_spread)
	_levels[player] = cue.volume_db + volume_offset
	player.volume_db = _levels[player] - _dip
	_started[player] = now
	_plays[player] = _next_play
	_next_play += 1
	player.play()
	return _plays[player]


## Lets go of the sound [method play] handed the number [param sound], [param after] seconds from now,
## fading it out over [param seconds] ([member release_fade] when below zero). Does nothing once that
## sound has ended, or its player has gone on to another.
func release(sound: int, seconds := -1.0, after := 0.0) -> void:
	var player: AudioStreamPlayer = _plays.find_key(sound) if sound != 0 else null
	if player == null or not player.playing or not _levels.has(player):
		return
	var fade := create_tween()
	fade.tween_interval(after)
	fade.tween_callback(func() -> void: _levels.erase(player))
	fade.tween_property(player, ^"volume_db", -60.0, release_fade if seconds < 0.0 else seconds)
	fade.tween_callback(player.stop)
	_fades[player] = fade


## Dips every sound while someone talks, and brings them back up when they stop.
func duck(talking: bool) -> void:
	if talking == _ducked:
		return
	_ducked = talking
	if _dipping != null and _dipping.is_valid():
		_dipping.kill()
	_dipping = create_tween()
	_dipping.tween_method(_set_dip, _dip, duck_db if talking else 0.0, duck_fade).set_trans(Tween.TRANS_SINE)


func _set_dip(value: float) -> void:
	_dip = value
	for player: AudioStreamPlayer in _levels:
		player.volume_db = _levels[player] - _dip


## A take of [param cue]: any but the one it played last, while it has another.
func _pick(cue: SoundCue) -> AudioStream:
	var count := cue.takes.size()
	var index := _rng.randi_range(0, count - 1)
	if count > 1 and index == int(_last_take.get(cue, -1)):
		index = (index + 1 + _rng.randi_range(0, count - 2)) % count
	_last_take[cue] = index
	return cue.takes[index]


## A player with nothing to play, or the one that has played longest when every one is busy.
func _free_player() -> AudioStreamPlayer:
	var oldest := _players[0]
	for player in _players:
		if not player.playing:
			return player
		if int(_started.get(player, 0)) < int(_started.get(oldest, 0)):
			oldest = player
	_levels.erase(oldest)
	return oldest
