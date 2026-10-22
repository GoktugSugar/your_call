class_name DialogueBox
extends Control
## The dialogue box: a hand-drawn frame floating just above the bottom edge, sized to its text and
## growing upward. Lines ink on in it in the hand-lettered face, a page of whole sentences at a time.
## A voiced line inks on in time with its voice, and each page plays only its own stretch of the take.
## The first click finishes the page while the voice plays on; the next click moves on, fading the
## voice out if it is still going. It listens for input only while it waits on the player. It always
## knows which character is being said, for a speaker whose mouth moves with the words.

## Emitted when a page appears.
signal page_shown(line: LineData, page: int, page_count: int)
## Emitted when a page starts or stops inking on.
signal typing_changed(typing: bool)
## Emitted when the speaker starts or stops talking: while a page inks on or its voice plays.
signal talking_changed(talking: bool)
## Emitted when the box starts or stops waiting for the player to move on.
signal waiting_changed(waiting: bool)
## Emitted when the player moves on from a page.
signal advanced

## The frame drawn around the text.
@export var frame: InkFrame
## Where the page is shown.
@export var text_label: RichTextLabel
## An unseen twin of the text label, used to measure pages before they are shown.
@export var measure_label: RichTextLabel
## Plays the voice, on the Voice bus.
@export var voice_player: AudioStreamPlayer

@export_group("Layout")
## The widest the text may run before it wraps, in pixels.
@export_range(200.0, 1800.0, 1.0) var max_text_width := 1180.0
## Space between the text and the frame.
@export var padding := Vector2(46.0, 22.0)
## Gap between the frame and the bottom of the screen.
@export_range(0.0, 400.0, 1.0) var bottom_margin := 34.0
## The most lines a page may take before the next sentence goes on a new page.
@export_range(1, 12) var max_lines := 3

@export_group("Typing")
## How fast unvoiced text inks on.
@export_range(1.0, 400.0, 1.0) var characters_per_second := 42.0
## Extra pause after a comma, colon or semicolon in unvoiced text, in seconds.
@export_range(0.0, 1.0, 0.01) var comma_pause := 0.06
## Extra pause after the end of a sentence in unvoiced text, in seconds.
@export_range(0.0, 2.0, 0.01) var sentence_pause := 0.26
## How many characters the soft leading edge of the ink spans.
@export_range(0.0, 20.0, 0.1) var ink_edge := 3.0

@export_group("Voice")
## How fast the voice plays: 1 is as recorded. The Voice bus shifts the pitch back, so a faster voice
## sounds like the same speaker talking faster rather than a higher one.
@export_range(0.5, 2.0, 0.01) var voice_speed := 1.0:
	set(value):
		voice_speed = value
		if is_node_ready():
			_apply_voice_speed()
## The bus the voice plays on. Its first effect must be the pitch shift that keeps the speaker's pitch.
@export var voice_bus := &"Voice"
## Seconds the voice takes to fade out when the player moves on while it is still playing.
@export_range(0.0, 1.0, 0.01) var voice_fade := 0.12
## Seconds of sound kept after a page's last character, so the take is not clipped. It never runs
## into the next page's first word.
@export_range(0.0, 1.0, 0.01) var voice_tail := 0.3
## Seconds a page's sound stops short of the next page's first word.
@export_range(0.0, 0.5, 0.005) var next_word_margin := 0.04

@export_group("Opening and closing")
## Seconds the frame takes to draw itself on when the box opens.
@export_range(0.0, 2.0, 0.01) var open_duration := 0.22
## Seconds the box takes to fade away when it closes.
@export_range(0.0, 2.0, 0.01) var close_duration := 0.22

@export_group("Moving on by itself")
## Seconds a page that moves on by itself stays up once it has inked on and its voice has finished.
@export_range(0.0, 5.0, 0.05) var auto_hold := 0.9

