class_name TitleShot
extends TrailerShot
## The title card: the game's name inks on with a line under it, while the imp has the last word.
## Settings: [code]title[/code] and [code]line[/code], the card's words; [code]wait[/code], seconds
## before the card starts; [code]say[/code], the trailer's lines the imp says, [code]say_after[/code]
## seconds after the card starts.


func play(trailer: Trailer, settings: Dictionary) -> void:
	await trailer.wait(float(settings.get("wait", 0.0)))
	trailer.title_card.write_on(str(settings.get("title", "")), str(settings.get("line", "")))
	var lines := trailer.lines_named(settings.get("say", []))
	if lines.is_empty():
		return
	await trailer.wait(float(settings.get("say_after", 0.0)))
	await trailer.dialogue.say(lines, false, true)
	await trailer.dialogue.close()
