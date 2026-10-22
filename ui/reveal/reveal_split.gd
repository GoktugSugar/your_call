class_name RevealSplit
extends RefCounted
## What the crowd reveal shows for one question: a heading, then a bar per option with its share of the
## crowd, which one the player picked, and, for a coordination gamble, the line the crowd had to cross.
## By default it comes straight from the question's data; a stage whose split depends on how the
## question played, such as the tier an offer ladder stopped on, makes its own.

## The heading over the bars.
var heading := ""
## The words over each bar, in option order.
var labels := PackedStringArray()
## Each bar's share of the crowd, from 0 to 100.
var shares := PackedFloat32Array()
## Which bar is the player's.
var pick := -1
## Palette roles that colour the bars by meaning, such as blue and red, in option order. Empty colours
## the pick amber and the rest in crowd ink.
var roles: Array[StringName] = []
## Where the line the crowd had to cross falls, from 0 to 100. Below 0 draws none.
var mark := -1.0
## The words on that line, such as "half".
var mark_label := ""


## The split as [param question]'s data has it, with the option at [param picked] as the player's.
## A hidden option, picked only on the stage, has no bar.
static func of(question: QuestionData, picked: int) -> RevealSplit:
	var split := RevealSplit.new()
	split.heading = question.reveal_heading
	var labels := question.bar_labels()
	var shown := question.shown_options()
	for i in shown:
		split.labels.append(labels[i])
		split.shares.append(question.options[i].crowd)
	split.pick = shown.find(picked)
	split.mark_label = question.reveal_mark
	return split
