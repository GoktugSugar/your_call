class_name DoodlesStage
extends Stage
## A quick would you rather: two small ink doodles side by side, each over its option's label, with
## "or" between them. Pointing at a doodle lifts it and lights its label, and clicking it picks it.
## On the pick an amber loop circles the chosen doodle, the other one dissolves, and the pick hops once.
## Stage data: [code]{"type": "doodles", "doodles": [id_a, id_b]}[/code]. Option 0 goes with the first
## doodle, on the left, and option 1 with the second, on the right. Each id names a doodle's script
## in [code]res://doodles/[/code].

## Path pattern of a doodle's script, filled with the doodle's id.
const DOODLE_SCRIPT := "res://doodles/%s.gd"

## Where each doodle stands, left then right. A doodle's origin goes on its slot's origin.
@export var slots: Array[Node2D] = []
## The label under each doodle, left then right.
@export var words: Array[ChoiceWord] = []
## The "or" between the two.
@export var or_label: Label
## The amber loop drawn around the pick. It stays hidden until then.
@export var flourish: InkDrawing

@export_group("Labels")
## Gap between a doodle's baseline and the top of its label.
@export_range(0.0, 200.0, 1.0) var label_gap := 12.0
## Size of the labels' letters.
@export_range(8, 120, 1) var label_font_size := 40
## Size of the "or".
@export_range(8, 120, 1) var or_font_size := 36
## How far above the baseline the middle of the "or" sits.
@export_range(-200.0, 400.0, 1.0) var or_height := 96.0
## Palette role of the "or".
@export var or_role := &"muted"

@export_group("Pointing")
## The area around each slot that catches the pointer, in the slot's space: the doodle and its label.
@export var hit_area := Rect2(-200.0, -250.0, 400.0, 330.0)
## How far a doodle rises while it is pointed at.
@export_range(0.0, 60.0, 0.5) var lift_height := 10.0
## Seconds a doodle takes to rise or settle.
@export_range(0.0, 1.0, 0.01) var lift_duration := 0.12

@export_group("Flourish")
## The middle of the loop, in the slot's space.
@export var flourish_center := Vector2(0.0, -70.0)
## Half the loop's width and height.
@export var flourish_radii := Vector2(228.0, 196.0)
## How many times round the loop goes. A little over once, as a hand overshoots.
@export_range(0.5, 3.0, 0.01) var flourish_turns := 1.12
## Where the loop starts, in degrees clockwise from the right. It runs anticlockwise from there.
@export_range(-360.0, 360.0, 1.0) var flourish_start_angle := -100.0
## How much wider the loop is at its end than at its start, as a share of its size, so the
## overshoot does not retrace the start.
@export_range(0.0, 0.5, 0.005) var flourish_spread := 0.06
## How far the loop is tilted, in degrees.
@export_range(-45.0, 45.0, 0.5) var flourish_tilt := -4.0
## Points per turn of the loop, before it is smoothed.
@export_range(8, 128, 1) var flourish_points := 36
## Width of the loop, as a multiple of the style's line width.
@export_range(0.2, 4.0, 0.05) var flourish_width := 1.3
## Palette role of the loop.
@export var flourish_role := &"amber"

@export_group("Consequence")
## Seconds the loop takes to draw itself on.
@export_range(0.05, 3.0, 0.01) var flourish_duration := 0.8
## Seconds the other doodle, its label and the "or" take to dissolve.
@export_range(0.05, 3.0, 0.01) var fade_duration := 0.6
## How high the pick hops.
@export_range(0.0, 80.0, 0.5) var bounce_height := 16.0
## Seconds the hop takes, up and back down.
@export_range(0.05, 2.0, 0.01) var bounce_duration := 0.45
## Seconds the pick holds still after its hop, before the consequence is over.
@export_range(0.0, 3.0, 0.01) var hold_duration := 0.7

const _DOODLES_KEY := "doodles"

## The doodle in each slot, or null where there is none.
var _doodles: Array[InkDrawing] = []
## Whether each doodle is lifted.
var _lifted: Array[bool] = []
var _lift_tweens: Array[Tween] = []
var _live := false
## The side under the pointer, or -1.
var _pointed := -1
## The side lit from the choice row, or -1.
var _highlighted := -1


## A new doodle drawn by the script for [param id], or null when there is no such doodle.
static func make_doodle(id: String) -> InkDrawing:
	var path := DOODLE_SCRIPT % id
	var script := load(path) as GDScript if ResourceLoader.exists(path) else null
	if script == null or not script.can_instantiate():
		return null
	var made: Object = script.new()
	if made is InkDrawing:
		return made as InkDrawing
	if made is Node:
		(made as Node).free()
	return null


func setup(for_question: QuestionData) -> void:
	super.setup(for_question)
	var ids: Array = for_question.stage.get(_DOODLES_KEY, [])
	var labels := for_question.option_labels()
	_doodles.clear()
	_lifted.clear()
	_lift_tweens.clear()
	for i in slots.size():
		var doodle: InkDrawing = null
		if i < ids.size():
			doodle = make_doodle(str(ids[i]))
			if doodle == null:
				push_warning("Doodles stage: no doodle '%s' in %s." % [ids[i], DOODLE_SCRIPT % ids[i]])
			else:
				slots[i].add_child(doodle)
		_doodles.append(doodle)
		_lifted.append(false)
		_lift_tweens.append(null)
		_place_word(words[i], labels[i] if i < labels.size() else "", slots[i].position)
	_place_or()


func enter() -> void:
	var fade := create_tween().set_parallel(true)
	for item in _lettering():
		item.modulate.a = 0.0
		fade.tween_property(item, ^"modulate:a", 1.0, enter_duration)
	await super.enter()


