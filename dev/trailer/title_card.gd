class_name TitleCard
extends Control
## The trailers' last card: the game's title inking on in place as the main menu's does, its stroke
## drawn under it, then the release line under that in amber. The words of the title come from the
## menu's own ([code]content/menu.json[/code]), so the card follows any change to the title. Development
## only, like the rest of the trailers.

@export var title: MenuTitle
@export var release: RichTextLabel
## The menu's words, for the title.
@export_file("*.json") var menu_path := "res://content/menu.json"
## The palette role the release line is in.
@export var release_role := &"amber"
## Seconds between the title's stroke being drawn and the release line starting to ink on.
@export_range(0.0, 3.0, 0.05) var release_delay := 0.25
## Seconds the release line takes to ink on.
@export_range(0.05, 5.0, 0.05) var release_time := 0.8
## How many characters soft the edge of the inking is.
@export_range(0.0, 10.0, 0.1) var ink_edge := 3.0

var _effect := InkOnEffect.new()


func _ready() -> void:
	release.install_effect(_effect)
	_effect.edge = ink_edge
	visible = false


## Sets the card's words, not inked on yet: the game's title, and [param line] under it.
func set_words(line: String) -> void:
	var menu := ContentLoader.new().load_menu(menu_path)
	title.set_title(menu.title if menu != null else "")
	var colour := InkPalette.get_default().color(release_role)
	release.text = "[center][color=#%s][inkon]%s[/inkon][/color][/center]" % [colour.to_html(false), line]
	_effect.progress = 0.0


## Shows the card and inks it on: the title and its stroke, then the release line. Returns once all
## of it is on.
func ink_on() -> void:
	visible = true
	await title.ink_on()
	if release_delay > 0.0:
		await get_tree().create_timer(release_delay, false).timeout
	var tween := create_tween()
	tween.tween_property(_effect, ^"progress", release.get_total_character_count() + ink_edge, release_time)
	await tween.finished
