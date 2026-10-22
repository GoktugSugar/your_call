class_name RevealShot
extends TrailerShot
## How others chose: a question's crowd reveal on its own, the bars inking in as the game shows them
## once a question is over, while the imp says some of the trailer's lines under it.
## Settings: [code]question[/code], the chapter and the question, such as [code]ch1.lever[/code];
## [code]pick[/code], the index of the option the player picked; [code]zoom[/code], how far the reveal
## is brought in round its middle; [code]say[/code] and [code]wait[/code], as for narration.


func play(trailer: Trailer, settings: Dictionary) -> void:
	var question := trailer.question_named(str(settings.get("question", "")))
	if question == null:
		push_error("Trailer: no question '%s' in the run" % settings.get("question", ""))
		return
	var split := _split(trailer, question, int(settings.get("pick", 0)))
	if split == null:
		return
	var reveal := trailer.reveal
	reveal.pivot_offset = reveal.center
	reveal.scale = Vector2.ONE * float(settings.get("zoom", 1.0))
	# Not awaited: the reveal waits for a click to go, and none comes while the shot records.
	reveal.present(split)
	await trailer.wait(float(settings.get("wait", 0.0)))
	var lines := trailer.lines_named(settings.get("say", []))
	if lines.is_empty():
		return
	await trailer.dialogue.say(lines, false, true)
	await trailer.dialogue.close()


## The split the question's own stage would reveal with [param pick] picked: its stage is set up unseen
## just long enough to ask, since some stages make their own, in their own colours.
static func _split(trailer: Trailer, question: QuestionData, pick: int) -> RevealSplit:
	var type := str(question.stage.get("type", ""))
	var path := QuestionPlayer.STAGE_SCENE % [type, type]
	if not ResourceLoader.exists(path):
		push_error("Trailer: no stage at %s" % path)
		return null
	var stage := (load(path) as PackedScene).instantiate() as Stage
	stage.visible = false
	stage.run = trailer.run
	trailer.question_player.stage_root.add_child(stage)
	stage.setup(question)
	var split := stage.reveal_split(pick)
	stage.queue_free()
	return split
