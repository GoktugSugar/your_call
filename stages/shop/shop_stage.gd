class_name ShopStage
extends Stage
## The money chapter's shop: one thing for sale, its doodle beside an amber price tag. Buy it and the
## price comes out of the wallet: an amber loop circles it and it hops. Keep the money, or try to buy it
## without enough, and the offer fades. Pointing at the thing lifts it and lights the buying option, and
## clicking it buys. Stage data:
## [codeblock]
## {"type": "shop", "item": "burrito", "label": "Free food for life", "price": 1800}
## {"type": "shop", "item": "charity_hand", "label": "End Poverty", "price": "everything", "buyback": 100}
## {"type": "shop", "item": "stranger_clock", "label": "A stranger's years", "price": 700, "step": 100,
##  "most": 40, "tag": {"text": "{price} a year"}, "tally": {"text": "{count} years taken"}}
## [/codeblock]
## [code]item[/code] names the doodle, [code]label[/code] is the thing's name on the receipt, and a price
## of [code]everything[/code] asks for the whole balance. [code]buyback[/code] is the share of the price
## the buyback offers for it, in percent, when that differs from the buyback's own. With [code]step[/code]
## it is bought one at a time, as often as the player likes up to [code]most[/code], each one dearer by
## the step, with [code]tag[/code] and [code]tally[/code] as its running words.
## The option whose outcome has [code]buy[/code] buys; the other keeps the money.
## Outcomes: [code]bought[/code]; [code]broke[/code] when the money is not there, which counts as keeping
## it; [code]passed[/code] for keeping it. Bought one at a time: [code]first[/code] and [code]more[/code]
## for each one bought, [code]broke[/code] or [code]ran_out[/code] when the money runs out before or after
## the first, and on stopping [code]some[/code] or [code]none[/code].
## Placeholders: [code]{price}[/code] what one costs now, [code]{count}[/code] how many were bought.

## The placeholders this stage fills.
const FILLS: PackedStringArray = ["price", "count"]
## The price that asks for everything the player has.
const EVERYTHING := "everything"

## Where the thing for sale stands. Its doodle's origin goes on this node's origin.
@export var slot: Node2D
## The price tag.
@export var tag: PriceTag
## Counts how many were bought, for a thing bought one at a time.
@export var tally: Label
## The amber loop drawn round the thing when it is bought.
@export var loop: PickLoop
## The pot to shop from when no chapter has opened a wallet, as in a sampler.
@export var fallback_start := 10000

@export_group("Words")
## Size of the tally.
@export_range(8, 120) var tally_size := 38
## Palette role of the tally.
@export var tally_role := &"amber"
## Gap between the bottom of the tag and the top of the tally.
@export_range(0.0, 200.0, 1.0) var tally_gap := 10.0
## Seconds the words take to fade in or out.
@export_range(0.0, 3.0, 0.01) var words_fade := 0.4

@export_group("Pointing")
## The area round the thing that catches the pointer, in the slot's space.
@export var hit_area := Rect2(-210.0, -260.0, 420.0, 290.0)
## How far the thing rises while it is pointed at.
@export_range(0.0, 60.0, 0.5) var lift_height := 10.0
## Seconds it takes to rise or settle.
@export_range(0.0, 1.0, 0.01) var lift_duration := 0.12

@export_group("Consequence")
## The middle of the loop, in the slot's space.
@export var loop_center := Vector2(0.0, -110.0)
## Seconds the loop takes to draw itself on.
@export_range(0.05, 3.0, 0.01) var loop_duration := 0.7
## How high the thing hops when it is bought.
@export_range(0.0, 80.0, 0.5) var hop_height := 16.0
## Seconds the hop takes, up and back down.
@export_range(0.05, 2.0, 0.01) var hop_duration := 0.4
## How faint the offer goes when it is passed by.
@export_range(0.0, 1.0, 0.01) var passed_alpha := 0.35
## Seconds the offer takes to fade when it is passed by.
@export_range(0.05, 3.0, 0.01) var fade_duration := 0.6
## How far the tag shakes, side to side, when there is not the money for it.
@export_range(0.0, 60.0, 0.5) var shake_distance := 12.0
## How many times it shakes.
@export_range(1, 8) var shakes := 3
## Seconds each shake takes, there and back.
@export_range(0.02, 1.0, 0.01) var shake_time := 0.12
## Seconds the stage holds still once the consequence has played.
@export_range(0.0, 3.0, 0.01) var hold_duration := 0.5

