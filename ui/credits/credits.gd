class_name Credits
extends CanvasLayer
## The credits: a clean paper page fades in, then the title and each credit scroll upward, each role in
## amber over its name in ink, and the page fades away. An advance press while they roll hurries them
## to the end. The text comes from [code]content/credits.json[/code].

## Emitted when the credits have rolled and faded.
signal finished

const CREDITS_PATH := "res://content/credits.json"

## Everything that fades in and out together.
@export var sheet: Control
## The column of title and credits that scrolls up.
@export var column: VBoxContainer

@export_group("Look")
## Size of the title.
@export_range(8, 300) var title_size := 104
## Size of each role.
@export_range(8, 200) var role_size := 34
## Size of each name.
@export_range(8, 200) var name_size := 50
## Space after the title and between credits.
@export_range(0.0, 400.0, 1.0) var credit_gap := 64.0
## Space between a role and its name.
@export_range(-40.0, 100.0, 1.0) var role_gap := 0.0
## Width of the column; longer names wrap within it.
@export_range(100.0, 1900.0, 1.0) var column_width := 1100.0

@export_group("Timing")
## Seconds the page takes to fade in.
@export_range(0.0, 5.0, 0.05) var fade_in := 0.7
## How fast the credits scroll, in pixels a second.
@export_range(1.0, 2000.0, 1.0) var scroll_speed := 90.0
## How much faster they scroll once the player presses on.
@export_range(1.0, 50.0, 0.5) var hurry := 8.0
## Seconds the page takes to fade out.
@export_range(0.0, 5.0, 0.05) var fade_out := 0.8

var _running := false
var _hurried := false
var _scroll: Tween


func _ready() -> void:
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not _running or not event.is_action_pressed(&"advance"):
		return
	get_viewport().set_input_as_handled()
	_hurried = true
	if _scroll != null and _scroll.is_running():
		_scroll.set_speed_scale(hurry)


## Rolls the credits. Returns once they have faded away.
func roll() -> void:
	_fill_column()
	visible = true
	_running = true
	_hurried = false
	sheet.modulate.a = 0.0
	var screen := sheet.get_viewport_rect().size
	column.size = Vector2(column_width, 0.0)
	column.position = Vector2((screen.x - column_width) * 0.5, screen.y)
	var appear := create_tween()
	appear.tween_property(sheet, ^"modulate:a", 1.0, fade_in)
	await appear.finished
	# Measured once the column has been laid out, so a name that wraps counts at its full height.
	await get_tree().process_frame
	var height := column.get_combined_minimum_size().y
	_scroll = create_tween()
	_scroll.tween_property(column, ^"position:y", -height, (screen.y + height) / scroll_speed)
	if _hurried:
		_scroll.set_speed_scale(hurry)
	await _scroll.finished
	var leave := create_tween()
	leave.tween_property(sheet, ^"modulate:a", 0.0, fade_out)
	await leave.finished
	_running = false
	visible = false
	finished.emit()


func _fill_column() -> void:
	for child in column.get_children():
		column.remove_child(child)
		child.queue_free()
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(CREDITS_PATH))
	if not data is Dictionary:
		push_error("Credits: cannot read %s" % CREDITS_PATH)
		return
	var palette := InkPalette.get_default()
	column.add_theme_constant_override(&"separation", int(credit_gap))
	column.add_child(_label(str(data.get("title", "")), title_size, palette.ink))
	for credit: Variant in data.get("credits", []):
		if not credit is Dictionary:
			continue
		var pair := VBoxContainer.new()
		pair.add_theme_constant_override(&"separation", int(role_gap))
		pair.add_child(_label(str(credit.get("role", "")), role_size, palette.amber))
		pair.add_child(_label(str(credit.get("name", "")), name_size, palette.ink))
		column.add_child(pair)


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = column_width
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	return label
