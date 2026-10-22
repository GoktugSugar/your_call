class_name RunPlayer
extends Node
## Plays the run: a chapter's beats in order, cinematics, the imp's narration and questions, until
## the chapter ends or a choice fires a secret ending. An ending is an ending, never a loss: the imp's
## reaction is his last line, he fades, the stage goes, and the credits roll.

## Emitted as each beat starts.
signal beat_started(beat: BeatData)

## Path pattern of a cinematic scene, filled with its name twice.
const CINEMATIC_SCENE := "res://cinematics/%s/%s_cinematic.tscn"
## The credits roll that follows any ending.
const CREDITS_SCENE := "res://ui/credits/credits.tscn"

@export var question_player: QuestionPlayer
@export var dialogue: DialogueBox
@export var imp: Imp
## Where cinematics and the credits are added.
@export var overlay_root: Node

@export_group("Pacing")
## Seconds between one beat ending and the next starting.
@export_range(0.0, 5.0, 0.01) var between_beats := 0.35
## Seconds between the imp's last line of an ending and his fading away.
@export_range(0.0, 5.0, 0.01) var before_ending := 0.6

## The wing the imp keeps when no stage asks for another.
@export var imp_wing := Imp.Wing.RIGHT


## Plays [param chapter] from the beat [param from] (or the start), feeding choices into [param profile].
## Returns the secret ending a choice fired, or an empty name when the chapter ran to its end.
func play_chapter(chapter: ChapterData, profile: Profile, from := &"") -> StringName:
	var started := from == &""
	for beat in chapter.beats:
		if not started:
			if beat.id != from:
				continue
			started = true
		beat_started.emit(beat)
		if beat is CinematicData:
			var scene := (beat as CinematicData).scene
			var cinematic: Variant = _add_overlay(CINEMATIC_SCENE % [scene, scene])
			if cinematic != null:
				await cinematic.play()
				cinematic.queue_free()
		elif beat is NarrationData:
			await _imp_ready()
			await dialogue.say((beat as NarrationData).lines)
			await dialogue.close()
		elif beat is QuestionData:
			await _imp_ready()
			var picked := await question_player.play(beat as QuestionData, profile)
			if picked != null and picked.ending != &"":
				await _end(picked.ending)
				return picked.ending
		await get_tree().create_timer(between_beats, false).timeout
	return &""


## The imp fades, the stage dissolves, and the credits roll.
func _end(_ending: StringName) -> void:
	await get_tree().create_timer(before_ending, false).timeout
	question_player.clear_stage()
	await imp.vanish()
	var credits: Variant = _add_overlay(CREDITS_SCENE)
	if credits != null:
		await credits.roll()
		credits.queue_free()


func _imp_ready() -> void:
	if not imp.visible:
		await imp.appear(imp_wing)


## Adds the scene at [param path] over everything, or returns null with a warning when it does not
## exist yet, so the run never stalls on it.
func _add_overlay(path: String) -> Node:
	if not ResourceLoader.exists(path):
		push_warning("Run: %s does not exist yet, skipping it." % path)
		return null
	var overlay := (load(path) as PackedScene).instantiate()
	overlay_root.add_child(overlay)
	return overlay