var _doodle: InkDrawing
var _wallet: Wallet
## The option that buys, or -1.
var _buy := -1
## What one costs now.
var _price := 0
var _step := 0
var _most := 1
var _one_at_a_time := false
## How many were bought here.
var _count := 0
var _another := false
var _live := false
var _pointed := false
var _highlighted := false
var _lifted := false
var _lift_tween: Tween
var _tag_text := "{price}"
var _tally_text := ""


func setup(for_question: QuestionData) -> void:
	super.setup(for_question)
	var data := for_question.stage
	_wallet = run.wallet if run.wallet != null else run.open_wallet(fallback_start)
	_doodle = DoodlesStage.make_doodle(str(data.get("item", "")))
	if _doodle != null:
		slot.add_child(_doodle)
	else:
		push_warning("Shop stage: no doodle '%s' for %s." % [data.get("item", ""), for_question.id])
	_one_at_a_time = data.has("step")
	_step = int(data.get("step", 0))
	_most = maxi(int(data.get("most", 1)), 1) if _one_at_a_time else 1
	_price = _wallet.balance if str(data.get("price", "")) == EVERYTHING else int(data.get("price", 0))
	for i in for_question.options.size():
		if bool(for_question.options[i].outcome.get("buy", false)):
			_buy = i
	var tag_data: Variant = data.get("tag", {})
	if tag_data is Dictionary:
		_tag_text = str(tag_data.get("text", _tag_text))
	var tally_data: Variant = data.get("tally", {})
	if tally_data is Dictionary:
		_tally_text = str(tally_data.get("text", ""))
	tally.add_theme_font_size_override(&"font_size", tally_size)
	tally.add_theme_color_override(&"font_color", InkPalette.get_default().color(tally_role))
	tally.visible = _one_at_a_time and not _tally_text.is_empty()
	_refresh()


func enter() -> void:
	var fade := create_tween().set_parallel(true)
	for item in _words():
		item.modulate.a = 0.0
		fade.tween_property(item, ^"modulate:a", 1.0, enter_duration)
	await super.enter()


func set_choosing(active: bool) -> void:
	_live = active and _buy >= 0
	if not _live and _pointed:
		_pointed = false
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		option_hovered.emit(-1)
	_lift(_pointed or _highlighted)


func highlight_option(index: int) -> void:
	_highlighted = index >= 0 and index == _buy
	_lift(_pointed or _highlighted)


func play_consequence(index: int) -> StringName:
	set_choosing(false)
	_highlighted = false
	_lift(false)
	_another = false
	if index != _buy:
		if _count == 0:
			_wallet.pass_on(_purchase())
			await _fade_offer()
		await _hold()
		if _one_at_a_time:
			return &"some" if _count > 0 else &"none"
		return &"passed"
	if not _wallet.can_afford(_price):
		if _count == 0:
			_wallet.pass_on(_purchase())
		await _shake_tag()
		if _count == 0:
			await _fade_offer()
		await _hold()
		return &"ran_out" if _count > 0 else &"broke"
	_wallet.buy(_purchase())
	_count += 1
	if _count == 1:
		await loop.circle(loop.to_local(slot.to_global(loop_center)), loop_duration)
	await _hop()
	if not _one_at_a_time:
		await _hold()
		return &"bought"
	_price += _step
	_another = _count < _most
	_refresh()
	return &"first" if _count == 1 else &"more"


func another_round() -> bool:
	return _another


func fills() -> Dictionary:
	return {"price": Numbers.money(_price), "count": Numbers.grouped(_count)}


func fill_keys() -> Dictionary:
	return {"price": str(_price), "count": str(_count)}


## The player's bar is the buying one if anything was bought, and keeping the money otherwise, as
## trying to buy without the money counts as keeping it.
func reveal_split(pick: int) -> RevealSplit:
	var split := super.reveal_split(pick)
	if _buy < 0 or question.options.size() != 2:
		return split
	split.pick = _buy if _count > 0 else 1 - _buy
	return split


