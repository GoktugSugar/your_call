class_name Markup
extends RefCounted
## The colour tags narration carries, such as [code][amber]five[/amber][/code], and the mechanical
## text rules every player-facing line follows. What each tag means is in PREMISE.md section 9.

## The tag vocabulary. Each tag is also the name of its palette colour.
const TAGS: PackedStringArray = ["red", "amber", "pink", "gold", "blue"]
## Every dash and hyphen. Player-facing text never contains any of them.
const DASHES := "-\u2010\u2011\u2012\u2013\u2014\u2015\u2212"

static var _tag_regex: RegEx


## The text with its tags taken out, as it is read aloud.
static func strip(text: String) -> String:
	return _tags().sub(text, "", true)


## Whether the text carries any tags.
static func has_tags(text: String) -> bool:
	return _tags().search(text) != null


## The text as BBCode for a RichTextLabel: known tags become their palette colours, anything else is shown literally.
static func to_bbcode(text: String, palette: InkPalette) -> String:
	var out := ""
	var at := 0
	for found in _tags().search_all(text):
		out += _escape(text.substr(at, found.get_start() - at))
		var name := found.get_string(2)
		if name in TAGS:
			out += "[/color]" if found.get_string(1) == "/" else "[color=#%s]" % palette.color(name).to_html(false)
		else:
			out += _escape(found.get_string())
		at = found.get_end()
	return out + _escape(text.substr(at))


## What is wrong with the tags in the text: unknown, nested, unclosed or stray. Empty when nothing is.
static func tag_problems(text: String) -> PackedStringArray:
	var problems := PackedStringArray()
	var open := ""
	for found in _tags().search_all(text):
		var name := found.get_string(2)
		var closing := found.get_string(1) == "/"
		if not name in TAGS:
			problems.append("unknown tag [%s%s]" % ["/" if closing else "", name])
		elif closing and open != name:
			problems.append("[/%s] closes nothing" % name if open.is_empty() else "[/%s] closes [%s]" % [name, open])
		elif closing:
			open = ""
		elif not open.is_empty():
			problems.append("[%s] opens inside [%s]" % [name, open])
		else:
			open = name
	if not open.is_empty():
		problems.append("[%s] is never closed" % open)
	var bare := strip(text)
	if bare.contains("[") or bare.contains("]"):
		problems.append("stray square bracket")
	return problems


## Whether the text contains a dash or hyphen of any kind.
static func has_dash(text: String) -> bool:
	for dash in DASHES:
		if text.contains(dash):
			return true
	return false


static func _escape(literal: String) -> String:
	return literal.replace("[", "[lb]")


static func _tags() -> RegEx:
	if _tag_regex == null:
		_tag_regex = RegEx.create_from_string("\\[(/?)([a-zA-Z_]+)\\]")
	return _tag_regex
