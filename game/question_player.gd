class_name QuestionPlayer
extends Node
## Plays one question through the core loop: the imp poses it, the player answers with the stage's
## control or the choice row, the ink consequence plays, the imp reacts over the world, a click lets
## the choice land, the crowd reveal shows how others chose, and the choice quietly nudges the profile.
## When the pick was the least popular, the imp can say so first, from the question's least popular
## lines. On an offer ladder the offer comes round again after each acceptance, until the player stops. A
## tableau, a question with nothing to choose, is its stage, what the imp says over it, and a click.

## Emitted as the question moves through the loop.
signal phase_changed(phase: Phase)
## Emitted each time the player is asked to choose, whether in the choice row or on the stage alone.
signal choosing_started
## Emitted when the stage cues the imp's face, such as his surprise when a button comes alive.
signal imp_face_cued(face: StringName)

enum Phase { IDLE, ASKING, CHOOSING, CONSEQUENCE, REACTING, REVEALING, DONE }
## How the imp's line after each round of an offer ladder plays before the offer comes back.
## HOLD keeps it up while the player chooses again, AUTO lets it play out and clear on its own, and
## CLICK waits for a click.
enum RoundLines { HOLD, AUTO, CLICK }

## Path pattern of a stage scene, filled with the stage type twice.
const STAGE_SCENE := "res://stages/%s/%s_stage.tscn"
## The question's set of lines the imp says before the reveal when the player's pick was the least
## popular, such as "Not the popular call. Watch."
const LEAST_POPULAR := &"least_popular"

## Where stages are added.
@export var stage_root: Node2D
@export var dialogue: DialogueBox
@export var choices: ChoiceRow
@export var reveal: CrowdReveal
## The imp, handed to every stage for those that do something to him.
@export var imp: Imp

@export_group("Pacing")
## Seconds between the pick and the consequence starting.
@export_range(0.0, 5.0, 0.01) var before_consequence := 0.35
## Seconds between the consequence ending and the imp reacting.
@export_range(0.0, 5.0, 0.01) var before_reaction := 0.4
## Seconds between the reaction clearing and the crowd reveal appearing.
@export_range(0.0, 5.0, 0.01) var before_reveal := 0.25
## How the imp's line after each round of an offer ladder plays before the offer comes back.
@export var round_lines := RoundLines.HOLD

## Where the question is in the loop.
var phase := Phase.IDLE:
	set(value):
		phase = value
		phase_changed.emit(value)
## The question being played, or null.
var question: QuestionData
## The stage on screen, or null.
var stage: Stage

## What the run remembers, for the question being played: which options it offers and which lines hold.
var _run: RunState


## Plays [param to_play] from start to finish, handing its stage [param run], what the run remembers.
## Each pick's profile nudges are added to the run's profile. Returns the secret ending the player's
## choice fired, or an empty name.
func play(to_play: QuestionData, run: RunState) -> StringName:
	question = to_play
	_run = run
	stage = _make_stage(to_play, run)
	if stage == null:
		return &""
	phase = Phase.ASKING
	await stage.enter()
	var ask := stage.fill(to_play.ask_for(stage.ask_key()))
	if to_play.is_tableau():
		await _play_tableau(ask)
		return &""
	if not stage.offers_choice():
		await _say(ask)
		await dialogue.close()
		await _finish()
		return &""
	await _say(ask, true)

	var pick := 0
	while true:
		phase = Phase.CHOOSING
		pick = await _choose(to_play)
		var option := to_play.options[pick]

		phase = Phase.CONSEQUENCE
		dialogue.close()
		await _pause(before_consequence)
		var result := await stage.play_consequence(pick)
		for fact in option.remember:
			run.remember(StringName(fact))
		await _pause(before_reaction)

		phase = Phase.REACTING
		var reaction := stage.fill(option.reaction_for(result))
		var ending := option.ending_for(result)
		if ending != &"":
			# A secret ending: the reaction is the imp's last line, and the run player takes it from here.
			await _say(reaction)
			await dialogue.close()
			phase = Phase.DONE
			return ending
		run.profile.apply(option.profile_for(result))
		if stage.another_round():
			await _say_between_rounds(reaction)
			continue
		if not reaction.is_empty():
			await _say(reaction)
		await dialogue.close()
		break

	await stage.leave()
	var split := stage.reveal_split(pick)
	await _pause(before_reveal)
	var least_popular := LineData.for_run(stage.fill(to_play.lines_in(LEAST_POPULAR)), run)
	if not least_popular.is_empty() and split.is_least_popular():
		await _say(least_popular)
		await dialogue.close()
	phase = Phase.REVEALING
	await reveal.present(split)
	await _finish(false)
	return &""


