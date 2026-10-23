class_name QuestionShot
extends TrailerShot
## A question from the run, played through the game's own loop: its stage drawing on, the imp asking,
## the choice row, the consequence and the crowd reveal, with the trailer's pointer doing the choosing.
## The imp can say the trailer's lines in place of his own.
## Settings:
## [code]question[/code]: the chapter and the question, such as [code]ch1.lever[/code].
## [code]ask[/code]: the trailer's lines that pose it, in place of the game's.
## [code]reaction[/code]: the trailer's lines he reacts with, whatever is picked, or [code]none[/code]
## for no reaction; left out, he says the game's.
## [code]sets[/code]: the stage's own sets of lines to replace, by name, each with the trailer's lines or
## [code]none[/code], such as the lines he says while the nuke's pin goes round.
## [code]wallet[/code]: the money the run has to spend, for the shop.
## [code]tune[/code]: the stage's settings to change, such as the country the pin lands on.
## [code]play[/code]: the pointer's steps (see [method Trailer.act]).

## What a reaction or a set says when it should say nothing.
const NOTHING := "none"


func play(trailer: Trailer, settings: Dictionary) -> void:
	var question := trailer.question_named(str(settings.get("question", "")))
	if question == null:
		push_error("Trailer: no question '%s' in the run" % settings.get("question", ""))
		return
	_retell(question, trailer, settings)
	if settings.has("wallet"):
		trailer.run.open_wallet(int(settings["wallet"]))
	var tune: Dictionary = settings.get("tune", {})
	if not tune.is_empty():
		# A stage is set up just after it enters the tree, so this lands before it reads its settings.
		trailer.question_player.stage_root.child_entered_tree.connect(Trailer.tune.bind(tune), CONNECT_ONE_SHOT)
	# The loop runs on by itself; the pointer steps in when it is time to choose.
	trailer.question_player.play(question, trailer.run)
	await trailer.act(settings.get("play", []))


## Puts the trailer's lines in the imp's mouth where [param settings] says, and takes every secret
## ending out of [param question], which the trailer never shows.
static func _retell(question: QuestionData, trailer: Trailer, settings: Dictionary) -> void:
	if settings.has("ask"):
		question.ask = trailer.lines_named([settings["ask"]])
		question.asks.clear()
	if settings.has("reaction"):
		var reaction := _lines_or_nothing(trailer, str(settings["reaction"]))
		for option in question.options:
			option.reaction = reaction
			option.reactions.clear()
	var sets: Dictionary = settings.get("sets", {})
	for set_name: String in sets:
		question.line_sets[StringName(set_name)] = _lines_or_nothing(trailer, str(sets[set_name]))
	for option in question.options:
		option.ending = &""
		option.endings.clear()


static func _lines_or_nothing(trailer: Trailer, name: String) -> Array[LineData]:
	var none: Array[LineData] = []
	return none if name == NOTHING else trailer.lines_named([name])
