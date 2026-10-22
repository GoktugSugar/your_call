class_name TitleCard
extends CanvasLayer
## The trailer's title card: the game's name inked on large in the hand-lettered face, an amber stroke
## drawn under it, then a line beneath in amber, such as where to find the game. Words ink on in place
## the way the dialogue box's do, a character at a time, and never shift as they go.

## The game's name.
@export var title_label: RichTextLabel
## The stroke under the name.
@export var underline: InkUnderline
## The line under it all.
@export var line_label: RichTextLabel

@export_group("Look")
## Size of the name, in pixels.
@export_range(8, 400) var title_size := 230
## Size of the line, in pixels.
@export_range(8, 200) var line_size := 60
## Palette role of the name.
@export var title_role := &"ink"
## Palette role of the line.
@export var line_role := &"amber"
## Where the middle of the name sits on the canvas.
@export var title_center := Vector2(960.0, 380.0)
## Gap between the name and the stroke under it, and between the stroke and the line.
@export_range(-200.0, 200.0, 1.0) var title_gap := -30.0
@export_range(-200.0, 200.0, 1.0) var line_gap := 26.0
## The stroke's width, as a share of the name's.
@export_range(0.1, 1.5, 0.01) var underline_share := 0.78
## The stroke's height, its sag drawn through the middle.
@export_range(1.0, 80.0, 1.0) var underline_height := 24.0
## How many characters the soft leading edge of the ink spans.
@export_range(0.0, 20.0, 0.1) var ink_edge := 2.0

@export_group("Timing")
## Seconds the name takes to ink on.
@export_range(0.05, 5.0, 0.05) var title_ink := 1.1
## Seconds the stroke takes to draw on, once the name is down.
@export_range(0.05, 5.0, 0.05) var underline_draw := 0.35
## Seconds between the stroke and the line starting to ink on.
@export_range(0.0, 5.0, 0.05) var line_delay := 0.15
## Seconds the line takes to ink on.
@export_range(0.05, 5.0, 0.05) var line_ink := 0.7

var _title_effect := InkOnEffect.new()
var _line_effect := InkOnEffect.new()


func _ready() -> void:
	var palette := InkPalette.get_default()
	for pair: Array in [[title_label, _title_effect, title_size, title_role], [line_label, _line_effect, line_size, line_role]]:
		var label: RichTextLabel = pair[0]
		var effect: InkOnEffect = pair[1]
		effect.edge = ink_edge
		effect.progress = 0.0
		label.install_effect(effect)
		label.add_theme_font_size_override(&"normal_font_size", pair[2])
		label.add_theme_color_override(&"default_color", palette.color(pair[3]))
	underline.reveal = 0.0
	visible = false


## Inks [param title] on, draws the stroke under it, then inks [param line] on beneath. Returns when
## all of it is down.
func write_on(title: String, line: String) -> void:
	_set_words(title_label, title)
	_set_words(line_label, line)
	_lay_out()
	visible = true
	var steps := create_tween()
	steps.tween_property(_title_effect, ^"progress", title.length() + ink_edge, title_ink)
	steps.tween_property(underline, ^"reveal", 1.0, underline_draw).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	steps.tween_interval(line_delay)
	steps.tween_property(_line_effect, ^"progress", line.length() + ink_edge, line_ink)
	await steps.finished


func _set_words(label: RichTextLabel, words: String) -> void:
	label.text = "[inkon]%s[/inkon]" % words


## Centres the name on [member title_center], with the stroke and the line under it. Each label is
## the width of the page, its words centred in it.
func _lay_out() -> void:
	var width := get_viewport().get_visible_rect().size.x
	for label: RichTextLabel in [title_label, line_label]:
		label.size = Vector2(width, label.size.y)
		label.size = Vector2(width, label.get_content_height())
		label.position.x = title_center.x - width * 0.5
	title_label.position.y = title_center.y - title_label.size.y * 0.5
	var under := title_label.position.y + title_label.size.y + title_gap
	underline.size = Vector2(title_label.get_content_width() * underline_share, underline_height)
	underline.position = Vector2(title_center.x - underline.size.x * 0.5, under)
	line_label.position.y = under + underline_height + line_gap
