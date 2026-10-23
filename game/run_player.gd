class_name RunPlayer
extends Node
## Plays the run: its chapters in order, and each chapter's beats in order, cinematics, the imp's
## narration and questions, until the run ends or a choice fires a secret ending. The page is the imp's
## to roam while he narrates, and he hops home to his wing before each question's stage. An ending is an
## ending, never a loss: the imp's reaction is his last line, he fades, the stage goes, and the credits
## roll. The imp takes his leave at the end of each chapter, and the next opens on the player waking.
## A chapter with a wallet, such as the money chapter, opens it as its first words are said and puts it
## away at its end.

## Emitted as each chapter starts.
signal chapter_started(chapter: ChapterData)
## Emitted as each beat starts.
signal beat_started(beat: BeatData)
## Emitted the moment a choice fires a secret ending, before the imp fades and the credits roll.
signal ending_reached(ending: StringName)

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


## Plays [param chapters] in order, from the chapter with the id [param from_chapter] and its beat
## [param from_beat] (or from the start), with [param run] remembering what happens. With
## [param fill_skipped], a run started part way first takes what each chapter it skips would have left
## behind; a continued run remembers all that already. Returns the secret ending a choice fired, or an
## empty name when the run went to its end.
func play_run(chapters: Array[ChapterData], run: RunState, from_chapter := &"", from_beat := &"",
		fill_skipped := true) -> StringName:
	var started := from_chapter == &""
	for chapter in chapters:
		if not started:
			if chapter.id != from_chapter:
				if fill_skipped:
					run.assume(chapter)
				continue
			started = true
		var ending := await play_chapter(chapter, run, from_beat)
		if ending != &"":
			return ending
		from_beat = &""
		if imp.visible:
			await imp.vanish()
	return &""


## Plays [param chapter] from the beat [param from] (or the start), with [param run] remembering what
## happens. Returns the secret ending a choice fired, or an empty name when the chapter ran to its end.
func play_chapter(chapter: ChapterData, run: RunState, from := &"") -> StringName:
	chapter_started.emit(chapter)
	var started := from == &""
	for beat in chapter.beats:
		if not started:
			if beat.id != from:
				continue
			started = true
		beat_started.emit(beat)
		if not beat is CinematicData and not chapter.wallet.is_empty() and run.wallet == null:
			run.open_wallet(int(chapter.wallet.get("start", 0)))
		if beat is CinematicData:
			await play_cinematic((beat as CinematicData).scene)
		elif beat is NarrationData:
			await _imp_ready()
			imp.free_to_roam = true
			await dialogue.say(LineData.for_run((beat as NarrationData).lines, run))
			await dialogue.close()
		elif beat is QuestionData:
			await _imp_ready()
			imp.free_to_roam = false
			await imp.go_home()
			var ending := await question_player.play(beat as QuestionData, run)
			if ending != &"":
				ending_reached.emit(ending)
				run.close_wallet()
				await _end(ending)
				return ending
		await get_tree().create_timer(between_beats, false).timeout
	run.close_wallet()
	return &""


## Plays the cinematic called [param scene] over everything, such as the [code]crash[/code]. Returns once
## it has finished, at once when it does not exist yet.
func play_cinematic(scene: StringName) -> void:
	var cinematic: Variant = _add_overlay(CINEMATIC_SCENE % [scene, scene])
	if cinematic != null:
		await cinematic.play()
		cinematic.queue_free()


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