## Extra width given to a measured page on top of a space, so rounding never wraps a line the measure
## kept whole. A line only stays whole with room for the space it broke at, which its measured width leaves out.
const _WRAP_SLACK := 2.0
## Loud enough to call silence, in decibels.
const _SILENT_DB := -60.0

var _effect := InkOnEffect.new()
## The page's text without markup: the characters whose times [member _schedule] holds.
var _plain := ""
var _schedule := PackedFloat32Array()
var _elapsed := 0.0
var _typing := false
var _talking := false
var _waiting := false
var _open := false
var _max_height := 0.0
## Two players take turns, so a take fading out never cuts off the next one.
var _players: Array[AudioStreamPlayer] = []
var _current := 0
var _voiced := false
var _voice_start := 0.0
var _voice_end := 0.0
## Counts the pages shown, so a page that moves on by itself never moves a later one on.
var _page_count := 0
## Whether the line up was thrown in over something else, such as a countdown: it takes no clicks.
var _interjecting := false


func _ready() -> void:
	text_label.install_effect(_effect)
	_effect.edge = ink_edge
	measure_label.size = Vector2(max_text_width, 0.0)
	measure_label.text = "\n".join(PackedStringArray(range(max_lines).map(func(_i: int) -> String: return "Ag")))
	_max_height = measure_label.get_content_height()
	var second := voice_player.duplicate() as AudioStreamPlayer
	add_child(second)
	_players = [voice_player, second]
	_apply_voice_speed()
	modulate.a = 0.0
	set_process(false)


func _process(delta: float) -> void:
	var voice := _voice()
	if _voiced and voice.playing:
		# The playback position is in the take's own time; the mixer's lag is in real time.
		var lag := AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
		_elapsed = voice.get_playback_position() + lag * voice.pitch_scale - _voice_start
		if _voice_start + _elapsed >= _voice_end:
			voice.stop()
	else:
		_elapsed += delta
	if _typing:
		_effect.progress = _progress_at(_elapsed)
		if _effect.progress >= _schedule.size() - 1 + ink_edge:
			_end_typing()
	_update_talking()
	if not _typing and not voice.playing:
		set_process(false)


func _unhandled_input(event: InputEvent) -> void:
	if (_typing or _waiting) and not _interjecting and event.is_action_pressed(&"advance"):
		get_viewport().set_input_as_handled()
		advance()


## Shows [param lines] in turn, a page at a time, waiting for the player after each page.
## With [param hold_last], the last page stays up and this returns as soon as it has inked on.
## With [param auto], each page moves on by itself once it has been said, unless the player moves it first.
func say(lines: Array[LineData], hold_last := false, auto := false) -> void:
	_interjecting = false
	for line_index in lines.size():
		var line := lines[line_index]
		var clip := VoiceLibrary.clip_for(line) if line.voiced else null
		var spoken := Markup.strip(line.text)
		var pages := paginate(line.text)
		var cursor := 0
		for page_index in pages.size():
			var from := spoken.find(Markup.strip(pages[page_index]), cursor)
			if from >= 0:
				cursor = from + Markup.strip(pages[page_index]).length()
			await _show_page(line, pages[page_index], page_index, pages.size(), clip if from >= 0 else null, from)
			if hold_last and line_index == lines.size() - 1 and page_index == pages.size() - 1:
				return
			await _wait_for_player(auto)


## Shows the first page of [param line] at once, in place of whatever is up, without waiting for the
## player, the way the imp needles over a countdown. Its voice plays, it takes no clicks, and it stays
## up until the next line or [method close].
func interject(line: LineData) -> void:
	_interjecting = true
	_waiting = false
	_stop_voice(voice_fade)
	_end_typing()
	var pages := paginate(line.text)
	var clip := VoiceLibrary.clip_for(line) if line.voiced else null
	# Not awaited: the page inks on while whatever threw it in carries on.
	_show_page(line, pages[0], 0, pages.size(), clip, 0 if clip != null else -1)


