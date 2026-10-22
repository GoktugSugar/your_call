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
## Lines the stage shows, such as a plea floating over a figure. Their stage data names them with [code]says[/code].
var stage_lines: Array[LineData] = []
## The answers, in the order the choice row and the reveal show them.
var options: Array[OptionData] = []
## The reveal's heading.
var reveal_heading := "how others chose"


## The option labels, in order.
func option_labels() -> PackedStringArray:
	var labels := PackedStringArray()
	for option in options:
		labels.append(option.label)
	return labels


## The option with [param option_id], or null.
func find_option(option_id: StringName) -> OptionData:
	for option in options:
		if option.id == option_id:
			return option
	return null
