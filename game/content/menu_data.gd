class_name MenuData
extends RefCounted
## The main menu's words as data, from [code]content/menu.json[/code]: the title over the menu, the
## named sets of lines the imp says there, such as his barks and the question New Game puts when there
## is a run to lose, and the endings page's words: its heading, its count and every ending's name. The
## imp's lines can hang on what the menu knows ([constant FACTS]).

## There is a saved run to continue.
const RUN_SAVED := &"run_saved"
## Every fact a line on the menu can name in its [code]if[/code] or [code]unless[/code].
const FACTS: Array[StringName] = [RUN_SAVED]

## The id its lines' ids start with.
var id := &"menu"
## The title over the menu.
var title := ""
## The imp's lines on the menu, in named sets.
var sets: Dictionary[StringName, Array] = {}
## The heading over the endings page.
var endings_heading := ""
## How many endings have been found, with [code]{found}[/code] and [code]{total}[/code] to fill in.
var endings_count := ""
## Every ending, in the groups the endings page shows side by side, each group in order: lists of
## [code]{"id": StringName, "name": String}[/code].
var ending_groups: Array[Array] = []


## The lines of the set called [param set_name], or none.
func lines_in(set_name: StringName) -> Array[LineData]:
	var lines: Array[LineData] = []
	lines.assign(sets.get(set_name, []))
	return lines


## Every ending's id, group by group.
func ending_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for group in ending_groups:
		for ending: Dictionary in group:
			ids.append(ending["id"])
	return ids


## Every line on the menu, set by set.
func all_lines() -> Array[LineData]:
	var lines: Array[LineData] = []
	for set_name in sets:
		lines.append_array(sets[set_name])
	return lines