## Fades the box away, and the voice with it.
func close() -> void:
	_interjecting = false
	if not _open:
		return
	_open = false
	_stop_voice(voice_fade)
	var tween := create_tween()
	tween.tween_property(self, ^"modulate:a", 0.0, close_duration)
	await tween.finished


## Finishes the page if it is still inking on, letting its voice play on. Otherwise moves on from
## the page, fading the voice out if it is still going.
func advance() -> void:
	if _typing:
		_effect.progress = _schedule.size() - 1 + ink_edge
		_end_typing()
	elif _waiting:
		_stop_voice(voice_fade)
		_waiting = false
		waiting_changed.emit(false)
		advanced.emit()


## Whether the box is waiting for the player to move on.
func is_waiting() -> bool:
	return _waiting


## The character being said now, or [param lead] seconds from now. A voiced page is read off the voice's
## own clock, so it keeps following the voice after a click has finished showing the page; an unvoiced
## one is read off its typing. Spaces and punctuation count, as the pauses they are. Empty when nothing
## is being said.
func spoken_character(lead := 0.0) -> String:
	if not _talking:
		return ""
	# The voice's clock runs at the take's own speed.
	return character_at(_plain, _schedule, _elapsed + lead * (voice_speed if _voiced else 1.0))


## The character of [param text] being said [param time] seconds in, by [param schedule]: when each of
## its characters starts, with one more entry for when the last one ends. Empty before the first starts
## and once the last has ended.
static func character_at(text: String, schedule: PackedFloat32Array, time: float) -> String:
	var count := mini(text.length(), schedule.size() - 1)
	if count <= 0 or time < schedule[0] or time >= schedule[count]:
		return ""
	return text[clampi(schedule.bsearch(time, false) - 1, 0, count - 1)]


## The frame's rect on the canvas.
func frame_rect() -> Rect2:
	return frame.get_global_rect()


## The pages [param text] would take, as markup.
func paginate(text: String) -> PackedStringArray:
	return Pager.paginate(text, _fits)


func _show_page(line: LineData, page: String, index: int, count: int, clip: VoiceClip, from: int) -> void:
	var markup := Markup.to_bbcode(page, InkPalette.get_default())
	var text_size := text_size_for(markup)
	var frame_size := text_size + padding * 2.0
	frame.size = frame_size
	frame.position = Vector2((size.x - frame_size.x) * 0.5, size.y - bottom_margin - frame_size.y)
	text_label.position = padding
	text_label.size = text_size
	text_label.text = "[inkon]%s[/inkon]" % markup
	var plain := text_label.get_parsed_text()
	_plain = plain
	_start_voice(clip, from, plain.length())
	if not _voiced:
		_build_schedule(plain)
	_effect.progress = 0.0
	if not _open:
		_open = true
		frame.reveal = 0.0
		var tween := create_tween().set_parallel(true)
		tween.tween_property(self, ^"modulate:a", 1.0, open_duration * 0.5)
		tween.tween_property(frame, ^"reveal", 1.0, open_duration)
	page_shown.emit(line, index, count)
	_page_count += 1
	_elapsed = 0.0
	_typing = true
	set_process(true)
	typing_changed.emit(true)
	_update_talking()
	while _typing:
		await typing_changed


## Plays the stretch of [param clip] that speaks [param length] characters from [param from], and
## inks the page on to its timings. Without a clip the page stays unvoiced.
func _start_voice(clip: VoiceClip, from: int, length: int) -> void:
	_voiced = clip != null and from >= 0
	if not _voiced:
		return
	var stretch := clip.span(from, from + length)
	_schedule = clip.schedule(from, from + length)
	_voice_start = stretch.x
	_voice_end = minf(stretch.y + voice_tail, clip.next_start(from + length) - next_word_margin)
	var voice := _voice()
	voice.stop()
	voice.volume_db = 0.0
	voice.stream = clip.stream
	voice.play(_voice_start)