## Turning the doodles off leaves them as they are, so the pick does not flicker before its consequence.
func set_choosing(active: bool) -> void:
	_live = active
	if not active and _pointed >= 0:
		_pointed = -1
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		option_hovered.emit(-1)


func highlight_option(index: int) -> void:
	_highlighted = index
	_refresh()


func play_consequence(index: int) -> StringName:
	set_choosing(false)
	if index < 0 or index >= slots.size():
		return &""
	_highlighted = -1
	words[index].look = ChoiceWord.Look.PICKED
	var fade := create_tween().set_parallel(true)
	fade.tween_property(or_label, ^"modulate:a", 0.0, fade_duration)
	for side in slots.size():
		if side == index:
			continue
		words[side].look = ChoiceWord.Look.PASSED
		fade.tween_property(words[side], ^"modulate:a", 0.0, fade_duration)
		if _doodles[side] != null:
			fade.tween_property(_doodles[side], ^"dissolve", 1.0, fade_duration)
	await _circle(index)
	await _hop(index)
	if fade.is_running():
		await fade.finished
	await get_tree().create_timer(hold_duration, false).timeout
	return &""


func leave() -> void:
	var fade := create_tween().set_parallel(true)
	for item in _lettering():
		fade.tween_property(item, ^"modulate:a", 0.0, leave_duration)
	await super.leave()


## The middle of the doodle for [param index] on the canvas, where a pointer would point at it.
func option_point(index: int) -> Vector2:
	if index < 0 or index >= _doodles.size() or _doodles[index] == null:
		return Vector2.INF
	return slots[index].get_global_transform_with_canvas() * hit_area.get_center()


func _unhandled_input(event: InputEvent) -> void:
	if not _live or not event is InputEventMouse:
		return
	var over := _side_at(event as InputEventMouse)
	if event is InputEventMouseMotion:
		_set_pointed(over)
	elif over >= 0 and event.is_action_pressed(&"pick"):
		get_viewport().set_input_as_handled()
		option_committed.emit(over)


## The side whose doodle is under [param event]'s pointer, or -1.
func _side_at(event: InputEventMouse) -> int:
	for side in slots.size():
		if _doodles[side] != null and hit_area.has_point((slots[side].make_input_local(event) as InputEventMouse).position):
			return side
	return -1


func _set_pointed(side: int) -> void:
	if side == _pointed:
		return
	_pointed = side
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if side >= 0 else Input.CURSOR_ARROW)
	_refresh()
	option_hovered.emit(side)


func _refresh() -> void:
	for side in slots.size():
		_lift(side, side == _pointed or side == _highlighted)


func _lift(side: int, lifted: bool) -> void:
	if lifted == _lifted[side]:
		return
	_lifted[side] = lifted
	words[side].look = ChoiceWord.Look.LIFTED if lifted else ChoiceWord.Look.RESTING
	var doodle := _doodles[side]
	if doodle == null:
		return
	_stop_lift(side)
	_lift_tweens[side] = create_tween()
	_lift_tweens[side].tween_property(doodle, ^"position:y", -lift_height if lifted else 0.0, lift_duration) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _stop_lift(side: int) -> void:
	if _lift_tweens[side] != null and _lift_tweens[side].is_valid():
		_lift_tweens[side].kill()


## Draws the amber loop on around the doodle on [param side].
func _circle(side: int) -> void:
	var stroke := InkStroke.new()
	stroke.points = _loop_points(flourish.to_local(slots[side].to_global(flourish_center)))
	stroke.width_scale = flourish_width
	stroke.color_role = flourish_role
	flourish.strokes = [stroke]
	flourish.visible = true
	await flourish.draw_on(flourish_duration).finished


## The loop's path around [param center]: a little over one anticlockwise turn of a tilted ellipse
## that widens as it goes.
func _loop_points(center: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	var count := maxi(1, ceili(flourish_points * flourish_turns))
	var start := deg_to_rad(flourish_start_angle)
	var tilt := deg_to_rad(flourish_tilt)
	for i in count + 1:
		var along := float(i) / count
		var angle := start - TAU * flourish_turns * along
		var radii := flourish_radii * (1.0 + flourish_spread * (along - 0.5))
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y).rotated(tilt))
	return points


## The doodle on [param side] hops once and lands back on the baseline.
func _hop(side: int) -> void:
	var doodle := _doodles[side]
	if doodle == null:
		return
	_stop_lift(side)
	var half := bounce_duration * 0.5
	var hop := create_tween()
	hop.tween_property(doodle, ^"position:y", -bounce_height, half).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	hop.tween_property(doodle, ^"position:y", 0.0, half).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await hop.finished


## Shows [param text] in [param word], centred under the baseline point [param under].
func _place_word(word: ChoiceWord, text: String, under: Vector2) -> void:
	word.text = text
	word.mouse_filter = Control.MOUSE_FILTER_IGNORE
	word.add_theme_font_size_override(&"font_size", label_font_size)
	word.reset_size()
	word.position = under + Vector2(-word.size.x * 0.5, label_gap)


## Centres the "or" between the slots, at [member or_height] above their baseline.
func _place_or() -> void:
	or_label.add_theme_font_size_override(&"font_size", or_font_size)
	or_label.add_theme_color_override(&"font_color", InkPalette.get_default().color(or_role))
	or_label.reset_size()
	var middle := Vector2.ZERO
	for slot in slots:
		middle += slot.position / slots.size()
	or_label.position = middle - Vector2(0.0, or_height) - or_label.size * 0.5


## The labels and the "or", which fade in and out with the doodles.
func _lettering() -> Array[CanvasItem]:
	var items: Array[CanvasItem] = [or_label]
	for word in words:
		items.append(word)
	return items
