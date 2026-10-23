class_name GuessStage
extends Stage
## A guess at the room, for Everyone Else: an empty ink bar from none of the room to all of it, and over
## it what the guess is about, a doodle, a soul, a lever or a pair of buttons. While the ask's last page
## stays up the player marks where they think the room was: an amber mark follows the pointer along the
## bar, or the left and right keys, and a click or Enter sets it. Then the true bar inks in to the
## room's share, its bare number past its end, and how far off the guess was shows under it.
## It is a tableau, its lines keyed by how the guess came out.
## Stage data:
## [codeblock]
## {"type": "guess", "truth": 51, "about": "strangers", "close": 10,
##  "show": [{"doodle": "wallet"}, {"kind": "bear"}, {"button": "blue"}, {"lever": true}],
##  "gap": {"text": "off by {gap}"}, "exact": {"text": "spot on"},
##  "asks": [{"if": "pulled_lever", "ask": "pulled"}, {"ask": "left"}]}
## [/codeblock]
## [code]truth[/code] is the room's share, from 0 to 100; a callback names the share it repeats with
## [code]of[/code] ([code]"of": "ch1.lever.pull"[/code]), which the tests hold it to. [code]about[/code]
## files the guess in the run under that name, for a later read of how the guesses ran.
## Outcomes: [code]close[/code] within [code]close[/code] of the truth either way, [code]low[/code] under
## it, [code]high[/code] over it. Placeholders, in its words only: [code]{gap}[/code].

## Emitted when the player sets the guess.
signal guessed(share: float)

## The placeholders this stage fills.
const FILLS: PackedStringArray = ["gap"]

## The bar the guess is marked on.
@export var scale_bar: GuessScale
## The true bar, as long as the room's share, inked in once the guess is set.
@export var truth_bar: CrowdBar
## The guess's number, over the mark.
@export var guess_label: Label
## How far off the guess was, under the bar.
@export var gap_label: Label
## A push button, for a guess about the buttons.
@export var button_scene: PackedScene

@export_group("Layout")
## Where the things the guess is about stand, their ground, and the gap between them.
@export var show_spot := Vector2(960.0, 450.0)
@export_range(0.0, 600.0, 1.0) var show_gap := 230.0
## How big doodles and souls stand over the bar.
@export_range(0.1, 3.0, 0.01) var show_scale := 0.9
## How big a lever or a button stands over the bar.
@export_range(0.1, 3.0, 0.01) var control_scale := 1.3
## The band round the bar, above and below, where a click sets the guess.
@export_range(0.0, 400.0, 1.0) var click_band := 140.0
## The gap between the mark's handle and its number.
@export_range(0.0, 100.0, 1.0) var number_gap := 8.0

@export_group("Feel")
## Where the mark starts, before the player moves it.
@export_range(0.0, 100.0, 1.0) var start_guess := 50.0
## How far one press of a key moves the mark.
@export_range(0.1, 20.0, 0.1) var key_step := 1.0
## How close a guess must come to count as close, when the data does not say.
@export_range(0.0, 50.0, 0.5) var default_close := 10.0

@export_group("Look")
## Palette role of the guess's number, and of how far off it was.
@export var guess_role := &"amber"
@export var gap_role := &"muted"

@export_group("Timing")
## Seconds the true bar takes to ink in.
@export_range(0.05, 5.0, 0.05) var reveal_time := 1.1
## Seconds the gap takes to fade in, once the bar is in.
@export_range(0.0, 3.0, 0.05) var gap_fade := 0.35
## Seconds the stage holds before the imp reacts.
@export_range(0.0, 3.0, 0.05) var after_hold := 0.5

var _marking := false
var _shown: Array[Node2D] = []


func setup(for_question: QuestionData) -> void:
	super.setup(for_question)
	truth_bar.value = _truth()
	truth_bar.fill = 0.0
	truth_bar.full_length = scale_bar.length
	var palette := InkPalette.get_default()
	guess_label.add_theme_color_override(&"font_color", palette.color(guess_role))
	gap_label.add_theme_color_override(&"font_color", palette.color(gap_role))
	guess_label.modulate.a = 0.0
	gap_label.modulate.a = 0.0
	_show_things()


func holds_ask() -> bool:
	return true


## The guess is taken on the stage, with no choice row.
func chooses_alone() -> bool:
	return true


## The bar's words fade in with the stage.
func enter() -> void:
	guess_label.modulate.a = 0.0
	await super.enter()


