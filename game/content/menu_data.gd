class_name MenuData
extends RefCounted
## The main menu's words as data, from [code]content/menu.json[/code]: the title over the menu, and the
## named sets of lines the imp says there, such as his barks and the question New Game puts when there
## is a run to lose. Their lines can hang on what the menu knows ([constant FACTS]).

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


## The lines of the set called [param set_name], or none.
func lines_in(set_name: StringName) -> Array[LineData]:
	var lines: Array[LineData] = []
	lines.assign(sets.get(set_name, []))
	return lines


## Every line on the menu, set by set.
func all_lines() -> Array[LineData]:
	var lines: Array[LineData] = []
	for set_name in sets:
		lines.append_array(sets[set_name])
	return lines
