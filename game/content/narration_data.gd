class_name NarrationData
extends BeatData
## A beat of narration: the imp talking between questions, one line per dialogue box run.

## What is said, in order.
var lines: Array[LineData] = []


func all_lines() -> Array[LineData]:
	return lines.duplicate()
