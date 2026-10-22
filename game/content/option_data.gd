class_name OptionData
extends RefCounted
## One answer to a question: its label, what the crowd did, how it nudges the profile,
## what it does on stage, and how the imp reacts to it.

## Stable id within its question, such as [code]pull[/code].
var id := &""
## The words in the choice row. Plain text, never colour tags.
var label := ""
## The seeded share of the crowd who chose it, shown on the reveal.
var crowd := 0.0
## Silent nudges to the profile, by axis id. Negative leans toward the axis's first pole.
var profile: Dictionary[StringName, float] = {}
## What the option does on its stage. Each stage reads its own keys.
var outcome := {}
## The imp's reaction, one line per dialogue box run, whatever the stage's outcome.
var reaction: Array[LineData] = []
## Reactions that depend on how the consequence came out, keyed by the outcome the stage reports,
## such as [code]lives[/code] or a ladder's amount. Each value is an [code]Array[LineData][/code].
var reactions := {}
## The secret ending this option fires, or empty for none.
var ending := &""
## Secret endings that fire only on some outcomes, keyed like [member reactions].
var endings: Dictionary[StringName, StringName] = {}


## The reaction to [param result], the outcome the stage reported: its own lines if it has any,
## otherwise the plain [member reaction]. Empty when the imp has nothing to say to it.
func reaction_for(result: StringName) -> Array[LineData]:
	if reactions.has(result):
		return reactions[result]
	return reaction


## The secret ending [param result] fires, or an empty name.
func ending_for(result: StringName) -> StringName:
	return endings.get(result, ending)


## Every reaction line, plain and keyed, in the order they sit in the content.
func all_reactions() -> Array[LineData]:
	var lines: Array[LineData] = reaction.duplicate()
	for result: StringName in reactions:
		lines.append_array(reactions[result])
	return lines
