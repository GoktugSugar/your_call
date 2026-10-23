class_name Plea
extends Node2D
## Words floating over a soul on the tracks, inked on a character at a time once the stage is drawn.
## They bob with the page's boil and fade when the soul dies or the stage goes. Given a voice clip,
## they are said aloud and ink on in time with it.
## Its origin is the bottom middle of the words, which sits just over the soul's head.

## Emitted once the words have been said: inked on, and their voice, if they have one, played out.
signal said

## The label the words are set in. It grows upward from the origin as the words wrap.
@export var label: RichTextLabel
## Plays the words' voice, on the Voice bus.
@export var voice_player: AudioStreamPlayer
## Seconds each character takes to ink on when the words have no voice, and to finish the soft edge
## after a voice.
@export_range(0.0, 0.5, 0.005) var seconds_per_character := 0.03
## How many characters the soft leading edge spans while the words ink on.
@export_range(0.0, 10.0, 0.1) var ink_edge := 3.0
## Seconds the words take to fade away.
@export_range(0.0, 3.0, 0.01) var fade_duration := 0.4
## How far the words bob up and down, in pixels.
@export_range(0.0, 10.0, 0.1) var bob := 2.0
## Seconds per bob.
@export_range(0.5, 10.0, 0.1) var bob_period := 2.6

var _effect := InkOnEffect.new()
var _rest := Vector2.ZERO
## When each character starts to ink on, in seconds, with one more entry for when the last is done.
var _schedule := PackedFloat32Array()
## Seconds since the words started inking on, in the voice's own time while it plays.
var _elapsed := 0.0
var _saying := false


func _ready() -> void:
	label.install_effect(_effect)
	_effect.edge = ink_edge
	_rest = position
	# Streamed, as the dialogue box's voice is, so a browser never stalls to decode a take whole.
	voice_player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	Ink.boiled.connect(_on_boiled.unbind(1))
	set_process(false)


func _process(delta: float) -> void:
	if voice_player.playing:
		# The playback position runs ahead of what has been heard by the mixer's lag.
		_elapsed = voice_player.get_playback_position() + AudioServer.get_time_since_last_mix() \
				- AudioServer.get_output_latency()
	else:
		_elapsed += delta
	var whole := float(_schedule.size() - 1) + ink_edge
	_effect.progress = minf(InkOnEffect.progress_at(_schedule, _elapsed, 1.0 / maxf(seconds_per_character, 0.001)), whole)
	if _effect.progress >= whole and not voice_player.playing:
		set_process(false)
		_saying = false
		said.emit()


## Sets the words, in markup, without inking them on yet.
func set_words(markup: String) -> void:
	label.text = "[inkon]%s[/inkon]" % Markup.to_bbcode(markup, InkPalette.get_default())
	_effect.progress = 0.0


## Puts the words' bottom middle at [param at], in the parent's space.
func place(at: Vector2) -> void:
	_rest = at
	position = at


## Inks the words on at a steady pace, or says them aloud in [param voice] and inks them on in time
## with it. Returns once they have been said.
func write_on(voice: VoiceClip = null) -> void:
	var count := label.get_total_character_count()
	_elapsed = 0.0
	_saying = true
	if voice != null and Music.can_sound:
		_schedule = voice.schedule(0, count)
		voice_player.stream = voice.stream
		voice_player.play()
	else:
		_schedule.resize(count + 1)
		for i in count + 1:
			_schedule[i] = i * seconds_per_character
	set_process(true)
	await said


## Whether the words are still being said: inking on, or their voice still playing.
func is_saying() -> bool:
	return _saying


## The character being said [param lead] seconds from now, or an empty string when nothing is, by the
## schedule the words ink on by, which is the voice's own while it plays. A mouth follows it, as the
## imp's does on the menu page.
func spoken_character(lead := 0.0) -> String:
	if not _saying:
		return ""
	return DialogueBox.character_at(label.get_parsed_text(), _schedule, _elapsed + lead)


## Stops saying the words at once, voice and all, leaving them as far as they had inked on.
func stop_saying() -> void:
	voice_player.stop()
	set_process(false)
	_saying = false


## Fades the words away.
func fade_out() -> void:
	var tween := create_tween()
	tween.tween_property(self, ^"modulate:a", 0.0, fade_duration)
	await tween.finished


func _on_boiled() -> void:
	position = _rest + Vector2(0.0, sin(Ink.time * TAU / bob_period) * bob)
