class_name DiceStage
extends Stage
## A roll of the die: the campaign's two moments of pure chance. A hand drawn die inks in with a caption
## under it saying what it takes, and the click that moves on from the imp's "Go on. Roll." rolls it: it
## hops and tumbles, its faces flicking past slower and slower, lands on one with an amber flash, and
## reports whether the roll made the target or missed it.
## As a tableau, the die inks in on the ask's line [code]cue[/code] (counting from 1), and the click on
## the ask's last page rolls it; the question's [code]made[/code] or [code]missed[/code] lines follow. As
## a question, only an option whose outcome has [code]"roll": true[/code] rolls: the stage says the
## question's [code]fetch[/code] lines, inks the die in, says its [code]prompt[/code] lines, and the
## click on their last page rolls it; the option's reaction is keyed [code]made[/code] or
## [code]missed[/code]. Any other option leaves the die out of it.
## Stage data: [code]{"type": "dice", "sides": 6, "target": 3, "cue": 6, "caption": "roll a {target} or higher"}[/code].

## The placeholders the stage fills: the number the roll has to reach.
const FILLS: PackedStringArray = ["target"]
## The roll reached the target.
const MADE := &"made"
## It did not.
const MISSED := &"missed"

## The die.
@export var die: Die
## The caption under the die.
@export var caption: RichTextLabel
## Seed for the rolls. Zero rolls differently every time.
@export var roll_seed := 0

@export_group("Showing")
## Seconds the die takes to ink in.
@export_range(0.05, 3.0, 0.01) var die_draw := 0.6
## Seconds the caption takes to fade in.
@export_range(0.0, 3.0, 0.01) var caption_fade := 0.4
## Palette role of the caption's words.
@export var caption_role := &"muted"
## Palette role of the number the roll has to reach, in the caption.
@export var target_role := &"amber"

@export_group("Rolling")
## Seconds the roll takes, from the click to the die coming to rest.
@export_range(0.2, 5.0, 0.05) var roll_time := 1.5
## How many times the face it shows flicks over while it tumbles.
@export_range(1, 40) var face_flicks := 12
## Whole turns the die spins as it tumbles. Whole, so it lands square.
@export_range(0, 8) var tumble_turns := 2
## How high it hops as it tumbles.
@export_range(0.0, 300.0, 1.0) var hop_height := 70.0
## Seconds its amber flash lasts once it lands.
@export_range(0.0, 3.0, 0.05) var flash_time := 0.6
## Palette role of the flash.
@export var flash_role := &"amber"
## Seconds the die rests on its face before the stage moves on.
@export_range(0.0, 5.0, 0.05) var rest_time := 0.7

## The question's lines the stage says before a roll an option asks for: the imp fetching the die.
const _FETCH_LINES := &"fetch"
## The question's lines it says once the die is out; the click on their last page rolls it.
const _PROMPT_LINES := &"prompt"

var _rng := RandomNumberGenerator.new()
var _shown := false
var _cue_line := ""
## The face the die last landed on, or 0 before it is rolled.
var _rolled := 0


func setup(for_question: QuestionData) -> void:
	super.setup(for_question)
	if roll_seed != 0:
		_rng.seed = roll_seed
	else:
		_rng.randomize()
	die.visible = false
	caption.visible = false
	caption.text = _caption_markup(str(for_question.stage.get("caption", "")), int(for_question.stage.get("target", 1)))
	var cue := int(for_question.stage.get("cue", 0)) - 1
	if cue >= 0 and cue < for_question.ask.size():
		_cue_line = for_question.ask[cue].id
	if dialogue != null:
		dialogue.page_shown.connect(_on_page_shown)


func play_consequence(index: int) -> StringName:
	var rolls := question.is_tableau()
	if not rolls and index >= 0 and index < question.options.size():
		rolls = bool(question.options[index].outcome.get("roll", false))
	if not rolls:
		return &""
	if not question.is_tableau():
		await _say_set(_FETCH_LINES)
		await _show_die()
		await _say_set(_PROMPT_LINES)
	else:
		await _show_die()
	var face := await _roll()
	await get_tree().create_timer(rest_time, false).timeout
	return MADE if face >= int(question.stage.get("target", 1)) else MISSED


func fills() -> Dictionary:
	return {"target": str(question.stage.get("target", 1))}


## The face the die last landed on, or 0 before it has been rolled.
func rolled() -> int:
	return _rolled


func leave() -> void:
	if caption.visible:
		create_tween().tween_property(caption, ^"modulate:a", 0.0, leave_duration)
	await super.leave()


func _exit_tree() -> void:
	if dialogue != null and dialogue.page_shown.is_connected(_on_page_shown):
		dialogue.page_shown.disconnect(_on_page_shown)


## [param text] as the caption's markup: its words muted, and the target the roll has to reach, where
## [code]{target}[/code] stands, in amber.
func _caption_markup(text: String, target: int) -> String:
	var palette := InkPalette.get_default()
	var words := palette.color(caption_role).to_html(false)
	var number := palette.color(target_role).to_html(false)
	var parts := text.split("{target}")
	var markup := PackedStringArray()
	for i in parts.size():
		if i > 0:
			markup.append("[color=#%s]%d[/color]" % [number, target])
		markup.append("[color=#%s]%s[/color]" % [words, parts[i]])
	return "[center]%s[/center]" % "".join(markup)


## The die inks in with its caption under it, once.
func _show_die() -> void:
	if _shown:
		return
	_shown = true
	die.visible = true
	caption.visible = true
	caption.modulate.a = 0.0
	create_tween().tween_property(caption, ^"modulate:a", 1.0, caption_fade)
	await die.draw_on(die_draw).finished


func _on_page_shown(line: LineData, page: int, _page_count: int) -> void:
	if line.id == _cue_line and page == 0:
		_show_die()


## Says the question's [param set_name] lines that hold on the run, each page waiting for a click.
func _say_set(set_name: StringName) -> void:
	var lines := LineData.for_run(fill(question.lines_in(set_name)), run)
	if dialogue == null or lines.is_empty():
		return
	await dialogue.say(lines)
	await dialogue.close()


## The die hops and tumbles, its faces flicking past slower and slower, and lands with an amber flash on
## the face it rolled, which it returns.
func _roll() -> int:
	var sides := int(question.stage.get("sides", 6))
	var face := _rng.randi_range(1, sides)
	var rest := die.position
	var tumble := create_tween().set_parallel(true)
	tumble.tween_property(die, ^"rotation", die.rotation + TAU * tumble_turns, roll_time) \
			.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	var hop := create_tween()
	hop.tween_property(die, ^"position:y", rest.y - hop_height, roll_time * 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	hop.tween_property(die, ^"position:y", rest.y, roll_time * 0.45).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	# The faces flick past slower and slower: each wait is longer than the last, and they add up to the roll.
	var weights := 0.0
	for i in face_flicks:
		weights += 1.0 + i
	for i in face_flicks:
		await get_tree().create_timer(roll_time * (1.0 + i) / weights, false).timeout
		die.face = face if i == face_flicks - 1 else _other_face(die.face, sides)
	if tumble.is_running():
		await tumble.finished
	die.rotation = 0.0
	die.position = rest
	_rolled = face
	die.color_override = flash_role
	await get_tree().create_timer(flash_time, false).timeout
	die.color_override = &""
	return face


## A face other than [param current], at random.
func _other_face(current: int, sides: int) -> int:
	var next := _rng.randi_range(1, maxi(sides - 1, 1))
	return next + 1 if next >= current else next
