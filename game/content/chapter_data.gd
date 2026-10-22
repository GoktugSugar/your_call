class_name ChapterData
extends RefCounted
## A chapter of the run: its beats, in play order.

## Stable id, such as [code]ch1[/code].
var id := &""
## Its title, such as [code]The Tracks[/code].
var title := ""
## Its beats, in play order.
var beats: Array[BeatData] = []
## The pot of money the chapter hands the player, such as [code]{"start": 10000}[/code], or empty for none.
var wallet := {}
## What a run that starts after this chapter takes it to have left behind: facts to remember and kills
## by kind, such as [code]{"remember": ["button_woke"], "kills": {"soul": 7}}[/code]. For the dev menu.
var if_skipped := {}


## The beat with [param beat_id], or null.
func find_beat(beat_id: StringName) -> BeatData:
	for beat in beats:
		if beat.id == beat_id:
			return beat
	return null