func play_consequence(_index: int) -> StringName:
	_set_guess(start_guess)
	guess_label.modulate.a = 1.0
	_marking = true
	var guess: float = await guessed
	_marking = false
	dialogue.close()
	var truth := _truth()
	var about := str(question.stage.get("about", ""))
	if about != "":
		run.record_guess(question, StringName(about), guess, truth)
	var fill := create_tween()
	fill.tween_property(truth_bar, ^"fill", 1.0, reveal_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await fill.finished
	gap_label.text = _gap_words(guess, truth)
	gap_label.size = gap_label.get_combined_minimum_size()
	gap_label.position.x = scale_bar.position.x + (scale_bar.length - gap_label.size.x) * 0.5
	create_tween().tween_property(gap_label, ^"modulate:a", 1.0, gap_fade)
	await get_tree().create_timer(after_hold, false).timeout
	var close := float(question.stage.get("close", default_close))
	if absf(guess - truth) <= close:
		return &"close"
	return &"low" if guess < truth else &"high"


func leave() -> void:
	for label: Label in [guess_label, gap_label]:
		create_tween().tween_property(label, ^"modulate:a", 0.0, leave_duration)
	await super.leave()


## For autoplay: a point on the bar, the option's number in tens of the room (option 5 is half).
func option_point(index: int) -> Vector2:
	return scale_bar.global_position + Vector2(scale_bar.x_of(clampf((index + 1) * 10.0, 0.0, 100.0)), 0.0)


func fills() -> Dictionary:
	return {"gap": "0"}


func _unhandled_input(event: InputEvent) -> void:
	if not _marking:
		return
	if event is InputEventMouseMotion:
		_set_guess(scale_bar.share_at(_on_bar(event).x))
	elif event.is_action_pressed(&"pick") and event is InputEventMouse:
		var local := _on_bar(event)
		if absf(local.y) <= click_band:
			get_viewport().set_input_as_handled()
			_set_guess(scale_bar.share_at(local.x))
			guessed.emit(scale_bar.guess)
	elif event.is_action_pressed(&"ui_left", true):
		get_viewport().set_input_as_handled()
		_set_guess(scale_bar.guess - key_step)
	elif event.is_action_pressed(&"ui_right", true):
		get_viewport().set_input_as_handled()
		_set_guess(scale_bar.guess + key_step)
	elif event.is_action_pressed(&"ui_accept"):
		get_viewport().set_input_as_handled()
		guessed.emit(scale_bar.guess)


## Where a pointer event is, in the bar's own space.
func _on_bar(event: InputEvent) -> Vector2:
	return (scale_bar.make_input_local(event) as InputEventMouse).position


func _set_guess(share: float) -> void:
	scale_bar.guess = clampf(roundf(share), 0.0, 100.0)
	guess_label.text = str(int(scale_bar.guess))
	guess_label.size = guess_label.get_combined_minimum_size()
	guess_label.position = scale_bar.position + Vector2(scale_bar.x_of(scale_bar.guess) - guess_label.size.x * 0.5,
			-scale_bar.bar_height * 0.5 - scale_bar.mark_reach - scale_bar.handle_radius - number_gap - guess_label.size.y)


func _truth() -> float:
	return clampf(float(question.stage.get("truth", 50.0)), 0.0, 100.0)


## How far off [param guess] was from [param truth], in the stage data's words.
func _gap_words(guess: float, truth: float) -> String:
	var gap := roundi(absf(guess - truth))
	var key := "exact" if gap == 0 else "gap"
	var words: Variant = question.stage.get(key, {})
	var text := str(words.get("text", "")) if words is Dictionary else ""
	return text.format({"gap": str(gap)})


## Lays out what the guess is about over the bar, left to right, centred on [member show_spot].
func _show_things() -> void:
	var things: Array = question.stage.get("show", [])
	for i in things.size():
		var thing: Variant = things[i]
		if not thing is Dictionary:
			continue
		var node := _make_thing(thing)
		if node == null:
			continue
		node.position = show_spot + Vector2((i - (things.size() - 1) * 0.5) * show_gap, 0.0)
		add_child(node)
		_shown.append(node)


func _make_thing(thing: Dictionary) -> Node2D:
	if thing.has("doodle"):
		var doodle := DoodlesStage.make_doodle(str(thing["doodle"]))
		if doodle != null:
			doodle.scale = Vector2.ONE * show_scale
		return doodle
	if thing.has("kind"):
		var kind := SoulKind.find(StringName(str(thing["kind"])))
		if kind == null:
			return null
		var soul := kind.make()
		soul.scale *= show_scale
		return soul
	if thing.has("button"):
		var button := button_scene.instantiate() as PushButton
		button.look = ButtonLook.find(StringName(str(thing["button"])))
		button.scale = Vector2.ONE * control_scale
		return button
	if thing.get("lever", false):
		var lever := Lever.new()
		lever.scale = Vector2.ONE * control_scale
		return lever
	return null
