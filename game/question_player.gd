class_name QuestionPlayer
extends Node
## Plays one question through the core loop: the imp poses it, the player answers with the stage's
## control or the choice row, the ink consequence plays, the imp reacts over the world, a click lets
## the choice land, the crowd reveal shows how others chose, and the choice quietly nudges the profile.

## Emitted as the question moves through the loop.
signal phase_changed(phase: Phase)

enum Phase { IDLE, ASKING, CHOOSING, CONSEQUENCE, REACTING, REVEALING, DONE }

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

## Where the question is in the loop.
var phase := Phase.IDLE:
	set(value):
		phase = value
		phase_changed.emit(value)
## The question being played, or null.
var question: QuestionData
## The stage on screen, or null.
var stage: Stage


## Plays [param to_play] from start to finish and returns the option the player picked.
## The pick's profile nudges are added to [param profile].
func play(to_play: QuestionData, profile: Profile) -> OptionData:
	question = to_play
	stage = _make_stage(to_play)
	if stage == null:
		return null
	phase = Phase.ASKING
	await stage.enter()
	await dialogue.say(to_play.ask, true)

	phase = Phase.CHOOSING
	stage.option_hovered.connect(choices.highlight)
	stage.option_committed.connect(choices.commit)
	choices.hovered.connect(stage.highlight_option)
	stage.set_choosing(true)
	var pick := await choices.offer(to_play.option_labels(), dialogue.frame_rect())
	stage.set_choosing(false)
	choices.hovered.disconnect(stage.highlight_option)
	var option := to_play.options[pick]

	phase = Phase.CONSEQUENCE
	dialogue.close()
	await _pause(before_consequence)
	await stage.play_consequence(pick)
	await _pause(before_reaction)

	phase = Phase.REACTING
	await dialogue.say(option.reaction)
	await dialogue.close()
	profile.apply(option.profile)

	await stage.leave()
	await _pause(before_reveal)
	phase = Phase.REVEALING
	var shares := PackedFloat32Array()
	for each in to_play.options:
		shares.append(each.crowd)
	await reveal.present(to_play.reveal_heading, to_play.option_labels(), shares, pick)

	stage.queue_free()
	stage = null
	question = null
	phase = Phase.DONE
	return option


func _make_stage(for_question: QuestionData) -> Stage:
	var type := str(for_question.stage.get("type", ""))
	var path := STAGE_SCENE % [type, type]
	var packed := load(path) as PackedScene if ResourceLoader.exists(path) else null
	if packed == null:
		push_error("Question %s: no stage scene at %s" % [for_question.id, path])
		return null
	var made := packed.instantiate() as Stage
	stage_root.add_child(made)
	made.setup(for_question)
	return made


func _pause(seconds: float) -> void:
	if seconds > 0.0:
		await get_tree().create_timer(seconds, false).timeout
