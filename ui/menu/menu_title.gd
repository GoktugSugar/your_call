class_name MenuTitle
extends VBoxContainer
## The game's title over the menu, hand-lettered large in ink with a stroke drawn under it. It inks on in
## place a character at a time, and then the stroke draws itself on from the left.

## The title's words.
@export var words: RichTextLabel
## The stroke under the words.
@export var stroke: InkUnderline
## Seconds the words take to ink on.
@export_range(0.0, 5.0, 0.05) var ink_time := 1.1
## Seconds the stroke takes to draw on, once the words are on.
@export_range(0.0, 3.0, 0.05) var stroke_time := 0.45
## How many characters the soft leading edge spans while the words ink on.
@export_range(0.0, 10.0, 0.1) var ink_edge := 3.0
## How much longer than the words the stroke runs, as a share of their width.
@export_range(0.5, 2.0, 0.01) var stroke_share := 1.08

var _effect := InkOnEffect.new()


func _ready() -> void:
	words.install_effect(_effect)
	_effect.edge = ink_edge
	stroke.reveal = 0.0


## Sets the title to [param text], not inked on yet.
func set_title(text: String) -> void:
	words.text = "[center][inkon]%s[/inkon][/center]" % text
	_effect.progress = 0.0
	stroke.reveal = 0.0
	var font := words.get_theme_font(&"normal_font")
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, words.get_theme_font_size(&"normal_font_size")).x
	stroke.custom_minimum_size.x = width * stroke_share


## Inks the title on, then draws the stroke under it. Returns once both are on.
func ink_on() -> void:
	var tween := create_tween()
	tween.tween_property(_effect, ^"progress", words.get_total_character_count() + ink_edge, ink_time)
	tween.tween_property(stroke, ^"reveal", 1.0, stroke_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished
