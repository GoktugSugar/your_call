class_name DevMenu
extends CanvasLayer
## Development only: F2 opens a list of every chapter in the run and, beside it, every question in the
## chapter picked from the list, with the one being played marked. Picking a question starts the run
## there. Over the lists, a switch turns on auto skip, the player setting that moves dialogue on by itself.
## The game holds still while the menu is open, and F2 or Esc closes it again. Mouse or keys: a chapter's
## questions show once its name is clicked or reached, the arrows move between entries, Enter picks.

## Emitted when an entry is picked: the chapter's id, and the beat to start from, empty for its top.
signal picked(chapter: StringName, beat: StringName)

## The menu's panel, around everything else.
@export var panel: PanelContainer
## Holds the title, the switch and the lists.
@export var stack: VBoxContainer
## Holds the list of chapters and, beside it, the page of questions.
@export var body: HBoxContainer
## Holds a name per chapter.
@export var chapter_list: VBoxContainer
## Scrolls the page of questions when it outgrows the screen.
@export var scroll: ScrollContainer
## Holds a page of questions per chapter, only the picked chapter's shown.
@export var pages: Container
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

@export_group("Layout")
## The most entries in a column before a chapter's page breaks into another column.
@export_range(1, 100) var most_rows := 16
## The space between the columns of a page.
@export_range(0, 400) var column_gap := 56
## The widest the menu grows before its page scrolls, as a share of the screen.
@export_range(0.1, 1.0, 0.01) var max_width_share := 0.95
## The tallest the menu grows before its page scrolls, as a share of the screen.
@export_range(0.1, 1.0, 0.01) var max_height_share := 0.92

@export_group("Look")
## Palette role of each chapter's name.
@export var heading_role := &"secondary"
## Palette role of the entries.
@export var entry_role := &"ink"
## Palette role of the entry being played now, and of its chapter's name.
@export var now_role := &"amber"
## Palette role of the panel.
@export var panel_role := &"box_paper"
## Palette role of the panel's edge.
@export var edge_role := &"ink"
## Palette role of the wash behind the entry under the pointer or the keys, and behind the name of the
## chapter whose questions are shown.
@export var lit_role := &"faded"
## How opaque that wash is.
@export_range(0.0, 1.0, 0.01) var lit_alpha := 0.6
## How opaque the panel is.
@export_range(0.0, 1.0, 0.01) var panel_alpha := 0.97

var _first: Button
var _now: Button
## The top of the chapter being played, focused when what is being played is not a question.
var _now_top: Button
## Each chapter's name in the list, by the chapter's id.
var _headings: Dictionary[StringName, Button] = {}
## Each chapter's page of questions, by the chapter's id.
var _pages: Dictionary[StringName, Control] = {}
## The wash behind an entry under the pointer or the keys.
var _lit := StyleBoxFlat.new()
## No wash at all.
var _plain := StyleBoxEmpty.new()


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
	_lit.bg_color = Color(palette.color(lit_role), lit_alpha)
	_lit.set_corner_radius_all(6)
	auto_skip.text = auto_skip_text
	_style_entry(auto_skip, palette.color(entry_role))
	auto_skip.toggled.connect(func(on: bool) -> void: PlayerSettings.auto_advance = on)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


## Lists [param chapters] and holds the game still, marking the beat [param now_beat] of the chapter
## [param now_chapter] as the one being played, and showing that chapter's questions.
func open(chapters: Array[ChapterData], now_chapter: StringName, now_beat: StringName) -> void:
	_fill(chapters, now_chapter, now_beat)
	auto_skip.set_pressed_no_signal(PlayerSettings.auto_advance)
	# Shown before it is measured, since a container sizes only what is visible.
	visible = true
	_fit()
	if not chapters.is_empty():
		_show(now_chapter if _pages.has(now_chapter) else chapters[0].id)
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
	for holder: Node in [chapter_list, pages]:
		for child in holder.get_children():
			holder.remove_child(child)
			child.queue_free()
	_headings.clear()
	_pages.clear()
	_first = null
	_now = null
	_now_top = null
	for chapter in chapters:
		var heading := _add_heading(chapter, chapter.id == now_chapter)
		_link(heading, _add_page(chapter, now_chapter, now_beat))


