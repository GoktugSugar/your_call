class_name QuestionData
extends BeatData
## One question: the imp's lines that pose it, the stage it plays on, its options and its reveal.
## Its [member BeatData.id], such as [code]lever[/code], is what saves and the crowd tally key off.

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
	for set_name: StringName in line_sets:
		lines.append_array(line_sets[set_name])
	lines.append_array(stage_lines)
	for option in options:
		lines.append_array(option.all_reactions())
	return lines
