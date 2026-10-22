class_name GambleStage
extends Stage
## The coordination gamble: two buttons, and between them the soul whose fate the player decides.
## A seeded room of the newly dead has already voted. Pressing the gamble's button stakes the soul on
## the room: it lives only if more of the room pressed that button than the line. The other button
## keeps it alive whatever the room did. A soul that lives walks out; one the room lets down folds.
## Stage data: [code]{"type": "gamble", "line": 50, "random": 50, "soul": "stranger"}[/code].
## Each option's outcome names its button's look, [code]{"button": "blue", "gamble": true}[/code], and
## the buttons stand left to right in option order. The gamble option's crowd is the room's seeded
## share; [code]random[/code] is the share of the room that presses at random instead, drawn again
## every play, so the room's vote can swing.
## Outcomes: [code]lives[/code] or [code]dies[/code].

## The push button each option is pressed with.
@export var button_scene: PackedScene
## Where the buttons stand, left to right, in option order.
@export var button_spots := PackedVector2Array([Vector2(700.0, 650.0), Vector2(1220.0, 650.0)])
## Where the soul stands.
@export var soul_spot := Vector2(960.0, 650.0)
## The kind of soul at stake when the question does not say.
@export var default_soul := &"stranger"

@export_group("The room")
## The line the room must pass, as a share, when the question does not say.
@export_range(0.0, 100.0, 0.5) var default_line := 50.0
## Seed for how the random part of the room votes. Zero draws a new vote every play.
@export var room_seed := 0

@export_group("Consequence")
## Seconds the room takes to be counted after a gamble, while the soul glances about.
@export_range(0.0, 5.0, 0.05) var counting := 1.4
## How far the soul's head turns as it glances about, in degrees.
@export_range(0.0, 45.0, 0.5) var glance_tilt := 14.0
## Seconds each glance takes.
@export_range(0.05, 2.0, 0.01) var glance_time := 0.35
## Canvas x the soul walks out to when it lives.
@export var exit_x := -120.0
## How fast the soul walks out, in pixels a second.
@export_range(10.0, 2000.0, 5.0) var walk_speed := 260.0
## Seconds the stage holds after the soul has gone.
@export_range(0.0, 3.0, 0.05) var after_hold := 0.4

var _buttons: Array[PushButton] = []
var _soul: Soul
## The share of the room that pressed the gamble's button, drawn once per play.
var _room_share := 0.0
var _line := 50.0
var _gamble := -1


func setup(for_question: QuestionData) -> void:
	super.setup(for_question)
	var data := for_question.stage
	_line = float(data.get("line", default_line))
	for i in for_question.options.size():
		var option := for_question.options[i]
		var button := button_scene.instantiate() as PushButton
		button.look = ButtonLook.find(StringName(str(option.outcome.get("button", "plain"))))
		button.position = button_spots[mini(i, button_spots.size() - 1)]
		add_child(button)
		button.hover_changed.connect(func(hovered: bool) -> void: option_hovered.emit(i if hovered else -1))
		button.clicked.connect(func() -> void: option_committed.emit(i))
		_buttons.append(button)
		if bool(option.outcome.get("gamble", false)):
			_gamble = i
	var kind := SoulKind.find(StringName(str(data.get("soul", default_soul))))
	if kind == null:
		kind = SoulKind.find(default_soul)
	_soul = kind.make()
	_soul.position = soul_spot
	add_child(_soul)
	_room_share = _draw_room(float(data.get("random", 0.0)))


func set_choosing(active: bool) -> void:
	for button in _buttons:
		button.live = active


func highlight_option(index: int) -> void:
	for i in _buttons.size():
		_buttons[i].highlighted = i == index


func play_consequence(index: int) -> StringName:
	set_choosing(false)
	highlight_option(-1)
	await _buttons[index].press()
	var lives := true
	if index == _gamble:
		await _glance_about()
		lives = _room_share > _line
	if lives:
		await _walk_out()
	else:
		await _soul.fold(1.0)
	await get_tree().create_timer(after_hold, false).timeout
	return &"lives" if lives else &"dies"


## The room's vote: the gamble's button against the other, in their own colours, with the line it had to pass.
func reveal_split(pick: int) -> RevealSplit:
	var split := super.reveal_split(pick)
	for i in split.shares.size():
		split.shares[i] = _room_share if i == _gamble else 100.0 - _room_share
		split.roles.append(_buttons[i].look.cap_role if _buttons[i].look != null else &"")
	split.mark = _line
	return split


func option_point(index: int) -> Vector2:
	return _buttons[index].press_point() if index >= 0 and index < _buttons.size() else Vector2.INF


## The share of the room that pressed the gamble's button: its seeded share, with [param random]
## percent of the room pressing at random instead.
func _draw_room(random: float) -> float:
	var seeded := question.options[_gamble].crowd if _gamble >= 0 else 0.0
	if random <= 0.0:
		return seeded
	var rng := RandomNumberGenerator.new()
	if room_seed != 0:
		rng.seed = room_seed
	else:
		rng.randomize()
	var share := random / 100.0
	return seeded * (1.0 - share) + rng.randf() * 100.0 * share


## The soul glances one way and the other while the room is counted.
func _glance_about() -> void:
	var figure := _soul as StickFigure
	if figure == null or figure.pose == null:
		await get_tree().create_timer(counting, false).timeout
		return
	var rest := figure.pose
	var glances := maxi(1, floori(counting / (glance_time * 2.0)))
	for i in glances:
		var glance := rest.duplicate() as FigurePose
		glance.head_tilt = glance_tilt * (1.0 if i % 2 == 0 else -1.0)
		await figure.blend_to(glance, glance_time).finished
	await figure.blend_to(rest, glance_time).finished


## The soul walks out of the room, off the side of the page.
func _walk_out() -> void:
	var figure := _soul as StickFigure
	if figure != null and figure.has_method(&"walk_to"):
		await figure.call(&"walk_to", exit_x, walk_speed)
	else:
		await _soul.dissolve_away(leave_duration).finished
