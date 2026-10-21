class_name CrowdReveal
extends Control
## How others chose: a muted lowercase heading, then one solid ink bar per option, in option order.
## The bars ink in from the left while their bare numbers count up past their ends. The player's pick
## is amber and the crowd is darker ink. No container, no flash, no bounce. While the reveal is up,
## it is the only thing listening: the first input finishes the inking, the next dismisses it.

## Emitted when the player dismisses the reveal.
signal dismissed
## Emitted when every bar has inked in.
signal settled

## Holds the heading and the rows, centred on [member center].
@export var content: VBoxContainer
@export var heading: Label
## The row each option is shown with.
@export var row_scene: PackedScene
## Where the middle of the reveal sits on the canvas.
@export var center := Vector2(960.0, 420.0)
## Palette role of the player's pick.
@export var pick_role := &"amber"
## Palette role of every other option.
@export var crowd_role := &"crowd"

@export_group("Timing")
## Seconds the reveal takes to fade in.
@export_range(0.0, 2.0, 0.01) var fade_in_duration := 0.25
## Seconds each bar takes to ink in.
@export_range(0.05, 5.0, 0.01) var ink_duration := 1.0
## Seconds between one bar starting and the next.
@export_range(0.0, 2.0, 0.01) var bar_stagger := 0.12
## Seconds the reveal takes to fade out once dismissed.
@export_range(0.0, 2.0, 0.01) var fade_out_duration := 0.3

## A step long enough to finish the inking at once.
const _FINISH_STEP := 1000.0

var _rows: Array[CrowdRow] = []
var _inking: Tween
var _live := false


func _ready() -> void:
	modulate.a = 0.0
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not _live or not event.is_action_pressed(&"advance"):
		return
	get_viewport().set_input_as_handled()
	if is_settling():
		_inking.custom_step(_FINISH_STEP)
	else:
		dismiss()


## Shows the split: [param labels] and [param shares] in option order, with [param pick] as the player's.
## Returns once the player has dismissed it.
func present(heading_text: String, labels: PackedStringArray, shares: PackedFloat32Array, pick: int) -> void:
	for row in _rows:
		row.queue_free()
	_rows.clear()
	heading.text = heading_text
	heading.add_theme_color_override(&"font_color", InkPalette.get_default().heading)
	for i in labels.size():
		var row := row_scene.instantiate() as CrowdRow
		content.add_child(row)
		row.setup(labels[i], shares[i] if i < shares.size() else 0.0, pick_role if i == pick else crowd_role)
		_rows.append(row)
	content.reset_size()
	content.position = center - content.get_combined_minimum_size() * 0.5
	visible = true
	_live = true
	var appear := create_tween()
	appear.tween_property(self, ^"modulate:a", 1.0, fade_in_duration)
	_inking = create_tween().set_parallel(true)
	for i in _rows.size():
		_inking.tween_property(_rows[i].bar, ^"fill", 1.0, ink_duration).set_delay(fade_in_duration + bar_stagger * i) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_inking.finished.connect(settled.emit)
	await dismissed


## Dismisses the reveal.
func dismiss() -> void:
	if not _live:
		return
	_live = false
	dismissed.emit()
	var tween := create_tween()
	tween.tween_property(self, ^"modulate:a", 0.0, fade_out_duration)
	tween.tween_callback(hide)


## Whether the bars are still inking in.
func is_settling() -> bool:
	return _inking != null and _inking.is_running()


## Whether the reveal is up and listening.
func is_live() -> bool:
	return _live
