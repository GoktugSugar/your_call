class_name SplitStage
extends StudioStage
## 6.05, split or steal: two contestants behind their podiums, a card face down on each, and the pot
## between them with its amount on the board. The left one plays the card the player tells them to (the
## option's [code]card[/code]); the right one's is drawn from what the room does, stealing the stage
## data's [code]steal[/code] share of the time. Both cards flip, and whoever came out ahead throws their
## arms open while the other hangs their head.
## Stage data: [code]{"type": "split", "steal": 47, "pot": 100000, "board": {"text": "{pot}"},
## "split_word": {"text": "split"}, "steal_word": {"text": "steal"}}[/code]. Outcomes
## [code]shared[/code], [code]robbed[/code] (the left split, the right stole), [code]took_all[/code] (the
## other way round) and [code]nothing[/code] (both stole).

## Where the two contestants stand.
@export var spots := PackedVector2Array([Vector2(660.0, 0.0), Vector2(1260.0, 0.0)])
## Where the pot stands, and how big.
@export var pot_x := 960.0
@export_range(0.2, 3.0, 0.01) var pot_scale := 0.9
## How far over the floor the cards rest, on the podiums' tops.
@export_range(0.0, 600.0, 1.0) var card_height := 108.0
## How big the cards are, and how far from each contestant toward the pot they rest, clear of them.
@export_range(0.1, 3.0, 0.01) var card_scale := 0.6
@export_range(0.0, 300.0, 1.0) var card_offset := 70.0
## How far over the floor the board over the pot sits.
@export_range(0.0, 600.0, 1.0) var board_height := 250.0
## Palette roles of the two podiums' bands, left and right.
@export var podium_roles: Array[StringName] = [&"sky", &"orange"]
## How far over the floor the confetti bursts when they share it.
@export_range(0.0, 800.0, 1.0) var confetti_height := 300.0
## Seconds a card takes to flip, and the beat between the two.
@export_range(0.05, 3.0, 0.05) var flip_time := 0.45
@export_range(0.0, 3.0, 0.05) var flip_gap := 0.6
## Seed for the right one's card. Zero draws it fresh every play.
@export var card_seed := 0
## Seconds the stage holds once both have taken it.
@export_range(0.0, 3.0, 0.05) var after_hold := 0.8

const CLEARED := preload("res://figures/poses/verdict_cleared.tres")
const GUILTY := preload("res://figures/poses/verdict_guilty.tres")

var _souls: Array[Soul] = []
var _cards: Array[InkDrawing] = []


static func fill_names() -> PackedStringArray:
	return PackedStringArray(["pot"])


func setup(for_question: QuestionData) -> void:
	super.setup(for_question)
	for i in spots.size():
		var spot := spots[i]
		_souls.append(add_contestant(&"stranger", spot.x, podium_figure_scale))
		add_podium(spot.x, podium_roles[i] if i < podium_roles.size() else &"secondary")
		var toward_pot := signf(pot_x - spot.x)
		var card := add_prop("game_card", 0.0, card_scale, Vector2(spot.x + toward_pot * card_offset, floor_y - card_height))
		if card != null:
			card.z_index = 1
		_cards.append(card)
	add_prop("money_sack", pot_x, pot_scale)
	add_board("board", Vector2(pot_x, floor_y - board_height))


func play_consequence(index: int) -> StringName:
	var left_steals := str(question.options[index].outcome.get("card", "split")) == "steal"
	var right_steals := _right_steals()
	await _flip(0, left_steals)
	await get_tree().create_timer(flip_gap, false).timeout
	await _flip(1, right_steals)
	await get_tree().create_timer(flip_gap, false).timeout
	var outcome := &"shared"
	if left_steals and right_steals:
		outcome = &"nothing"
	elif left_steals:
		outcome = &"took_all"
	elif right_steals:
		outcome = &"robbed"
	_take_it(0, outcome in [&"shared", &"took_all"])
	_take_it(1, outcome in [&"shared", &"robbed"])
	if outcome == &"shared":
		celebrate(Vector2(pot_x, floor_y - confetti_height))
	elif outcome in [&"robbed", &"nothing"]:
		lose()
	await get_tree().create_timer(after_hold, false).timeout
	return outcome


func _right_steals() -> bool:
	var rng := RandomNumberGenerator.new()
	if card_seed != 0:
		rng.seed = card_seed
	else:
		rng.randomize()
	return rng.randf() * 100.0 < float(question.stage.get("steal", 50.0))


## Turns the card at [param index] over to show steal or split.
func _flip(index: int, steal: bool) -> void:
	var card := _cards[index]
	if card == null:
		return
	var words: Variant = question.stage.get("steal_word" if steal else "split_word", {})
	var tween := create_tween()
	tween.tween_property(card, ^"flip", 0.5, flip_time * 0.5)
	await tween.finished
	card.set(&"word", str(words.get("text", "")) if words is Dictionary else "")
	card.set(&"face_up", true)
	var back := create_tween()
	back.tween_property(card, ^"flip", 1.0, flip_time * 0.5)
	await back.finished


## The contestant at [param index] takes how it came out: arms open when they won something, head hung
## when they did not.
func _take_it(index: int, won: bool) -> void:
	var figure := _souls[index] as StickFigure
	if figure != null:
		figure.blend_to(CLEARED if won else GUILTY, 0.5)
