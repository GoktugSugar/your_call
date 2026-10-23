class_name AuctionStage
extends ShopStage
## The cigarette auction: a shop with a rival. Try to buy the thing and the walking button waddles in to
## bid against the player, always a step over them; the price tag climbs with every bid, but no money
## ever moves. Dropping out lets the button walk off with it. Bidding on past all sense fires the
## question's ending: the imp cuts in, and the button takes the thing and goes. Stage data, beside the
## shop's [code]item[/code] and [code]price[/code]:
## [codeblock]
## {"type": "auction", "item": "cigarette_pack", "price": 20, "step": 10, "persist": 3,
##  "bid": {"label": "Bid {bid}"}, "drop": {"label": "Drop out"}}
## [/codeblock]
## [code]persist[/code] counts the player's bids, the first one included, that fire the ending. The
## button says the question's [code]arrive[/code] lines as it comes in, its [code]taunts[/code] one a
## round, in order and round again, [code]won[/code] when the player drops out and [code]gloat[/code] when
## it takes the thing at the end; the imp cuts in with [code]stop[/code], which moves on by itself.
## The option whose outcome has [code]buy[/code] buys and then bids; the other passes and then drops out.
## Outcomes: [code]auction[/code] when the button comes in, [code]bid[/code] for each bid it answers,
## [code]cursed[/code] for the bid that goes past all sense, [code]dropped[/code], [code]passed[/code], and
## [code]broke[/code] when there is not even the money to start.
## Placeholders: [code]{price}[/code] the asking price, [code]{rival}[/code] the button's bid now and
## [code]{bid}[/code] what the player would bid over it.

## The walking button that bids against the player.
@export var walker_scene: PackedScene
## The look of its cap, by name: the green of 2.11.
@export var walker_look := &"green"

@export_group("Rival")
## Where it comes in from, past the edge of the canvas: away from the imp's wing.
@export_range(-600.0, 2600.0, 1.0) var walker_from := -140.0
## Where it stops to bid.
@export_range(0.0, 1920.0, 1.0) var walker_spot := 470.0
## Which way it leaves with its prize: -1 left, 1 right.
@export_range(-1, 1) var exit_direction := -1
## How it holds its arms while it bids.
@export var bidding_arms: ButtonArmPose
## Where it carries the thing it won, from its origin.
@export var carry_offset := Vector2(86.0, -96.0)
## How big the thing is while it is carried.
@export_range(0.1, 2.0, 0.01) var carry_scale := 0.5
## Seconds the thing takes to go into its hands.
@export_range(0.05, 2.0, 0.01) var grab_duration := 0.35
## Seconds between one of its lines being said and the next thing happening.
@export_range(0.0, 3.0, 0.01) var beat := 0.35

var _rival_bid := 0
## How many times the player has bid, the first try to buy included.
var _bids := 0
var _persist := 3
var _bid_text := "Bid {bid}"
var _drop_text := "Drop out"
var _walker: WalkingButton


func setup(for_question: QuestionData) -> void:
	super.setup(for_question)
	var data := for_question.stage
	# The asking price is not the shop's price per unit: an auction never sells more than one.
	_step = int(data.get("step", 0))
	_persist = maxi(int(data.get("persist", 3)), 1)
	for key: String in ["bid", "drop"]:
		var entry: Variant = data.get(key, {})
		if entry is Dictionary and entry.has("label"):
			if key == "bid":
				_bid_text = str(entry["label"])
			else:
				_drop_text = str(entry["label"])
	tally.visible = false


func play_consequence(index: int) -> StringName:
	set_choosing(false)
	_highlighted = false
	_lift(false)
	_another = false
	if _bids == 0:
		return await _open(index == _buy)
	if index != _buy:
		await _let_it_win(&"won")
		return &"dropped"
	_bids += 1
	_price = _rival_bid + _step
	_refresh()
	await _hop()
	if _bids >= _persist:
		await _cut_in()
		await _let_it_win(&"gloat")
		return &"cursed"
	await get_tree().create_timer(beat, false).timeout
	await _rival_bids()
	_another = true
	return &"bid"


## The first round: passing, trying without the money, or the first bid, which brings the rival in.
func _open(buying: bool) -> StringName:
	if not buying:
		await _fade_offer()
		await _hold()
		return &"passed"
	if not _wallet.can_afford(_price):
		await _shake_tag()
		await _fade_offer()
		await _hold()
		return &"broke"
	_bids = 1
	await _hop()
	run.remember(RunState.BUTTON_AUCTIONED)
	await _bring_in_rival()
	await _rival_bids()
	_another = true
	return &"auction"


## The placeholders this stage fills: the asking price, the rival's bid and the player's next one.
static func fill_names() -> PackedStringArray:
	return PackedStringArray(["price", "rival", "bid"])


func option_labels() -> PackedStringArray:
	if _bids == 0:
		return super.option_labels()
	var values := fills()
	var labels := PackedStringArray()
	for i in question.options.size():
		labels.append((_bid_text if i == _buy else _drop_text).format(values))
	return labels


