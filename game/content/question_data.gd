class_name QuestionData
extends BeatData
## One question: the imp's lines that pose it, the stage it plays on, its options and its reveal.
## Its [member BeatData.id], such as [code]lever[/code], is what saves and the crowd tally key off.
## A question with no options is a tableau: a stage the imp talks over with nothing to choose, such as
## the money chapter's receipt.

## Its number in the script, such as [code]1.02[/code].
var number := ""
## Its title in the script, such as [code]The Lever[/code].
var title := ""
## The structure of the decision: binary, multiple choice, coordination gamble and so on.
var verb := &"binary"
## Light, medium or heavy. Paces the consequence.
var weight := &"medium"
## The stage it plays on and how that stage is set: [code]type[/code] names the stage, the rest is the stage's own.
var stage := {}
## The imp's lines that pose the question.
var ask: Array[LineData] = []
## Other ways to pose it, keyed by name, for a stage that picks how to ask from how the run has gone,
## such as when the player owns nothing to sell back. Each value is an [code]Array[LineData][/code].
var asks := {}
## Named sets of the imp's lines that the stage says at moments of its own, such as the needling over
## a countdown. Each value is an [code]Array[LineData][/code].
var line_sets := {}
## Lines the stage shows, such as a plea floating over a figure. Their stage data names them with [code]says[/code].
var stage_lines: Array[LineData] = []
## Words the stage shows that are not lines, such as a readout or a caption. They may hold placeholders.
var stage_texts := PackedStringArray()
## The answers, in the order the choice row and the reveal show them.
var options: Array[OptionData] = []
## The reveal's heading.
var reveal_heading := "how others chose"
## The words over the reveal's bars, when they differ from the option labels.
var reveal_labels := PackedStringArray()
## The name of the line a coordination gamble's crowd had to cross, such as [code]half[/code]. Empty for none.
var reveal_mark := ""
## The ending a tableau fires, or empty for none, as the run's main endings do.
var ending := &""
## Endings a tableau fires only on some outcomes, keyed by the outcome its stage reports.
var endings: Dictionary[StringName, StringName] = {}


## Whether it is a tableau, with nothing to choose.
## The ending a tableau fires when its stage reports [param result], or an empty name.
func ending_for(result: StringName) -> StringName:
	return endings.get(result, ending)


func is_tableau() -> bool:
	return options.is_empty()


## The ask called [param key]: its own lines if it has them, otherwise the plain [member ask].
func ask_for(key: StringName) -> Array[LineData]:
	if asks.has(key):
		return asks[key]
	return ask


## The indices of the options the choice row shows on [param run], in order: all but the hidden ones,
## and those the run does not offer, such as another class's option. With no run, all but the hidden.
func shown_options(run: RunState = null) -> PackedInt32Array:
	var shown := PackedInt32Array()
	for i in options.size():
		if options[i].offered_on(run):
			shown.append(i)
	return shown


## Whether some of its options are offered only on some runs.
func has_conditional_options() -> bool:
	for option in options:
		if not option.requires.is_empty() or not option.excludes.is_empty():
			return true
	return false


## The option labels, in order.
func option_labels() -> PackedStringArray:
	var labels := PackedStringArray()
	for option in options:
		labels.append(option.label)
	return labels


## The words over the reveal's bars: its own labels if it has them, otherwise the option labels.
func bar_labels() -> PackedStringArray:
	return reveal_labels if not reveal_labels.is_empty() else option_labels()


## The option with [param option_id], or null.
func find_option(option_id: StringName) -> OptionData:
	for option in options:
		if option.id == option_id:
			return option
	return null


## The set of lines called [param set_name], or an empty list.
func lines_in(set_name: StringName) -> Array[LineData]:
	if line_sets.has(set_name):
		return line_sets[set_name]
	return []


func all_lines() -> Array[LineData]:
	var lines: Array[LineData] = ask.duplicate()
	for key: StringName in asks:
		lines.append_array(asks[key])
	for set_name: StringName in line_sets:
		lines.append_array(line_sets[set_name])
	lines.append_array(stage_lines)
	for option in options:
		lines.append_array(option.all_reactions())
	return lines
