class_name DevMenu
extends CanvasLayer
## Development only: F2 opens a list of every chapter in the run and every question in it, with the
## one being played marked. Picking one starts the run there. Over the list, a switch turns on auto skip,
## the player setting that moves dialogue on by itself. The game holds still while the menu is open, and
## F2 or Esc closes it again. Mouse or keys: the arrows move between entries, Enter picks.

## Emitted when an entry is picked: the chapter's id, and the beat to start from, empty for its top.
signal picked(chapter: StringName, beat: StringName)

## Holds the title and the columns.
@export var panel: PanelContainer
## Scrolls the columns when they outgrow the panel.
@export var scroll: ScrollContainer
## Holds a column per chapter.
@export var columns: HBoxContainer
## Turns auto skip on and off: [member PlayerSettings.auto_advance].
@export var auto_skip: CheckButton

@export_group("Words")
## What the entry for the top of a chapter says.
@export var top_text := "From the top"
## What marks the entry being played now.
@export var now_mark := "now:"
## What the auto skip switch says.
@export var auto_skip_text := "Auto skip: each line moves on once it is said"
## Size of each chapter's name.
@export_range(8, 120) var heading_size := 34
## Size of the entries.
@export_range(8, 120) var entry_size := 28

@export_group("Look")
## Palette role of each chapter's name.
@export var heading_role := &"secondary"
## Palette role of the entries.
@export var entry_role := &"ink"
## Palette role of the entry being played now.
@export var now_role := &"amber"
## Palette role of the panel.
@export var panel_role := &"box_paper"
## Palette role of the panel's edge.
@export var edge_role := &"ink"
## Palette role of the wash behind the entry under the pointer or the keys.
@export var lit_role := &"faded"
## How opaque the panel is.
@export_range(0.0, 1.0, 0.01) var panel_alpha := 0.97
## The tallest the list grows before it scrolls, as a share of the screen.
@export_range(0.1, 1.0, 0.01) var max_height_share := 0.86

var _first: Button
var _now: Button
## The top of the chapter being played, focused when what is being played is not a question.
var _now_top: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var palette := InkPalette.get_default()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(palette.color(panel_role), panel_alpha)
	style.border_color = palette.color(edge_role)
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	panel.add_theme_stylebox_override(&"panel", style)
	auto_skip.text = auto_skip_text
	_style_entry(auto_skip, palette.color(entry_role))
	auto_skip.toggled.connect(func(on: bool) -> void: PlayerSettings.auto_advance = on)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


## Lists [param chapters] and holds the game still, marking the beat [param now_beat] of the chapter
## [param now_chapter] as the one being played.
func open(chapters: Array[ChapterData], now_chapter: StringName, now_beat: StringName) -> void:
	_fill(chapters, now_chapter, now_beat)
	auto_skip.set_pressed_no_signal(PlayerSettings.auto_advance)
	# Shown before it is measured, since a container sizes only what is visible.
	visible = true
	var screen := get_viewport().get_visible_rect().size
	var content := columns.get_combined_minimum_size()
	scroll.custom_minimum_size = Vector2(minf(content.x, screen.x * 0.9), minf(content.y, screen.y * max_height_share))
	get_tree().paused = true
	var focus := _now if _now != null else (_now_top if _now_top != null else _first)
	if focus != null:
		focus.grab_focus()


## Hides the list and lets the game carry on.
func close() -> void:
	visible = false
	get_tree().paused = false


## Whether the list is up.
func is_open() -> bool:
	return visible


## Picks the entry for [param chapter] and [param beat], as a click on it would.
func pick(chapter: StringName, beat: StringName) -> void:
	picked.emit(chapter, beat)


func _fill(chapters: Array[ChapterData], now_chapter: StringName, now_beat: StringName) -> void:
	for child in columns.get_children():
		columns.remove_child(child)
		child.queue_free()
	_first = null
	_now = null
	_now_top = null
	for chapter in chapters:
		var column := VBoxContainer.new()
		columns.add_child(column)
		var heading := Label.new()
		heading.text = "%s  %s" % [chapter.id, chapter.title]
		heading.add_theme_font_size_override(&"font_size", heading_size)
		heading.add_theme_color_override(&"font_color", InkPalette.get_default().color(heading_role))
		column.add_child(heading)
		var top := _add_entry(column, top_text, chapter.id, &"", chapter.id == now_chapter and now_beat == &"")
		if chapter.id == now_chapter:
			_now_top = top
		for beat in chapter.beats:
			if beat is QuestionData:
				var question := beat as QuestionData
				_add_entry(column, "%s  %s" % [question.number, question.title], chapter.id, beat.id,
						chapter.id == now_chapter and beat.id == now_beat)


func _add_entry(column: VBoxContainer, text: String, chapter: StringName, beat: StringName, is_now: bool) -> Button:
	var entry := Button.new()
	entry.text = "%s %s" % [now_mark, text] if is_now else text
	_style_entry(entry, InkPalette.get_default().color(now_role if is_now else entry_role))
	entry.pressed.connect(func() -> void: picked.emit(chapter, beat))
	column.add_child(entry)
	if _first == null:
		_first = entry
	if is_now:
		_now = entry
	return entry


## Gives [param button] the look of an entry, its words in [param color], with a wash behind it under
## the pointer or the keys.
func _style_entry(button: Button, color: Color) -> void:
	button.flat = true
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override(&"font_size", entry_size)
	for state: StringName in [&"font_color", &"font_hover_color", &"font_focus_color", &"font_pressed_color",
			&"font_hover_pressed_color"]:
		button.add_theme_color_override(state, color)
	var lit := StyleBoxFlat.new()
	lit.bg_color = Color(InkPalette.get_default().color(lit_role), 0.6)
	lit.set_corner_radius_all(6)
	for state: StringName in [&"hover", &"focus", &"pressed", &"hover_pressed"]:
		button.add_theme_stylebox_override(state, lit)
