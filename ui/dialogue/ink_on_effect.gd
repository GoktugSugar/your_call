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


func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	char_fx.color.a *= clampf((progress - char_fx.range.x) / maxf(edge, 0.001), 0.0, 1.0)
	return true
