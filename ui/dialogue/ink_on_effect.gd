@tool
class_name InkOnEffect
extends RichTextEffect
## Inks text on in place, a character at a time with a soft leading edge. The whole page is laid
## out from the start, so nothing shifts while it types. Wrap the text in [code][inkon]...[/inkon][/code].

## The BBCode tag this effect answers to.
var bbcode := "inkon"
## How many characters are on the page, counting the one being inked as a fraction.
var progress := 0.0
## How many characters the soft leading edge spans.
var edge := 3.0


## How many characters are on the page [param time] seconds in, counting the one being inked as a
## fraction. [param schedule] holds when each character starts to ink on, with one more entry for when
## the last is done; after that the count runs on at [param rate] characters a second, so the soft
## leading edge can finish.
static func progress_at(schedule: PackedFloat32Array, time: float, rate: float) -> float:
	var last := schedule.size() - 1
	if last <= 0 or time >= schedule[last]:
		return last + (time - schedule[last]) * rate
	var i := clampi(schedule.bsearch(time, false) - 1, 0, last - 1)
	return i + (time - schedule[i]) / maxf(schedule[i + 1] - schedule[i], 0.0001)


func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	char_fx.color.a *= clampf((progress - char_fx.range.x) / maxf(edge, 0.001), 0.0, 1.0)
	return true
