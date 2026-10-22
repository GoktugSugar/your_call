class_name LineData
extends RefCounted
## One line of narration: who says it and what they say. The text may carry colour tags, and
## placeholders such as [code]{amount}[/code] that the stage fills in when the line is shown.

## A stable id for the line, built from where it sits: [code]<question>.<part>.<number>[/code].
var id := ""
## Who says it. The imp says almost everything.
var speaker := &"imp"
## What they say, with colour tags such as [code][amber]five[/amber][/code].
var text := ""
## The imp's expression while he says it, or empty for his usual grin.
var face := &""
## A stage direction for the voice, such as [code][furious][/code], said before the line but not
## spoken or shown. Empty uses the speaker's own direction, if any.
var direction := ""
## Whether the line is spoken aloud. One that is not inks on in silence, and the voice tools skip it.
var voiced := true


static func make(line_id: String, line_text: String, line_speaker := &"imp", line_face := &"") -> LineData:
	var line := LineData.new()
	line.id = line_id
	line.text = line_text
	line.speaker = line_speaker
	line.face = line_face
	return line


## The names of the placeholders in the text, such as [code]amount[/code].
func placeholders() -> PackedStringArray:
	return Markup.placeholders(text)


## A copy with its placeholders filled from [param fills], ready to show. [param keys] gives each
## placeholder's value a short name, such as an amount in digits or a country's code; the names of the
## values this line uses end the copy's id, so every filling can have a voice clip of its own. A line
## without placeholders comes back as it is.
func filled(fills: Dictionary, keys := {}) -> LineData:
	var names := placeholders()
	if names.is_empty():
		return self
	var variant := PackedStringArray()
	for name in names:
		var key := _key_of(str(keys.get(name, fills.get(name, ""))))
		if not key in variant:
			variant.append(key)
	var copy := LineData.make("%s.%s" % [id, "_".join(variant)], text.format(fills), speaker, face)
	copy.direction = direction
	copy.voiced = voiced
	return copy


## [param lines] with their placeholders filled from [param fills] and [param keys].
static func fill_all(lines: Array[LineData], fills: Dictionary, keys := {}) -> Array[LineData]:
	var out: Array[LineData] = []
	for line in lines:
		out.append(line.filled(fills, keys))
	return out


## A value's key as it goes into an id: letters and digits only.
static func _key_of(value: String) -> String:
	var key := ""
	for character in value:
		if character.is_valid_identifier() or character.is_valid_int():
			key += character
	return key
