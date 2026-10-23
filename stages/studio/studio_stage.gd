class_name StudioStage
extends Stage
## The studio of The Show, under every one of its rounds: a curtain valance across the top of the page,
## the stage floor, and the studio audience seen from behind along the foot of the page, swaying with the
## boil and clapping on cue. A round extends this and stages its own act on the floor.
## The room votes in every round. Its share for the first option is that option's seeded crowd, with
## [code]random[/code] percent of the room voting at random instead, drawn once each play
## ([method room_share]); the room picks the first option when that share passes [code]line[/code].
## The reveal shows the room's vote as it fell, with the line marked when the question names one.
## Stage data: [code]{"random": 40, "line": 50}[/code] and each round's own. A round's boards, such as
## a prize, are words in its data (a [code]text[/code]) with [code]{prize}[/code] or [code]{pot}[/code]
## filled in as money.

@export_group("Studio")
## Where the stage floor runs across the page: the ground every contestant stands on.
@export_range(0.0, 1080.0, 1.0) var floor_y := 700.0
## How much bigger than on the tracks the contestants stand, the studio being nearer.
@export_range(0.5, 3.0, 0.01) var figure_scale := 1.45
## Size of the words on the studio's boards, such as a prize.
@export_range(8, 200) var board_size := 50
## Palette role of the words on the boards.
@export var board_role := &"amber"
## Seconds the boards take to fade in and out with the stage.
@export_range(0.0, 3.0, 0.05) var board_fade := 0.4

@export_group("The room")
## The line the room must pass, as a share, when the question does not say.
@export_range(0.0, 100.0, 0.5) var default_line := 50.0
## Seed for how the random part of the room votes. Zero draws a new vote every play.
@export var room_seed := 0
## Seconds the room takes to vote, the audience bobbing while it is counted.
@export_range(0.0, 5.0, 0.05) var counting := 1.3

## The valance across the top of the page.
var valance: StudioValance
## The floor, drawn in front of the contestants.
var studio_floor: StudioFloor
## The audience along the foot of the page.
var audience: Audience

## The room's share for the first option, drawn once each play. Below 0 until it is drawn.
var _room := -1.0
var _boards: Array[Label] = []


func setup(for_question: QuestionData) -> void:
	super.setup(for_question)
	valance = StudioValance.new()
	valance.z_index = -1
	add_child(valance)
	studio_floor = StudioFloor.new()
	studio_floor.position = Vector2(0.0, floor_y)
	studio_floor.z_index = 2
	add_child(studio_floor)
	audience = Audience.new()
	audience.z_index = 3
	add_child(audience)


## The studio and the round's act draw on, and the boards fade in.
func enter() -> void:
	for board in _boards:
		create_tween().tween_property(board, ^"modulate:a", 1.0, board_fade).from(0.0)
	await super.enter()


## The boards fade as everything else dissolves.
func leave() -> void:
	for board in _boards:
		create_tween().tween_property(board, ^"modulate:a", 0.0, board_fade)
	await super.leave()


## The room's share for the first option: its seeded crowd, with the stage's [code]random[/code] share
## of the room voting at random instead. Drawn once each play.
func room_share() -> float:
	if _room >= 0.0:
		return _room
	var seeded := question.options[0].crowd if not question.options.is_empty() else 0.0
	var random := float(question.stage.get("random", 0.0)) / 100.0
	var rng := RandomNumberGenerator.new()
	if room_seed != 0:
		rng.seed = room_seed
	else:
		rng.randomize()
	_room = clampf(seeded * (1.0 - random) + rng.randf() * 100.0 * random, 0.0, 100.0)
	return _room


## The share the room's vote for the first option must pass.
func room_line() -> float:
	return float(question.stage.get("line", default_line))


## Whether the room picks the first option.
func room_picks_first() -> bool:
	return room_share() > room_line()


## The room votes: the audience bobs while it is counted.
func count_votes() -> void:
	audience.clap(counting)
	await get_tree().create_timer(counting, false).timeout


## A soul of the kind [param kind_id] standing on the floor at [param x], at the studio's size.
func add_contestant(kind_id: StringName, x: float) -> Soul:
	var kind := SoulKind.find(kind_id)
	if kind == null:
		kind = SoulKind.find(&"stranger")
	var soul := kind.make()
	soul.scale *= figure_scale
	soul.position = Vector2(x, floor_y)
	add_child(soul)
	return soul


## The doodle [param id] standing on the floor at [param x] (or at [param at] when it is given), at
## [param size] times its own size. Null when there is no such doodle yet, so a round still plays.
func add_prop(id: String, x: float, size := 1.0, at := Vector2.INF) -> InkDrawing:
	var prop := DoodlesStage.make_doodle(id)
	if prop == null:
		push_warning("Studio: no doodle '%s' yet" % id)
		return null
	prop.scale = Vector2.ONE * size
	prop.position = at if at.is_finite() else Vector2(x, floor_y)
	add_child(prop)
	return prop


## Hops [param node] up by [param height] and back down over [param seconds].
func hop(node: Node2D, height: float, seconds: float) -> void:
	if node == null:
		return
	var ground := node.position.y
	var tween := create_tween()
	tween.tween_property(node, ^"position:y", ground - height, seconds * 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, ^"position:y", ground, seconds * 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished


## A board of words centred on [param at], from the stage data's [param key] (its [code]text[/code],
## filled), in the board colour. It fades in and out with the stage. Null when the data has none.
func add_board(key: String, at: Vector2) -> Label:
	var data: Variant = question.stage.get(key)
	if not data is Dictionary or not data.has("text"):
		return null
	var board := Label.new()
	board.add_theme_font_size_override(&"font_size", board_size)
	board.add_theme_color_override(&"font_color", InkPalette.get_default().color(board_role))
	board.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.modulate.a = 0.0
	board.z_index = 4
	add_child(board)
	_boards.append(board)
	set_board(board, str(data["text"]).format(fills()), at)
	return board


## Sets [param board] to [param text], centred on [param at].
func set_board(board: Label, text: String, at: Vector2) -> void:
	board.text = text
	board.size = board.get_combined_minimum_size()
	board.position = at - board.size * 0.5


## The amounts the boards show, as money.
func fills() -> Dictionary:
	var values := {}
	for key: String in ["prize", "pot"]:
		if question.stage.has(key):
			values[key] = Numbers.money(int(question.stage[key]))
	return values


## The room's vote as it fell, the first option's share against the rest, with the line it had to
## pass when the question names one.
func reveal_split(pick: int) -> RevealSplit:
	var split := super.reveal_split(pick)
	if split.shares.size() == 2:
		split.shares[0] = room_share()
		split.shares[1] = 100.0 - room_share()
	if split.mark_label != "":
		split.mark = room_line()
	return split