## Dissolves the stage still on screen, if any, and frees it.
func clear_stage() -> void:
	if stage == null:
		return
	var leaving := stage
	stage = null
	question = null
	await leaving.leave()
	leaving.queue_free()


## A tableau: the imp says its ask over the stage, if it has one, the stage plays out and says how it
## came out, and the imp says the question's lines for that, the click on the last page the gate.
func _play_tableau(ask: Array[LineData]) -> void:
	if not ask.is_empty():
		await _say(ask)
		await dialogue.close()
	phase = Phase.CONSEQUENCE
	var result := await stage.play_consequence(-1)
	await _pause(before_reaction)
	phase = Phase.REACTING
	var lines := stage.fill(question.lines_in(result))
	if not lines.is_empty():
		await _say(lines)
	await dialogue.close()
	await _finish()


## Lets go of the question: the stage dissolves away first when [param leaving].
func _finish(leaving := true) -> void:
	if leaving:
		await stage.leave()
	stage.queue_free()
	stage = null
	question = null
	phase = Phase.DONE


## Waits for the player's pick: in the choice row, with the stage's controls lit and picking in step,
## or on the stage alone when it takes the choice by itself. The row leaves out hidden options, which
## only the stage can pick; picking one there ends the row's offer.
func _choose(to_play: QuestionData) -> int:
	choosing_started.emit()
	if stage.chooses_alone():
		stage.set_choosing(true)
		var chosen := await stage.choose()
		stage.set_choosing(false)
		return chosen
	var shown := to_play.shown_options(_run)
	var labels := PackedStringArray()
	var all_labels := stage.option_labels()
	for i in shown:
		labels.append(all_labels[i])
	var picked_on_stage := [-1]
	var stage_hovered := func(index: int) -> void: choices.highlight(shown.find(index) if index >= 0 else -1)
	var stage_committed := func(index: int) -> void:
		if shown.has(index):
			choices.commit(shown.find(index))
		else:
			picked_on_stage[0] = index
			choices.dismiss()
	var row_hovered := func(row_index: int) -> void: stage.highlight_option(shown[row_index] if row_index >= 0 else -1)
	stage.option_hovered.connect(stage_hovered)
	stage.option_committed.connect(stage_committed)
	choices.hovered.connect(row_hovered)
	stage.set_choosing(true)
	var row_pick := await choices.offer(labels, dialogue.frame_rect())
	stage.set_choosing(false)
	choices.hovered.disconnect(row_hovered)
	stage.option_hovered.disconnect(stage_hovered)
	stage.option_committed.disconnect(stage_committed)
	return shown[row_pick] if row_pick >= 0 else picked_on_stage[0]


## Says those of [param lines] that hold on the run, in turn, in the dialogue box, except a line someone
## on the stage says themselves, which floats over them while the box is away. With [param hold_last],
## the last page stays up and this returns as soon as it has inked on.
func _say(lines: Array[LineData], hold_last := false) -> void:
	var in_box: Array[LineData] = []
	for line in LineData.for_run(lines, _run):
		if stage == null or not stage.speaks(line):
			in_box.append(line)
			continue
		if not in_box.is_empty():
			await dialogue.say(in_box)
			in_box = []
		await dialogue.close()
		await stage.say_line(line)
	if not in_box.is_empty():
		await dialogue.say(in_box, hold_last)


## The imp's line after a round of an offer ladder, played the way [member round_lines] says.
func _say_between_rounds(all_lines: Array[LineData]) -> void:
	var lines := LineData.for_run(all_lines, _run)
	if lines.is_empty():
		return
	match round_lines:
		RoundLines.HOLD:
			await dialogue.say(lines, true)
		RoundLines.AUTO:
			await dialogue.say(lines, false, true)
			await dialogue.close()
		RoundLines.CLICK:
			await dialogue.say(lines)
			await dialogue.close()


func _make_stage(for_question: QuestionData, run: RunState) -> Stage:
	var type := str(for_question.stage.get("type", ""))
	var path := STAGE_SCENE % [type, type]
	var packed := load(path) as PackedScene if ResourceLoader.exists(path) else null
	if packed == null:
		push_error("Question %s: no stage scene at %s" % [for_question.id, path])
		return null
	var made := packed.instantiate() as Stage
	made.dialogue = dialogue
	made.run = run
	made.imp = imp
	made.imp_face_cued.connect(imp_face_cued.emit)
	stage_root.add_child(made)
	made.setup(for_question)
	return made


func _pause(seconds: float) -> void:
	if seconds > 0.0:
		await get_tree().create_timer(seconds, false).timeout