func leave() -> void:
	var fade := create_tween().set_parallel(true)
	for item in _words():
		fade.tween_property(item, ^"modulate:a", 0.0, leave_duration)
	await super.leave()


func option_point(index: int) -> Vector2:
	if index < 0 or index != _buy or _doodle == null:
		return Vector2.INF
	return slot.get_global_transform_with_canvas() * hit_area.get_center()


## Every way this stage fills its question's lines, for the voice tools and the tests: the price as it
## is offered, which is the first one's price for a thing bought one at a time. A price of everything
## the player has is never said, only shown.
static func fill_variants(for_question: QuestionData) -> Dictionary:
	var price: Variant = for_question.stage.get("price", 0)
	var variants := {}
	if str(price) == EVERYTHING:
		return variants
	var fill_set := {"fills": {"price": Numbers.money(int(price))}, "keys": {"price": str(int(price))}}
	for line in for_question.all_lines():
		if "price" in line.placeholders():
			variants[line.id] = [fill_set]
	return variants


func _unhandled_input(event: InputEvent) -> void:
	if not _live or not event is InputEventMouse or _doodle == null:
		return
	var over := hit_area.has_point((slot.make_input_local(event) as InputEventMouse).position)
	if event is InputEventMouseMotion:
		if over != _pointed:
			_pointed = over
			Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if over else Input.CURSOR_ARROW)
			_lift(_pointed or _highlighted)
			option_hovered.emit(_buy if over else -1)
	elif over and event.is_action_pressed(&"pick"):
		get_viewport().set_input_as_handled()
		option_committed.emit(_buy)


## What is on offer, as the wallet keeps it, at what one costs now.
func _purchase() -> Purchase:
	var data := question.stage
	var item := Purchase.make(question.id, str(data.get("label", "")), str(data.get("item", "")), _price)
	item.buyback_share = float(data.get("buyback", -1.0))
	return item


## Shows the price, and the tally for a thing bought one at a time, as they stand.
func _refresh() -> void:
	var values := fills()
	tag.set_words(_tag_text.format(values))
	tally.text = _tally_text.format(values)
	tally.reset_size()
	tally.position = tag.position + Vector2(tag.point_length + (tag.card_size.x - tally.size.x) * 0.5,
			tag.card_size.y * 0.5 + tally_gap)


func _lift(lifted: bool) -> void:
	if lifted == _lifted or _doodle == null:
		return
	_lifted = lifted
	if _lift_tween != null and _lift_tween.is_valid():
		_lift_tween.kill()
	_lift_tween = create_tween()
	_lift_tween.tween_property(_doodle, ^"position:y", -lift_height if lifted else 0.0, lift_duration) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _hop() -> void:
	if _doodle == null:
		return
	if _lift_tween != null and _lift_tween.is_valid():
		_lift_tween.kill()
	var half := hop_duration * 0.5
	var hop := create_tween()
	hop.tween_property(_doodle, ^"position:y", -hop_height, half).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	hop.tween_property(_doodle, ^"position:y", 0.0, half).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await hop.finished


## The tag shakes its head: there is not the money for it.
func _shake_tag() -> void:
	var home := tag.position
	var shake := create_tween()
	for i in shakes:
		shake.tween_property(tag, ^"position:x", home.x + shake_distance, shake_time * 0.25)
		shake.tween_property(tag, ^"position:x", home.x - shake_distance, shake_time * 0.5)
		shake.tween_property(tag, ^"position:x", home.x, shake_time * 0.25)
	await shake.finished


## The offer goes faint as it passes by.
func _fade_offer() -> void:
	var fade := create_tween().set_parallel(true)
	for item: CanvasItem in [slot, tag, tally]:
		fade.tween_property(item, ^"modulate:a", passed_alpha, fade_duration)
	await fade.finished


func _hold() -> void:
	if hold_duration > 0.0:
		await get_tree().create_timer(hold_duration, false).timeout


## The words that fade in and out with the drawings.
func _words() -> Array[CanvasItem]:
	var items: Array[CanvasItem] = [tag.words]
	if tally.visible:
		items.append(tally)
	return items
