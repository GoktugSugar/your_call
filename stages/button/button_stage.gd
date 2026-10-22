class_name ButtonStage
extends Stage
## One push button, alone on the page. The option whose outcome has [code]press[/code] presses it; the
## other leaves it be. Stage data: [code]{"type": "button", "button": "plain"}[/code], where
## [code]button[/code] names the button's look.
## With [code]"comes_alive": true[/code] the button is the walking button, dormant: pressed, it wakes
## with a start, says the stage's first line with a fist shaken at the player, gets up, and stomps off
## saying the second. Its lines are the stage data's [code]says[/code], spoken by the button.

## The button.
@export var button: PushButton
## The walking button, for a button that comes alive.
@export var walker_scene: PackedScene

@export_group("Coming alive")
## The arm pose it yelps with.
@export var yelp_arms: ButtonArmPose
## The arm pose it stomps off with.
@export var stomp_arms: ButtonArmPose
## Seconds it holds its yelp before it gets up.
@export_range(0.0, 5.0, 0.05) var yelp_hold := 2.2
## Which way it stomps off: -1 left, 1 right. The imp stands to the right.
@export_range(-1, 1) var exit_direction := -1

@export_group("Consequence")
## Seconds the stage holds after the button is pressed or left.
@export_range(0.0, 5.0, 0.05) var after_hold := 1.0

var _press := -1
var _walker: WalkingButton


func setup(for_question: QuestionData) -> void:
	super.setup(for_question)
	var look := ButtonLook.find(StringName(str(for_question.stage.get("button", "plain"))))
	if bool(for_question.stage.get("comes_alive", false)) and walker_scene != null:
		_walker = walker_scene.instantiate() as WalkingButton
		_walker.position = button.position
		add_child(_walker)
		button.queue_free()
		button = _walker.body
	button.look = look
	for i in for_question.options.size():
		if bool(for_question.options[i].outcome.get("press", false)):
			_press = i
	button.hover_changed.connect(func(hovered: bool) -> void: option_hovered.emit(_press if hovered else -1))
	button.clicked.connect(func() -> void: option_committed.emit(_press))


func set_choosing(active: bool) -> void:
	button.live = active and _press >= 0


func highlight_option(index: int) -> void:
	button.highlighted = index >= 0 and index == _press


func play_consequence(index: int) -> StringName:
	set_choosing(false)
	button.highlighted = false
	if index == _press:
		await button.press()
		if _walker != null:
			await _come_alive()
	await get_tree().create_timer(after_hold, false).timeout
	return &""


func option_point(index: int) -> Vector2:
	return button.press_point() if index >= 0 and index == _press else Vector2.INF


## The button wakes with a start, swears at the player, gets up and stomps off, muttering.
func _come_alive() -> void:
	var said := question.stage_lines
	await _walker.wake()
	if said.size() > 0:
		_walker.say(said[0].text)
	if yelp_arms != null:
		_walker.hold_arms(yelp_arms)
	await get_tree().create_timer(yelp_hold, false).timeout
	await _walker.stand_up()
	if stomp_arms != null:
		_walker.hold_arms(stomp_arms)
	if said.size() > 1:
		_walker.say(said[1].text)
	await _walker.walk_off(exit_direction)
