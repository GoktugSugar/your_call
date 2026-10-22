class_name TimerStage
extends Stage
## The timer: one button with a word on it and a clock counting down over it. There is no choice row:
## the clock starts with the imp's last word, he needles the player over it, and the player either
## presses the button or lets the clock run out. Stage data:
## [code]{"type": "timer", "seconds": 10, "label": "press", "cues": [0.6, 2.6, 4.0, 5.0, 8.0]}[/code].
## The question's [code]countdown[/code] lines are said at the cues, in seconds after the clock starts,
## or spread evenly over it when there are no cues. The option whose outcome has [code]press[/code] is
## picked by pressing; the other when the clock runs out.

## Emitted when the choice is settled, by a press or by the clock running out.
signal _settled(index: int)

## The set of lines the imp needles the player with over the clock.
const COUNTDOWN_SET := &"countdown"

## The button.
@export var button: PushButton
## The clock over the button.
@export var clock: Label

@export_group("Clock")
## Seconds on the clock when the question does not say.
@export_range(1.0, 120.0, 0.5) var default_seconds := 10.0
## Size of the clock's numbers.
@export_range(8, 300) var clock_size := 120
## Palette role of the clock.
@export var clock_role := &"ink"
## Palette role of the clock in its last seconds.
@export var closing_role := &"amber"
## The last seconds, shown in [member closing_role].
@export_range(0.0, 30.0, 0.5) var closing_seconds := 3.0
## Gap between the top of the button's cap and the bottom of the clock.
@export_range(0.0, 200.0, 1.0) var clock_gap := 24.0

@export_group("Consequence")
## Seconds of nothing happening after the press or the end of the clock.
@export_range(0.0, 5.0, 0.05) var nothing_hold := 1.4

var _press := -1
var _wait := -1
var _seconds := 0.0
var _left := 0.0
var _running := false
var _cue := 0
var _cues := PackedFloat32Array()
var _lines: Array[LineData] = []


func setup(for_question: QuestionData) -> void:
	super.setup(for_question)
	var data := for_question.stage
	button.look = ButtonLook.find(StringName(str(data.get("button", "plain"))))
	button.text = str(data.get("label", ""))
	_seconds = float(data.get("seconds", default_seconds))
	_left = _seconds
	for i in for_question.options.size():
		if bool(for_question.options[i].outcome.get("press", false)):
			_press = i
		else:
			_wait = i
	_lines = for_question.lines_in(COUNTDOWN_SET)
	for cue: Variant in data.get("cues", []):
		_cues.append(float(cue))
	if _cues.size() < _lines.size():
		_cues.clear()
		for i in _lines.size():
			_cues.append(_seconds * (i + 0.5) / _lines.size())
	clock.add_theme_font_size_override(&"font_size", clock_size)
	button.clicked.connect(_on_pressed)
	_show_clock()
	set_process(false)


func enter() -> void:
	clock.modulate.a = 0.0
	create_tween().tween_property(clock, ^"modulate:a", 1.0, enter_duration)
	await super.enter()


func _process(delta: float) -> void:
	if not _running:
		return
	_left = maxf(_left - delta, 0.0)
	var elapsed := _seconds - _left
	while _cue < _lines.size() and elapsed >= _cues[_cue]:
		dialogue.interject(_lines[_cue])
		_cue += 1
	_show_clock()
	if _left <= 0.0:
		_settle(_wait)


func _unhandled_input(event: InputEvent) -> void:
	if _running and event.is_action_pressed(&"choose_1"):
		get_viewport().set_input_as_handled()
		_on_pressed()


func chooses_alone() -> bool:
	return true


## Starts the clock and waits for the press, or for the clock to run out.
func choose() -> int:
	_running = true
	set_process(true)
	button.live = _press >= 0
	return await _settled


func set_choosing(active: bool) -> void:
	if not active:
		button.live = false


## Nothing happens, whichever it was. The button was pressed the moment it was clicked.
func play_consequence(_index: int) -> StringName:
	await get_tree().create_timer(nothing_hold, false).timeout
	return &""


func leave() -> void:
	create_tween().tween_property(clock, ^"modulate:a", 0.0, leave_duration)
	await super.leave()


func option_point(index: int) -> Vector2:
	return button.press_point() if index >= 0 and index == _press else Vector2.INF


func _on_pressed() -> void:
	if _running:
		button.press()
		_settle(_press)


func _settle(index: int) -> void:
	_running = false
	set_process(false)
	button.live = false
	_settled.emit(index)


## Shows the whole seconds left over the button, in the closing colour near the end.
func _show_clock() -> void:
	clock.text = str(ceili(_left))
	clock.add_theme_color_override(&"font_color",
			InkPalette.get_default().color(closing_role if _left <= closing_seconds else clock_role))
	clock.reset_size()
	var cap_top := button.position + button.cap_middle() - Vector2(0.0, button.cap_radius)
	clock.position = cap_top - Vector2(clock.size.x * 0.5, clock.size.y + clock_gap)
