class_name QuestionPlayer
extends Node
## Plays one question through the core loop: the imp poses it, the player answers with the stage's
## control or the choice row, the ink consequence plays, the imp reacts over the world, a click lets
## the choice land, the crowd reveal shows how others chose, and the choice quietly nudges the profile.
## On an offer ladder the offer comes round again after each acceptance, until the player stops.

## Emitted as the question moves through the loop.
signal phase_changed(phase: Phase)
## Emitted each time the player is asked to choose, whether in the choice row or on the stage alone.
signal choosing_started

enum Phase { IDLE, ASKING, CHOOSING, CONSEQUENCE, REACTING, REVEALING, DONE }
## How the imp's line after each round of an offer ladder plays before the offer comes back.
## HOLD keeps it up while the player chooses again, AUTO lets it play out and clear on its own, and
## CLICK waits for a click.
enum RoundLines { HOLD, AUTO, CLICK }

## Path pattern of a stage scene, filled with the stage type twice.
const STAGE_SCENE := "res://stages/%s/%s_stage.tscn"

## Where stages are added.
@export var stage_root: Node2D
@export var dialogue: DialogueBox
@export var choices: ChoiceRow
@export var reveal: CrowdReveal

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


## Plays [param to_play] from start to finish. Each pick's profile nudges are added to [param profile].
## Returns the secret ending the player's choice fired, or an empty name.
func play(to_play: QuestionData, profile: Profile) -> StringName:
	question = to_play
	stage = _make_stage(to_play)
	if stage == null:
		return &""
	phase = Phase.ASKING
	await stage.enter()
	await dialogue.say(stage.fill(to_play.ask), true)

	var pick := 0
	while true:
		phase = Phase.CHOOSING
		pick = await _choose(to_play)
		var option := to_play.options[pick]

		phase = Phase.CONSEQUENCE
		dialogue.close()
		await _pause(before_consequence)
		var result := await stage.play_consequence(pick)
		await _pause(before_reaction)

		phase = Phase.REACTING
		var reaction := stage.fill(option.reaction_for(result))
		var ending := option.ending_for(result)
		if ending != &"":
			# A secret ending: the reaction is the imp's last line, and the run player takes it from here.
			await dialogue.say(reaction)
			await dialogue.close()
			phase = Phase.DONE
			return ending
		profile.apply(option.profile)
		if stage.another_round():
			await _say_between_rounds(reaction)
			continue
		if not reaction.is_empty():
			await dialogue.say(reaction)
		await dialogue.close()
		break

	await stage.leave()
	await _pause(before_reveal)
	phase = Phase.REVEALING
	await reveal.present(stage.reveal_split(pick))

	stage.queue_free()
	stage = null
	question = null
	phase = Phase.DONE
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


## Waits for the player's pick: in the choice row, with the stage's controls lit and picking in step,
## or on the stage alone when it takes the choice by itself.
func _choose(to_play: QuestionData) -> int:
	choosing_started.emit()
	if stage.chooses_alone():
		stage.set_choosing(true)
		var chosen := await stage.choose()
		stage.set_choosing(false)
		return chosen
	stage.option_hovered.connect(choices.highlight)
	stage.option_committed.connect(choices.commit)
	choices.hovered.connect(stage.highlight_option)
	stage.set_choosing(true)
	var pick := await choices.offer(to_play.option_labels(), dialogue.frame_rect())
	stage.set_choosing(false)
	choices.hovered.disconnect(stage.highlight_option)
	stage.option_hovered.disconnect(choices.highlight)
	stage.option_committed.disconnect(choices.commit)
	return pick


## The imp's line after a round of an offer ladder, played the way [member round_lines] says.
func _say_between_rounds(lines: Array[LineData]) -> void:
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


func _make_stage(for_question: QuestionData) -> Stage:
	var type := str(for_question.stage.get("type", ""))
	var path := STAGE_SCENE % [type, type]
	var packed := load(path) as PackedScene if ResourceLoader.exists(path) else null
	if packed == null:
		push_error("Question %s: no stage scene at %s" % [for_question.id, path])
		return null
	var made := packed.instantiate() as Stage
	made.dialogue = dialogue
	stage_root.add_child(made)
	made.setup(for_question)
	return made


func _pause(seconds: float) -> void:
	if seconds > 0.0:
		await get_tree().create_timer(seconds, false).timeout
