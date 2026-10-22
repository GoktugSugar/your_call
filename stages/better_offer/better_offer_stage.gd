class_name BetterOfferStage
extends Stage
## The better offer: a plain button, and beside it the best life a human being has ever lived, a golden
## soul in a little crown that inks itself in while the imp sells it. Press the button and the player
## becomes that soul and stops being themselves: it hops for joy and strolls off, happy, and nobody is
## left to enjoy it. Keep their own life, and the golden soul turns away and fades.
## Stage data: [code]{"type": "better_offer", "button": "plain", "figure": "best_life", "cue": 2}[/code],
## where [code]cue[/code] is the line of the ask, counting from 1, on which the soul inks in. The option
## whose outcome has [code]press[/code] presses the button.

## The button.
@export var button: PushButton
## Where the golden soul stands.
@export var figure_spot := Vector2(760.0, 650.0)
## The kind of soul on offer when the question does not say.
@export var default_figure := &"best_life"
## How much bigger than a grown stranger the soul on offer is drawn.
@export_range(0.5, 4.0, 0.05) var figure_scale := 1.5
## Seconds the soul on offer takes to ink itself in.
@export_range(0.05, 5.0, 0.05) var figure_draw := 1.6

@export_group("Taking it")
## How high the soul hops for joy.
@export_range(0.0, 120.0, 1.0) var joy_height := 22.0
## Seconds each hop takes, up and down.
@export_range(0.05, 2.0, 0.01) var joy_time := 0.32
## How many times it hops.
@export_range(0, 6) var joy_hops := 2
## Canvas x the soul strolls off to.
@export var exit_x := -160.0
## How fast it strolls, in pixels a second.
@export_range(10.0, 2000.0, 5.0) var stroll_speed := 220.0

@export_group("Keeping your own")
## Seconds the soul takes to fade once it has turned away.
@export_range(0.05, 5.0, 0.05) var fade_time := 1.2

@export_group("Consequence")
## Seconds the stage holds once the soul has gone.
@export_range(0.0, 5.0, 0.05) var after_hold := 0.6

var _figure: Soul
var _press := -1
var _cue_line := ""
var _shown := false


func setup(for_question: QuestionData) -> void:
	super.setup(for_question)
	var data := for_question.stage
	button.look = ButtonLook.find(StringName(str(data.get("button", "plain"))))
	for i in for_question.options.size():
		if bool(for_question.options[i].outcome.get("press", false)):
			_press = i
	button.hover_changed.connect(func(hovered: bool) -> void: option_hovered.emit(_press if hovered else -1))
	button.clicked.connect(func() -> void: option_committed.emit(_press))
	var kind := SoulKind.find(StringName(str(data.get("figure", default_figure))))
	if kind == null:
		kind = SoulKind.find(&"stranger")
	_figure = kind.make()
	_figure.scale *= figure_scale
	_figure.position = figure_spot
	_figure.visible = false
	add_child(_figure)
	var cue := int(data.get("cue", 1)) - 1
	if cue >= 0 and cue < for_question.ask.size():
		_cue_line = for_question.ask[cue].id
	if dialogue != null:
		dialogue.page_shown.connect(_on_page_shown)


func set_choosing(active: bool) -> void:
	if active:
		_show_figure()
	button.live = active and _press >= 0


func highlight_option(index: int) -> void:
	button.highlighted = index >= 0 and index == _press


func play_consequence(index: int) -> StringName:
	set_choosing(false)
	button.highlighted = false
	if index == _press:
		await button.press()
		await _hop_for_joy()
		await _stroll_off()
	else:
		await _turn_away()
	await get_tree().create_timer(after_hold, false).timeout
	return &""


func option_point(index: int) -> Vector2:
	return button.press_point() if index >= 0 and index == _press else Vector2.INF


func _exit_tree() -> void:
	if dialogue != null and dialogue.page_shown.is_connected(_on_page_shown):
		dialogue.page_shown.disconnect(_on_page_shown)


## The golden soul inks itself in, once.
func _show_figure() -> void:
	if _shown:
		return
	_shown = true
	_figure.visible = true
	_figure.draw_on(figure_draw)


func _on_page_shown(line: LineData, page: int, _page_count: int) -> void:
	if line.id == _cue_line and page == 0:
		_show_figure()


func _hop_for_joy() -> void:
	var ground := _figure.position.y
	for i in joy_hops:
		var hop := create_tween()
		hop.tween_property(_figure, ^"position:y", ground - joy_height, joy_time * 0.5) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		hop.tween_property(_figure, ^"position:y", ground, joy_time * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await hop.finished


## The happy soul strolls off the page.
func _stroll_off() -> void:
	var figure := _figure as StickFigure
	if figure != null and figure.has_method(&"walk_to"):
		await figure.call(&"walk_to", exit_x, stroll_speed)
	else:
		await _figure.dissolve_away(fade_time).finished


## The soul turns its back and fades.
func _turn_away() -> void:
	var figure := _figure as StickFigure
	if figure != null:
		figure.eyes = StickFigure.Eyes.HIDDEN
	await _figure.dissolve_away(fade_time).finished
