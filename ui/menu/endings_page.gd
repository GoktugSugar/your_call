class_name EndingsPage
extends MenuList
## The endings, on the main menu in place of its entries: every ending of the game in its group, the
## groups side by side, a long group running on into a column of its own. The endings the player has
## found show their names in ink; the rest are a faded hand-drawn blank, saying nothing of what they
## are. Under them, how many have been found, then Back. Back or Esc leaves.

## Emitted when the player leaves the page.
signal closed

## The heading over the endings.
@export var heading: Label
## The columns of endings, side by side.
@export var columns: HBoxContainer
## How many have been found.
@export var count_label: Label
## Leaves the page.
@export var back: MenuWord

@export_group("Layout")
## The most endings in one column; a longer group runs on into another.
@export_range(1, 30) var rows_per_column := 7
## Gap between one ending and the next in a column.
@export_range(0, 60) var row_gap := 4
## Size of an ending's name.
@export_range(8, 120) var name_size := 40
## Width and height of the blank standing for an ending not yet found.
@export var blank_size := Vector2(170.0, 56.0)
## Seconds between one blank drawing itself on and the next.
@export_range(0.0, 1.0, 0.005) var blank_stagger := 0.03
## Seconds a blank takes to draw itself on.
@export_range(0.0, 2.0, 0.01) var blank_draw := 0.25

@export_group("Look")
## Palette role of the heading.
@export var heading_role := &"heading"
## Palette role of a found ending's name.
@export var found_role := &"ink"
## Palette role of the blank for an ending not yet found.
@export var blank_role := &"faded"
## Palette role of the count.
@export var count_role := &"muted"


func _ready() -> void:
	hide()
	back.pressed.connect(close)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


## Shows every ending in [param menu]'s words, the ones in [param found] by name, then how many of them
## have been found, Back current.
func open(menu: MenuData, found: PackedStringArray) -> void:
	var palette := InkPalette.get_default()
	heading.text = menu.endings_heading
	heading.add_theme_color_override(&"font_color", palette.color(heading_role))
	for column in columns.get_children():
		# Taken out at once, so the new columns' layout never counts them.
		columns.remove_child(column)
		column.queue_free()
	var total := 0
	var shown := 0
	var blanks := 0
	for group in menu.ending_groups:
		var column: VBoxContainer = null
		for ending: Dictionary in group:
			if column == null or column.get_child_count() >= rows_per_column:
				column = VBoxContainer.new()
				column.add_theme_constant_override(&"separation", row_gap)
				columns.add_child(column)
			total += 1
			if String(ending["id"]) in found:
				shown += 1
				column.add_child(_name(ending["name"], palette.color(found_role)))
			else:
				column.add_child(_blank(blanks))
				blanks += 1
	count_label.text = menu.endings_count.format({"found": shown, "total": total})
	count_label.add_theme_color_override(&"font_color", palette.color(count_role))
	show()
	link()
	focus(back)


## Leaves the page.
func close() -> void:
	if not visible:
		return
	hide()
	closed.emit()


func _name(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size.y = blank_size.y
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override(&"font_size", name_size)
	label.add_theme_color_override(&"font_color", color)
	return label


## A faded blank line, drawing itself on a little after the one before it.
func _blank(index: int) -> InkUnderline:
	var blank := InkUnderline.new()
	blank.custom_minimum_size = blank_size
	blank.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	blank.color_role = blank_role
	blank.reveal = 0.0
	var tween := create_tween()
	tween.tween_interval(blank_stagger * index)
	tween.tween_property(blank, ^"reveal", 1.0, blank_draw)
	return blank
