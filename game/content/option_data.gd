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
## The imp's reaction, one line per dialogue box run.
var reaction: Array[LineData] = []
## The secret ending this option fires, or empty for none.
var ending := &""