## Adds [param chapter]'s name to the list. Clicking or reaching it shows the chapter's questions.
func _add_heading(chapter: ChapterData, is_now: bool) -> Button:
	var heading := Button.new()
	heading.text = "%s  %s" % [chapter.id, chapter.title]
	_style_entry(heading, InkPalette.get_default().color(now_role if is_now else heading_role))
	heading.add_theme_font_size_override(&"font_size", heading_size)
	var id := chapter.id
	heading.focus_entered.connect(func() -> void: _show(id))
	heading.pressed.connect(func() -> void: _show(id))
	chapter_list.add_child(heading)
	_headings[id] = heading
	if _first == null:
		_first = heading
	return heading


## Adds the page of [param chapter]'s questions, its top first, in columns of at most [member most_rows],
## evened out.
func _add_page(chapter: ChapterData, now_chapter: StringName, now_beat: StringName) -> HBoxContainer:
	var is_now := chapter.id == now_chapter
	var entries: Array[Button] = [_entry(top_text, chapter.id, &"", is_now and now_beat == &"")]
	if is_now:
		_now_top = entries[0]
	for beat in chapter.beats:
		if beat is QuestionData:
			var question := beat as QuestionData
			entries.append(_entry("%s  %s" % [question.number, question.title], chapter.id, beat.id,
					is_now and beat.id == now_beat))
	var page := HBoxContainer.new()
	page.add_theme_constant_override(&"separation", column_gap)
	pages.add_child(page)
	_pages[chapter.id] = page
	var rows := ceili(entries.size() / ceilf(entries.size() / float(most_rows)))
	for i in entries.size():
		if i % rows == 0:
			page.add_child(VBoxContainer.new())
		page.get_child(-1).add_child(entries[i])
	return page


## An entry that starts the run at [param beat] of [param chapter], marked when it is the one being
## played.
func _entry(text: String, chapter: StringName, beat: StringName, is_now: bool) -> Button:
	var entry := Button.new()
	entry.text = "%s %s" % [now_mark, text] if is_now else text
	_style_entry(entry, InkPalette.get_default().color(now_role if is_now else entry_role))
	entry.pressed.connect(func() -> void: picked.emit(chapter, beat))
	if is_now:
		_now = entry
	return entry


## Lets the keys go from [param heading] into [param page], and from the page's first column back to it.
func _link(heading: Button, page: Control) -> void:
	var first_column := page.get_child(0)
	heading.focus_neighbor_right = heading.get_path_to(first_column.get_child(0))
	for entry: Control in first_column.get_children():
		entry.focus_neighbor_left = entry.get_path_to(heading)


## Sizes the page's scroll to the biggest page, so the menu keeps still from chapter to chapter, as far as
## the screen allows. Every page is shown while it is measured.
func _fit() -> void:
	for page: Control in _pages.values():
		page.show()
	scroll.custom_minimum_size = Vector2.ZERO
	var share := get_viewport().get_visible_rect().size * Vector2(max_width_share, max_height_share)
	var edges := panel.get_combined_minimum_size() - stack.get_combined_minimum_size()
	var beside := body.get_combined_minimum_size().x - scroll.get_combined_minimum_size().x
	var above := stack.get_combined_minimum_size().y - body.get_combined_minimum_size().y
	var room := share - edges - Vector2(beside, above)
	var content := pages.get_combined_minimum_size()
	scroll.custom_minimum_size = Vector2(minf(content.x, room.x), minf(content.y, room.y))


## Shows the questions of the chapter [param id], and washes its name in the list.
func _show(id: StringName) -> void:
	for each: StringName in _pages:
		_pages[each].visible = each == id
		_headings[each].add_theme_stylebox_override(&"normal", _lit if each == id else _plain)


## Gives [param button] the look of an entry, its words in [param color], with a wash behind it under
## the pointer or the keys.
func _style_entry(button: Button, color: Color) -> void:
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override(&"font_size", entry_size)
	for state: StringName in [&"font_color", &"font_hover_color", &"font_focus_color", &"font_pressed_color",
			&"font_hover_pressed_color"]:
		button.add_theme_color_override(state, color)
	button.add_theme_stylebox_override(&"normal", _plain)
	for state: StringName in [&"hover", &"focus", &"pressed", &"hover_pressed"]:
		button.add_theme_stylebox_override(state, _lit)
