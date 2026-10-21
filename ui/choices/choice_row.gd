class_name ChoiceRow
extends Control
## The choice row: the options as muted hand-lettered words in a row just above the dialogue box,
## with no box and no divider. Point at a word to light it, then click it or press its number.
## A control on the stage can light and pick options too. It listens for input only while it offers.

## Emitted when the pointer moves onto a word, or off all of them ([code]-1[/code]).
signal hovered(index: int)
## Emitted when the row starts offering [param count] options.
signal offered(count: int)
## Emitted once, when an option is picked.
signal committed(index: int)

## The row the words sit in.
@export var row: HBoxContainer
## The word each option is shown with.
@export var word_scene: PackedScene
## Gap between the row and the top of the dialogue box.
@export_range(0.0, 200.0, 1.0) var gap_above_box := 6.0
## Seconds the row takes to fade in.
@export_range(0.0, 2.0, 0.01) var fade_in_duration := 0.25
## Seconds the pick stays on screen before the row fades.
@export_range(0.0, 3.0, 0.01) var linger := 0.45
## Seconds the row takes to fade out.
@export_range(0.0, 2.0, 0.01) var fade_out_duration := 0.3

var _words: Array[ChoiceWord] = []
var _live := false
var _pointed := -1
var _highlighted := -1


func _ready() -> void:
	modulate.a = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if not _live:
		return
	for i in _words.size():
		if event.is_action_pressed(StringName("choose_%d" % (i + 1))):
			get_viewport().set_input_as_handled()
			commit(i)
			return


## Shows [param labels] as words just above [param box], and waits for one to be picked. Returns its index.
func offer(labels: PackedStringArray, box: Rect2) -> int:
	_clear()
	for i in labels.size():
		var word := word_scene.instantiate() as ChoiceWord
		word.text = labels[i]
		word.index = i
		word.pointed.connect(_on_word_pointed)
		word.clicked.connect(_on_word_clicked)
		row.add_child(word)
		_words.append(word)
	var height := row.get_combined_minimum_size().y
	row.position = Vector2(0.0, box.position.y - gap_above_box - height)
	row.size = Vector2(size.x, height)
	_pointed = -1
	_highlighted = -1
	_live = true
	create_tween().tween_property(self, ^"modulate:a", 1.0, fade_in_duration)
	offered.emit(labels.size())
	return await committed


## Lights the option at [param index] as if pointed at, from a control elsewhere. [code]-1[/code] clears it.
func highlight(index: int) -> void:
	if _live:
		_highlighted = index
		_refresh()


## Picks the option at [param index]: it stays amber, the others fade, and the row goes.
func commit(index: int) -> void:
	if not _live or index < 0 or index >= _words.size():
		return
	_live = false
	for word in _words:
		word.look = ChoiceWord.Look.PICKED if word.index == index else ChoiceWord.Look.PASSED
	committed.emit(index)
	var tween := create_tween()
	tween.tween_interval(linger)
	tween.tween_property(self, ^"modulate:a", 0.0, fade_out_duration)


## Whether the row is waiting for a pick.
func is_offering() -> bool:
	return _live


func _refresh() -> void:
	for word in _words:
		var lit := word.index == _pointed or word.index == _highlighted
		word.look = ChoiceWord.Look.LIFTED if lit else ChoiceWord.Look.RESTING


func _clear() -> void:
	for word in _words:
		word.queue_free()
	_words.clear()


func _on_word_pointed(word: ChoiceWord, is_pointed: bool) -> void:
	if not _live:
		return
	if is_pointed:
		_pointed = word.index
	elif _pointed == word.index:
		_pointed = -1
	_refresh()
	hovered.emit(_pointed)


func _on_word_clicked(word: ChoiceWord) -> void:
	commit(word.index)
