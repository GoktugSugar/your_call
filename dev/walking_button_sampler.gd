extends Node2D
## Development only: the walking button on its own. A dormant green button is pressed, wakes with a
## start, swears where it sits, gets up and stomps off to the left, muttering. Up the page, buttons
## already alive stand about in each arm pose, one shaking its fist, so the poses can be judged side by side.
## With [code]--walk[/code] the button starts alive and sets straight off, to judge the gait, and
## [code]--slow=S[/code] runs the walk at S times its speed, so a burst of screenshots catches every step.
## [codeblock]
## Godot --path . res://dev/capture_runner.tscn -- --scene=res://dev/walking_button_sampler.tscn --out=C:/somewhere/shot --times=1,3,5
## [/codeblock]

## The walking button scene.
@export var walker_scene: PackedScene
## The arm poses up the page, by name.
@export var poses: PackedStringArray = ["rest", "fist", "hips", "shrug", "startled"]
## Which way each posing button faces, in the same order: -1 left, 0 out of the page, 1 right.
@export var pose_facings: PackedInt32Array = [0, 1, -1, 0, 0]
## Where the first posing button stands.
@export var first_spot := Vector2(330.0, 430.0)
## Distance between neighbouring posing buttons.
@export_range(50.0, 600.0, 1.0) var spacing := 315.0
## Size of the posing buttons.
@export_range(0.1, 2.0, 0.01) var pose_scale := 0.75
## Where the button that comes alive starts.
@export var star_spot := Vector2(1240.0, 940.0)
## What it swears as it wakes.
@export var first_line := "Ow! Fuck. That actually hurt, you absolute prick."
## How it holds its arms while it swears, by name.
@export var swearing_pose := &"shrug"
## What it mutters as it goes.
@export var second_line := "Unbelievable. I did nothing to you. Nothing."
## Seconds before it is pressed.
@export_range(0.0, 5.0, 0.05) var press_delay := 0.8
## Seconds the swearing hangs there before it gets up.
@export_range(0.0, 5.0, 0.05) var sink_in := 0.6
## Seconds it stands before it storms off.
@export_range(0.0, 5.0, 0.05) var stand_beat := 0.6
## Gap between a posing button's feet and its name.
@export_range(0.0, 100.0, 1.0) var name_gap := 14.0
## Size of the names' letters.
@export_range(8, 80) var name_size := 26


func _ready() -> void:
	for i in poses.size():
		var poser := _walker(Vector2(first_spot.x + spacing * i, first_spot.y), pose_scale)
		poser.alive = true
		poser.facing = pose_facings[i] if i < pose_facings.size() else 0
		poser.hold_arms(ButtonArmPose.find(poses[i]))
		_name(poses[i], poser.position)
	var star := _walker(star_spot, 1.0)
	await get_tree().create_timer(press_delay).timeout
	var args := DevArgs.parse()
	if args.has("walk"):
		Engine.time_scale = String(args.get("slow", "1")).to_float()
		star.alive = true
		star.say(second_line)
		await star.walk_off(-1)
		return
	await star.body.press()
	await star.wake()
	star.hold_arms(ButtonArmPose.find(swearing_pose))
	await star.say(first_line)
	await get_tree().create_timer(sink_in).timeout
	star.hold_arms(star.rest_arms)
	await star.stand_up()
	star.fade_words()
	await get_tree().create_timer(stand_beat).timeout
	star.say(second_line)
	await star.walk_off(-1)


func _walker(at: Vector2, size: float) -> WalkingButton:
	var walker := walker_scene.instantiate() as WalkingButton
	walker.position = at
	walker.scale = Vector2.ONE * size
	add_child(walker)
	return walker


func _name(text: String, under: Vector2) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override(&"font_size", name_size)
	label.add_theme_color_override(&"font_color", InkPalette.get_default().secondary)
	add_child(label)
	label.reset_size()
	label.position = under + Vector2(-label.size.x * 0.5, name_gap)
