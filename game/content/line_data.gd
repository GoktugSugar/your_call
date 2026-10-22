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


## A copy with its placeholders filled from [param fills], ready to show. [param variant] names this
## filling, such as the amount or the country, and ends the copy's id, so every filling can have a
## voice clip of its own. An empty variant keeps the id.
func filled(fills: Dictionary, variant := "") -> LineData:
	var copy := LineData.make(id if variant.is_empty() else "%s.%s" % [id, variant], text.format(fills), speaker, face)
	copy.direction = direction
	return copy


## [param lines] with their placeholders filled from [param fills], under [param variant]. Lines
## without placeholders come back as they are.
static func fill_all(lines: Array[LineData], fills: Dictionary, variant := "") -> Array[LineData]:
	var out: Array[LineData] = []
	for line in lines:
		out.append(line.filled(fills, variant) if not line.placeholders().is_empty() else line)
	return out
