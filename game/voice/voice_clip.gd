class_name VoiceClip
extends RefCounted
## One line's voice: a single take of the whole line, and the time each of its characters is spoken.
## A dialogue box plays only its own stretch of the take.

## The take.
var stream: AudioStream
## The spoken text the timings belong to: the line with its colour tags stripped.
var text := ""
## When each character starts and ends, in seconds into the take. Empty if the take came without timings.
var starts := PackedFloat32Array()
var ends := PackedFloat32Array()


## The stretch of the take that speaks characters [param from] up to (not including) [param to], as
## start and end seconds. Without timings, the take is shared out in proportion to the characters.
func span(from: int, to: int) -> Vector2:
	if not _has_timings():
		var length := stream.get_length() if stream != null else 0.0
		var count := maxf(float(text.length()), 1.0)
		return Vector2(length * from / count, length * to / count)
	var first := clampi(from, 0, starts.size() - 1)
	var last := clampi(to - 1, first, ends.size() - 1)
	return Vector2(starts[first], ends[last])


## When each of characters [param from] up to [param to] starts, in seconds after the start of their
## stretch, with one more entry for when the last one ends. The dialogue box inks them on to this.
func schedule(from: int, to: int) -> PackedFloat32Array:
	var stretch := span(from, to)
	var times := PackedFloat32Array()
	times.resize(to - from + 1)
	for i in to - from:
		if _has_timings():
			times[i] = maxf(starts[clampi(from + i, 0, starts.size() - 1)] - stretch.x, 0.0)
		else:
			times[i] = (stretch.y - stretch.x) * i / maxf(float(to - from), 1.0)
	times[to - from] = stretch.y - stretch.x
	return times


func _has_timings() -> bool:
	return not starts.is_empty() and starts.size() == text.length() and ends.size() == text.length()
