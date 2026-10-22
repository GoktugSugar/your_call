class_name BeatData
extends RefCounted
## One beat of the run: a question, or some lines from the imp between questions.

## Stable id within its chapter, such as [code]lever[/code].
var id := &""
## The chapter it belongs to, such as [code]ch1[/code].
var chapter := &""


## Every line the beat can show, in the order it sits in the content.
func all_lines() -> Array[LineData]:
	return []
