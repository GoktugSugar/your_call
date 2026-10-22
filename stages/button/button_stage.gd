class_name ButtonStage
extends Stage
## One push button, alone on the page. The option whose outcome has [code]press[/code] presses it; the
## other leaves it be. Stage data: [code]{"type": "button", "button": "plain"}[/code], where
## [code]button[/code] names the button's look.

## The button.
@export var button: PushButton

@export_group("Consequence")
## Seconds the stage holds after the button is pressed or left.
@export_range(0.0, 5.0, 0.05) var after_hold := 1.0

var _press := -1


func setup(for_question: QuestionData) -> void:
	super.setup(for_question)
	button.look = ButtonLook.find(StringName(str(for_question.stage.get("button", "plain"))))
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
	await get_tree().create_timer(after_hold, false).timeout
	return &""


func option_point(index: int) -> Vector2:
	return button.press_point() if index >= 0 and index == _press else Vector2.INF
