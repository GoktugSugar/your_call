extends Node2D
## Development only: every doodle on one page, each on a baseline over its id, under a guide line at
## the tallest a doodle should stand. With [code]--stage=N[/code] it plays the doodles stage for the
## Nth sample question instead: the stage draws on, the pointer moves onto the doodle given by
## [code]--pick=N[/code] (counting from 1), clicks it, and the consequence plays.
## [codeblock]
## Godot --path . res://dev/capture_runner.tscn -- --scene=res://dev/doodle_sampler.tscn \
##     --stage=3 --pick=2 --out=C:/somewhere/shot --times=1,2.5,4
## [/codeblock]

## The doodles on the page, in order.
@export var ids: PackedStringArray = ["winged_figure", "flexing_figure", "sweet_poop", "foul_ice_cream",
		"giant_duck", "tiny_horses", "rewind_button", "pause_button", "snowflake", "sun", "third_arm_figure",
		"two_headed_figure"]
## How many doodles stand in each row.
@export_range(1, 8) var columns := 4
## Where the first doodle stands.
@export var first_spot := Vector2(300.0, 270.0)
## Distance between neighbouring doodles, across and down.
@export var spacing := Vector2(440.0, 340.0)
## Height of the guide line over each doodle: the tallest a doodle should stand.
@export_range(0.0, 600.0, 1.0) var tallest := 230.0
## Gap between a doodle's baseline and its id.
@export_range(0.0, 100.0, 1.0) var id_gap := 14.0
## Size of the ids' letters.
@export_range(8, 80) var id_font_size := 26
## Width of the guide lines.
@export_range(0.5, 8.0, 0.5) var guide_width := 1.5

@export_group("Stage")
## The doodles stage, played with [code]--stage[/code].
@export var stage_scene: PackedScene
## The sample questions: two doodle ids, then their two labels.
@export var samples: Array[PackedStringArray] = [
	PackedStringArray(["winged_figure", "flexing_figure", "Fly", "Super strength"]),
	PackedStringArray(["sweet_poop", "foul_ice_cream", "The delicious shit", "The vile ice cream"]),
	PackedStringArray(["giant_duck", "tiny_horses", "The giant duck", "The tiny horses"]),
	PackedStringArray(["rewind_button", "pause_button", "The rewind button", "The pause button"]),
	PackedStringArray(["snowflake", "sun", "Always too cold", "Always too hot"]),
	PackedStringArray(["third_arm_figure", "two_headed_figure", "A third arm", "A second head"]),
]
## Seconds between the stage being drawn on and the pointer moving onto a doodle.
@export_range(0.0, 5.0, 0.05) var point_delay := 0.6
## Seconds the pointer rests on the doodle before it clicks.
@export_range(0.0, 5.0, 0.05) var click_delay := 0.8
## Seconds the pick stays up after its consequence, before the stage leaves.
@export_range(0.0, 5.0, 0.05) var leave_delay := 1.0
## Where the dialogue box sits in the game, outlined faintly for judging the layout.
@export var dialogue_box := Rect2(370.0, 880.0, 1180.0, 166.0)

var _staging := false


func _ready() -> void:
	var args := DevArgs.parse()
	_staging = args.has("stage")
	if _staging:
		var sample := samples[clampi(int(args["stage"]) - 1, 0, samples.size() - 1)]
		_play_stage(sample, clampi(int(args.get("pick", "1")) - 1, 0, 1))
	else:
		_lay_out_page()
	queue_redraw()


func _draw() -> void:
	var guide := InkPalette.get_default().faded
	if _staging:
		draw_rect(dialogue_box, guide, false, guide_width)
		return
	for i in ids.size():
		var spot := _spot(i)
		var half := spacing.x * 0.5
		draw_line(spot + Vector2(-half, 0.0), spot + Vector2(half, 0.0), guide, guide_width)
		draw_line(spot + Vector2(-half, -tallest), spot + Vector2(half, -tallest), guide, guide_width)


func _lay_out_page() -> void:
	for i in ids.size():
		var spot := _spot(i)
		var doodle := DoodlesStage.make_doodle(ids[i])
		if doodle == null:
			push_error("doodle sampler: no doodle '%s'" % ids[i])
		else:
			doodle.position = spot
			add_child(doodle)
		var label := Label.new()
		label.text = ids[i]
		label.add_theme_font_size_override(&"font_size", id_font_size)
		label.add_theme_color_override(&"font_color", InkPalette.get_default().muted)
		add_child(label)
		label.reset_size()
		label.position = spot + Vector2(-label.size.x * 0.5, id_gap)


func _spot(index: int) -> Vector2:
	return first_spot + Vector2(index % columns, floori(index / float(columns))) * spacing


func _play_stage(sample: PackedStringArray, pick: int) -> void:
	var question := QuestionData.new()
	question.id = &"sample"
	question.stage = {"type": "doodles", "doodles": [sample[0], sample[1]]}
	for label in sample.slice(2):
		var option := OptionData.new()
		option.label = label
		question.options.append(option)
	var stage := stage_scene.instantiate() as DoodlesStage
	add_child(stage)
	stage.setup(question)
	await stage.enter()
	stage.set_choosing(true)
	await get_tree().create_timer(point_delay).timeout
	var at := get_viewport().get_screen_transform() * stage.option_point(pick)
	_point(at)
	await get_tree().create_timer(click_delay).timeout
	_click(at)
	var picked: int = await stage.option_committed
	stage.set_choosing(false)
	await stage.play_consequence(picked)
	await get_tree().create_timer(leave_delay).timeout
	await stage.leave()


func _point(at: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	Input.parse_input_event(motion)


func _click(at: Vector2) -> void:
	for pressed: bool in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		click.position = at
		click.global_position = at
		Input.parse_input_event(click)
