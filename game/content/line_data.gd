class_name LineData
extends RefCounted
## One line of narration: who says it and what they say. The text may carry colour tags.

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
