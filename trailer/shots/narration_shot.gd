class_name NarrationShot
extends TrailerShot
## The imp says some of the trailer's lines on the page, each page moving on by itself once it is said.
## Settings: [code]say[/code], the names of the trailer's lines in order; [code]wait[/code], seconds
## before he starts.


func play(trailer: Trailer, settings: Dictionary) -> void:
	await trailer.wait(float(settings.get("wait", 0.0)))
	await trailer.dialogue.say(trailer.lines_named(settings.get("say", [])), false, true)
	await trailer.dialogue.close()