## Stops the voice, fading it over [param fade] seconds on its own player while the other is free for the next take.
func _stop_voice(fade: float) -> void:
	var voice := _voice()
	if not voice.playing:
		return
	if fade <= 0.0:
		voice.stop()
		return
	_current = 1 - _current
	var tween := create_tween()
	tween.tween_property(voice, ^"volume_db", _SILENT_DB, fade)
	tween.tween_callback(voice.stop)
	_update_talking()


## Plays the voice at [member voice_speed], with the bus shifting its pitch back down.
func _apply_voice_speed() -> void:
	for player in _players:
		player.pitch_scale = voice_speed
	var bus := AudioServer.get_bus_index(voice_bus)
	if bus < 0 or AudioServer.get_bus_effect_count(bus) == 0:
		return
	var shift := AudioServer.get_bus_effect(bus, 0) as AudioEffectPitchShift
	if shift != null:
		shift.pitch_scale = 1.0 / voice_speed
		AudioServer.set_bus_effect_enabled(bus, 0, not is_equal_approx(voice_speed, 1.0))


func _voice() -> AudioStreamPlayer:
	return _players[_current]


func _update_talking() -> void:
	var talking := _typing or (_voiced and _voice().playing)
	if talking != _talking:
		_talking = talking
		talking_changed.emit(talking)


func _wait_for_player(auto := false) -> void:
	_waiting = true
	waiting_changed.emit(true)
	if auto:
		_move_on_by_itself(_page_count)
	await advanced


## Moves on from page number [param page] once its voice has finished and it has stayed up for
## [member auto_hold], unless the player has moved on already.
func _move_on_by_itself(page: int) -> void:
	while _voiced and _voice().playing and page == _page_count:
		await get_tree().process_frame
	await get_tree().create_timer(auto_hold, false).timeout
	if _waiting and page == _page_count:
		advance()


func _end_typing() -> void:
	if not _typing:
		return
	_typing = false
	typing_changed.emit(false)
	_update_talking()


## The size a page's text takes in the box, given as BBCode: its widest line, with room to keep
## every line whole, by its height.
func text_size_for(bbcode: String) -> Vector2:
	measure_label.text = bbcode
	return Vector2(minf(measure_label.get_content_width() + _wrap_room(), max_text_width), measure_label.get_content_height())


## Width a page needs beyond its measured width to keep its lines whole: a space, and a little slack.
func _wrap_room() -> float:
	var font := measure_label.get_theme_font(&"normal_font")
	var font_size := measure_label.get_theme_font_size(&"normal_font_size")
	return font.get_string_size(" ", HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x + _WRAP_SLACK


func _fits(markup: String) -> bool:
	measure_label.text = Markup.to_bbcode(markup, InkPalette.get_default())
	return measure_label.get_content_height() <= _max_height + 0.5


## Works out when each character of an unvoiced page inks on: a steady pace, with a breath after punctuation.
func _build_schedule(plain: String) -> void:
	_schedule.resize(plain.length() + 1)
	_schedule[0] = 0.0
	var step := 1.0 / characters_per_second
	for i in plain.length():
		var pause := 0.0
		var next_is_gap := i + 1 >= plain.length() or plain[i + 1] == " "
		if ".?!".contains(plain[i]) and next_is_gap:
			pause = sentence_pause
		elif ",;:".contains(plain[i]):
			pause = comma_pause
		_schedule[i + 1] = _schedule[i] + step + pause


## How many characters are on the page [param time] seconds in, counting the one being inked as a fraction.
func _progress_at(time: float) -> float:
	var last := _schedule.size() - 1
	if time >= _schedule[last]:
		return last + (time - _schedule[last]) * characters_per_second
	var i := clampi(_schedule.bsearch(time, false) - 1, 0, last - 1)
	return i + (time - _schedule[i]) / maxf(_schedule[i + 1] - _schedule[i], 0.0001)
