class_name ChapterData
extends RefCounted
## A chapter of the run: its beats, in play order.

## Stable id, such as [code]ch1[/code].
var id := &""
## Its title, such as [code]The Tracks[/code].
var title := ""
## Its beats, in play order.
var beats: Array[BeatData] = []


## The beat with [param beat_id], or null.
func find_beat(beat_id: StringName) -> BeatData:
	for beat in beats:
		if beat.id == beat_id:
			return beat
	return null
