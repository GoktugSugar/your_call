extends Node2D
## Development only: every push button look in a row, each named, then a button lifted as if pointed
## at, one held halfway down, and the timer's button with its word, so the buttons can be judged side
## by side. With [code]--press[/code] each button in the row is pressed in turn.
## [codeblock]
## Godot --path . res://dev/capture_runner.tscn -- --scene=res://dev/button_sampler.tscn --out=C:/somewhere/shot --times=1
## [/codeblock]

## The push button scene.
@export var button_scene: PackedScene
## The looks in the row, by name.
@export var looks: PackedStringArray = ["plain", "blue", "red", "green", "gold"]
## Where the first button stands.
@export var first_spot := Vector2(240.0, 430.0)
## Distance between neighbouring buttons.
@export_range(50.0, 600.0, 1.0) var spacing := 360.0
## Where the row of states stands.
@export var states_y := 900.0
## Gap between a button's base and its name.
@export_range(0.0, 100.0, 1.0) var name_gap := 14.0
## Size of the names' letters.
@export_range(8, 80) var name_size := 26
## Seconds between one press and the next with [code]--press[/code].
@export_range(0.1, 5.0, 0.05) var press_gap := 0.6

var _row: Array[PushButton] = []


func _ready() -> void:
	for i in looks.size():
		var button := _button(looks[i], Vector2(first_spot.x + spacing * i, first_spot.y))
		_row.append(button)
		_name(looks[i], button.position)
	var lifted := _button(&"blue", Vector2(first_spot.x + spacing * 0.5, states_y))
	lifted.highlighted = true
	_name("lifted", lifted.position)
	var down := _button(&"red", Vector2(first_spot.x + spacing * 1.5, states_y))
	down.depth = 0.5
	_name("half pressed", down.position)
	var timer := _button(&"plain", Vector2(first_spot.x + spacing * 2.5, states_y))
	timer.text = "press"
	_name("with a word", timer.position)
	if DevArgs.parse().has("press"):
		for button in _row:
			await get_tree().create_timer(press_gap).timeout
			button.press()


func _button(look: StringName, at: Vector2) -> PushButton:
	var button := button_scene.instantiate() as PushButton
	button.look = ButtonLook.find(look)
	button.position = at
	add_child(button)
	return button


func _name(text: String, under: Vector2) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override(&"font_size", name_size)
	label.add_theme_color_override(&"font_color", InkPalette.get_default().secondary)
	add_child(label)
	label.reset_size()
	label.position = under + Vector2(-label.size.x * 0.5, name_gap)
