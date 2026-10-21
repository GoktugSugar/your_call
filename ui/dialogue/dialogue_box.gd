class_name DialogueBox
extends Control
## The dialogue box: a hand-drawn frame floating just above the bottom edge, sized to its text and
## growing upward. Lines ink on in it in the hand-lettered face, a page of whole sentences at a time.
## A click or key finishes the page, then moves on. It listens for input only while it waits on the player.

## Emitted when a page appears.
signal page_shown(line: LineData, page: int, page_count: int)
## Emitted when a page starts or stops inking on.
signal typing_changed(typing: bool)
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
## How fast the text inks on.
@export_range(1.0, 400.0, 1.0) var characters_per_second := 42.0
## Extra pause after a comma, colon or semicolon, in seconds.
@export_range(0.0, 1.0, 0.01) var comma_pause := 0.06
## Extra pause after the end of a sentence, in seconds.
@export_range(0.0, 2.0, 0.01) var sentence_pause := 0.26
## How many characters the soft leading edge of the ink spans.
@export_range(0.0, 20.0, 0.1) var ink_edge := 3.0

@export_group("Opening and closing")
## Seconds the frame takes to draw itself on when the box opens.
@export_range(0.0, 2.0, 0.01) var open_duration := 0.22
## Seconds the box takes to fade away when it closes.
@export_range(0.0, 2.0, 0.01) var close_duration := 0.22

## Extra width given to a measured page, so rounding never wraps a line the measure kept whole.
const _WRAP_SLACK := 2.0

var _effect := InkOnEffect.new()
var _schedule := PackedFloat32Array()
var _elapsed := 0.0
var _typing := false
var _waiting := false
var _open := false
var _max_height := 0.0


func _ready() -> void:
	text_label.install_effect(_effect)
	_effect.edge = ink_edge
	measure_label.size = Vector2(max_text_width, 0.0)
	measure_label.text = "\n".join(PackedStringArray(range(max_lines).map(func(_i: int) -> String: return "Ag")))
	_max_height = measure_label.get_content_height()
	modulate.a = 0.0
	set_process(false)


func _process(delta: float) -> void:
	_elapsed += delta
	_effect.progress = _progress_at(_elapsed)
	if _effect.progress >= _schedule.size() - 1 + ink_edge:
		_end_typing()


func _unhandled_input(event: InputEvent) -> void:
	if (_typing or _waiting) and event.is_action_pressed(&"advance"):
		get_viewport().set_input_as_handled()
		advance()


## Shows [param lines] in turn, a page at a time, waiting for the player after each page.
## With [param hold_last], the last page stays up and this returns as soon as it has inked on.
func say(lines: Array[LineData], hold_last := false) -> void:
	for line_index in lines.size():
		var line := lines[line_index]
		var pages := paginate(line.text)
		for page_index in pages.size():
			await _show_page(line, pages[page_index], page_index, pages.size())
			if hold_last and line_index == lines.size() - 1 and page_index == pages.size() - 1:
				return
			await _wait_for_player()


## Fades the box away.
func close() -> void:
	if not _open:
		return
	_open = false
	var tween := create_tween()
	tween.tween_property(self, ^"modulate:a", 0.0, close_duration)
	await tween.finished


## Finishes the page if it is still inking on, otherwise moves on from it.
func advance() -> void:
	if _typing:
		_effect.progress = _schedule.size() - 1 + ink_edge
		_end_typing()
	elif _waiting:
		_waiting = false
		waiting_changed.emit(false)
		advanced.emit()


## Whether the box is waiting for the player to move on.
func is_waiting() -> bool:
	return _waiting


## The frame's rect on the canvas.
func frame_rect() -> Rect2:
	return frame.get_global_rect()


## The pages [param text] would take, as markup.
func paginate(text: String) -> PackedStringArray:
	return Pager.paginate(text, _fits)


func _show_page(line: LineData, page: String, index: int, count: int) -> void:
	var markup := Markup.to_bbcode(page, InkPalette.get_default())
	var bbcode := "[inkon]%s[/inkon]" % markup
	measure_label.text = markup
	var text_size := Vector2(minf(measure_label.get_content_width() + _WRAP_SLACK, max_text_width), measure_label.get_content_height())
	var frame_size := text_size + padding * 2.0
	frame.size = frame_size
	frame.position = Vector2((size.x - frame_size.x) * 0.5, size.y - bottom_margin - frame_size.y)
	text_label.position = padding
	text_label.size = text_size
	text_label.text = bbcode
	_build_schedule(text_label.get_parsed_text())
	_effect.progress = 0.0
	if not _open:
		_open = true
		frame.reveal = 0.0
		var tween := create_tween().set_parallel(true)
		tween.tween_property(self, ^"modulate:a", 1.0, open_duration * 0.5)
		tween.tween_property(frame, ^"reveal", 1.0, open_duration)
	page_shown.emit(line, index, count)
	_elapsed = 0.0
	_typing = true
	set_process(true)
	typing_changed.emit(true)
	while _typing:
		await typing_changed


func _wait_for_player() -> void:
	_waiting = true
	waiting_changed.emit(true)
	await advanced


func _end_typing() -> void:
	if not _typing:
		return
	_typing = false
	set_process(false)
	typing_changed.emit(false)


func _fits(markup: String) -> bool:
	measure_label.text = Markup.to_bbcode(markup, InkPalette.get_default())
	return measure_label.get_content_height() <= _max_height + 0.5


## Works out when each character inks on: a steady pace, with a breath after punctuation.
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