func fills() -> Dictionary:
	return {"price": Numbers.money(_price), "rival": Numbers.money(_rival_bid), "bid": Numbers.money(_rival_bid + _step)}


func fill_keys() -> Dictionary:
	return {"price": str(_price), "rival": str(_rival_bid), "bid": str(_rival_bid + _step)}


## The player went for it if they bid at all; passing, and finding they had not the money, count the same.
func reveal_split(pick: int) -> RevealSplit:
	var split := RevealSplit.of(question, pick)
	if _buy >= 0 and question.options.size() == 2:
		split.pick = _buy if _bids > 0 else 1 - _buy
	return split


## Every way this stage fills its question's lines, for the voice tools and the tests: the asking price
## in the ask, the button's bid in each round in its taunts and in the imp's lines that answer them.
static func fill_variants(for_question: QuestionData) -> Dictionary:
	var data := for_question.stage
	var price := int(data.get("price", 0))
	var step := int(data.get("step", 0))
	var rounds := maxi(int(data.get("persist", 3)), 1) - 1
	var variants := {}
	for line in for_question.ask:
		if not line.placeholders().is_empty():
			variants[line.id] = [_fill_set(price, price, step)]
	var taunts := for_question.lines_in(&"taunts")
	for i in taunts.size():
		var sets: Array = []
		for round_number in range(1, rounds + 1):
			if (round_number - 1) % taunts.size() == i:
				sets.append(_fill_set(price, _rival_in(round_number, price, step), step))
		variants[taunts[i].id] = sets
	for option in for_question.options:
		for result: StringName in option.reactions:
			var sets: Array = []
			if result == &"auction" and rounds >= 1:
				sets.append(_fill_set(price, _rival_in(1, price, step), step))
			elif result == &"bid":
				for round_number in range(2, rounds + 1):
					sets.append(_fill_set(price, _rival_in(round_number, price, step), step))
			for line: LineData in option.reactions[result]:
				if not line.placeholders().is_empty():
					variants[line.id] = sets
	return variants


## What the rival bids in round [param round_number], counting from 1: a step over the player's bid,
## which is a step over its last.
static func _rival_in(round_number: int, price: int, step: int) -> int:
	return price + (2 * round_number - 1) * step


static func _fill_set(price: int, rival: int, step: int) -> Dictionary:
	return {"fills": {"price": Numbers.money(price), "rival": Numbers.money(rival), "bid": Numbers.money(rival + step)},
			"keys": {"price": str(price), "rival": str(rival), "bid": str(rival + step)}}


## The walking button waddles in, already alive, and says it wants the thing.
func _bring_in_rival() -> void:
	if walker_scene == null:
		return
	_walker = walker_scene.instantiate() as WalkingButton
	_walker.position = Vector2(walker_from, slot.position.y)
	add_child(_walker)
	_walker.body.look = ButtonLook.find(walker_look)
	_walker.alive = true
	await _walker.walk_to(walker_spot)
	await _walker.face_toward(0)
	if bidding_arms != null:
		_walker.hold_arms(bidding_arms)
	await _say_line(&"arrive", 0)


## The rival bids a step over the player, and says so: the tag climbs to its bid.
func _rival_bids() -> void:
	var round_number := _bids
	_rival_bid = _price + _step
	_price = _rival_bid
	_refresh()
	var taunts := question.lines_in(&"taunts")
	if not taunts.is_empty():
		await _say(_filled(taunts[(round_number - 1) % taunts.size()]))


## The imp cuts in, over everything, and moves on by himself.
func _cut_in() -> void:
	var stop := question.lines_in(&"stop")
	if stop.is_empty() or dialogue == null:
		return
	await dialogue.say(fill(stop), false, true)
	await dialogue.close()


## The rival says its [param said] line, takes the thing, and walks off with it; the tag clears.
func _let_it_win(said: StringName) -> void:
	if _walker == null:
		await _fade_offer()
		return
	await _say_line(said, 0)
	var grab := create_tween().set_parallel(true)
	grab.tween_property(tag, ^"modulate:a", 0.0, grab_duration)
	slot.reparent(_walker)
	grab.tween_property(slot, ^"position", carry_offset, grab_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	grab.tween_property(slot, ^"scale", Vector2.ONE * carry_scale, grab_duration)
	await grab.finished
	await _walker.walk_off(exit_direction)
	await _walker.finish_saying()


## Has the rival say line [param index] of the question's [param set_name] set, aloud when it has been
## voiced, and waits until it has been said.
func _say_line(set_name: StringName, index: int) -> void:
	var lines := question.lines_in(set_name)
	if index < lines.size():
		await _say(_filled(lines[index]))


func _say(line: LineData) -> void:
	if _walker == null:
		return
	_walker.say(line.text, VoiceLibrary.clip_for(line))
	await _walker.finish_saying()
	await get_tree().create_timer(beat, false).timeout


## [param line] with its placeholders filled from the stage as it is now.
func _filled(line: LineData) -> LineData:
	return line.filled(fills(), fill_keys())
