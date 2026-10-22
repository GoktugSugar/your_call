class_name OfferStage
extends Stage
## An escalating offer, a ladder: one button and an amount over it. Press it and take the amount, and the
## offer comes round again at the next tier for as long as the player keeps pressing; stop, and it is
## over. The price of a life halves the amount and a stranger folds with every press; the button for
## everyone doubles it. Running readouts appear once there is a number to run. Stage data:
## [codeblock]
## {"type": "offer", "button": "plain", "victim": "stranger", "people": 8100000000, "high_from": 128,
##  "readouts": [{"text": "{total} banked", "role": "amber"}],
##  "tiers": [{"amount": 100000, "crowd": 61}, ..., {"amount": 512, "crowd": 6, "repeats": true}]}
## [/codeblock]
## A tier's crowd is the share who took the offer at that tier; the reveal shows the tier the player
## stopped on. A tier that [code]repeats[/code] comes round again at the same amount, so the top of a
## climbing ladder can be pressed for ever. The option whose outcome has [code]accept[/code] takes the
## offer; the other stops.
## Outcomes: taking an amount reports it in digits, such as [code]50000[/code], or [code]again[/code]
## for a repeat of the same tier. Stopping reports [code]high[/code] or [code]low[/code] when
## [code]high_from[/code] is set: the amount last taken, measured against it.
## Placeholders: [code]{amount}[/code] the amount on offer, [code]{given}[/code] the amount last taken,
## [code]{total}[/code] everything taken, [code]{count}[/code] how many have died, and
## [code]{grand}[/code] everything taken times [code]people[/code].

## The placeholders this stage fills.
const FILLS: PackedStringArray = ["amount", "given", "total", "count", "grand"]

## The button.
@export var button: PushButton
## The amount on offer, over the button.
@export var price: Label
## Holds the running readouts.
@export var readouts: VBoxContainer
## Where the strangers who die for the money are added.
@export var victims: Node2D

@export_group("Words")
## Size of the amount on offer.
@export_range(8, 200) var price_size := 64
## Palette role of the amount on offer.
@export var price_role := &"amber"
## Gap between the top of the button's cap and the bottom of the amount.
@export_range(0.0, 200.0, 1.0) var price_gap := 18.0
## Size of the readouts.
@export_range(8, 120) var readout_size := 36
## Seconds the words take to fade in or out.
@export_range(0.0, 3.0, 0.01) var words_fade := 0.4

@export_group("Strangers")
## Where a stranger can appear: anywhere along the bottom edge of this rect, standing on it.
@export var victim_area := Rect2(360.0, 560.0, 360.0, 90.0)
## Seconds a stranger takes to ink in.
@export_range(0.0, 3.0, 0.01) var victim_draw := 0.35
## Seconds a stranger stands before it folds.
@export_range(0.0, 3.0, 0.01) var victim_pause := 0.25
## Seed for where the strangers appear. Zero picks a new one every play.
@export var victim_seed := 0

## The tiers of the ladder, in order.
var _tiers: Array[Dictionary] = []
## The tier on offer now.
var _tier := 0
## Whether the tier on offer has been taken already, for a tier that repeats.
var _taken := false
## The amount last taken, everything taken, and how many have died for it.
var _given := 0
var _total := 0
var _count := 0
var _people := 0
var _high_from := -1
var _accept := -1
var _another := false
var _rng := RandomNumberGenerator.new()
var _readout_labels: Array[Label] = []
var _readout_texts := PackedStringArray()


func setup(for_question: QuestionData) -> void:
	super.setup(for_question)
	var data := for_question.stage
	for tier: Variant in data.get("tiers", []):
		if tier is Dictionary:
			_tiers.append(tier)
	button.look = ButtonLook.find(StringName(str(data.get("button", "plain"))))
	_people = int(data.get("people", 0))
	_high_from = int(data.get("high_from", -1))
	for i in for_question.options.size():
		if bool(for_question.options[i].outcome.get("accept", false)):
			_accept = i
	if victim_seed != 0:
		_rng.seed = victim_seed
	else:
		_rng.randomize()
	for readout: Variant in data.get("readouts", []):
		if readout is Dictionary:
			_add_readout(str(readout.get("text", "")), StringName(str(readout.get("role", "ink"))))
	readouts.modulate.a = 0.0
	price.add_theme_font_size_override(&"font_size", price_size)
	price.add_theme_color_override(&"font_color", InkPalette.get_default().color(price_role))
	button.hover_changed.connect(func(hovered: bool) -> void: option_hovered.emit(_accept if hovered else -1))
	button.clicked.connect(func() -> void: option_committed.emit(_accept))
	_refresh()


func enter() -> void:
	price.modulate.a = 0.0
	create_tween().tween_property(price, ^"modulate:a", 1.0, enter_duration)
	await super.enter()


func set_choosing(active: bool) -> void:
	button.live = active and _accept >= 0


func highlight_option(index: int) -> void:
	button.highlighted = index >= 0 and index == _accept


func play_consequence(index: int) -> StringName:
	set_choosing(false)
	button.highlighted = false
	if index != _accept or _tiers.is_empty():
		_another = false
		if _high_from < 0:
			return &""
		return &"high" if _given >= _high_from else &"low"
	var tier := _tiers[_tier]
	var amount := int(tier.get("amount", 0))
	var result := &"again" if _taken else StringName(str(amount))
	var victim := StringName(str(question.stage.get("victim", "")))
	var stranger: Soul = null
	if victim != &"" and SoulKind.exists(victim):
		stranger = _place_stranger(victim)
	await button.press()
	_given = amount
	_total += amount
	_refresh()
	if readouts.modulate.a < 1.0:
		create_tween().tween_property(readouts, ^"modulate:a", 1.0, words_fade)
	if stranger != null:
		await get_tree().create_timer(victim_pause, false).timeout
		await stranger.fold(1.0 if _rng.randf() < 0.5 else -1.0)
		stranger.queue_free()
		_count += 1
	if bool(tier.get("repeats", false)):
		_taken = true
		_another = true
	elif _tier + 1 < _tiers.size():
		_tier += 1
		_taken = false
		_another = true
	else:
		_another = false
	_refresh()
	return result


func another_round() -> bool:
	return _another


func fills() -> Dictionary:
	return {"amount": Numbers.money(_offer()), "given": Numbers.money(_given), "total": Numbers.money(_total),
			"count": Numbers.grouped(_count), "grand": Numbers.money(_total * _people)}


func fill_keys() -> Dictionary:
	return {"amount": str(_offer()), "given": str(_given), "total": str(_total), "count": str(_count),
			"grand": str(_total * _people)}


## The share who took the offer at the tier the player stopped on.
func reveal_split(pick: int) -> RevealSplit:
	var split := super.reveal_split(pick)
	if _tiers.is_empty() or _accept < 0:
		return split
	var took := float(_tiers[_tier].get("crowd", split.shares[_accept]))
	for i in split.shares.size():
		split.shares[i] = took if i == _accept else 100.0 - took
	return split


func leave() -> void:
	var fade := create_tween().set_parallel(true)
	for item: CanvasItem in [price, readouts]:
		fade.tween_property(item, ^"modulate:a", 0.0, leave_duration)
	await super.leave()


func option_point(index: int) -> Vector2:
	return button.press_point() if index >= 0 and index == _accept else Vector2.INF


## Every way this stage can fill its question's lines, for the voice tools and the tests: the opening
## offer fills the ask, and every tier's amount fills the lines said on stopping, those after a high
## stop only from [code]high_from[/code] up.
static func fill_variants(for_question: QuestionData) -> Dictionary:
	var amounts: Array[int] = []
	for tier: Variant in for_question.stage.get("tiers", []):
		if tier is Dictionary:
			amounts.append(int(tier.get("amount", 0)))
	var high_from := int(for_question.stage.get("high_from", -1))
	var variants := {}
	if amounts.is_empty():
		return variants
	for line in for_question.ask:
		if not line.placeholders().is_empty():
			variants[line.id] = [_fill_set(amounts[0])]
	for option in for_question.options:
		var said := {&"": option.reaction}
		said.merge(option.reactions)
		for result: StringName in said:
			for line: LineData in said[result]:
				if line.placeholders().is_empty():
					continue
				var sets: Array = []
				for amount in amounts:
					if result == &"high" and amount < high_from or result == &"low" and amount >= high_from:
						continue
					sets.append(_fill_set(amount))
				variants[line.id] = sets
	return variants


static func _fill_set(amount: int) -> Dictionary:
	return {"fills": {"amount": Numbers.money(amount), "given": Numbers.money(amount)},
			"keys": {"amount": str(amount), "given": str(amount)}}


## The amount on offer now.
func _offer() -> int:
	return int(_tiers[_tier].get("amount", 0)) if not _tiers.is_empty() else 0


## A stranger of [param kind], inking in somewhere off to the side.
func _place_stranger(kind: StringName) -> Soul:
	var soul := SoulKind.find(kind).make()
	soul.position = Vector2(_rng.randf_range(victim_area.position.x, victim_area.end.x), victim_area.end.y)
	victims.add_child(soul)
	soul.draw_on(victim_draw)
	return soul


func _add_readout(template: String, role: StringName) -> void:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override(&"font_size", readout_size)
	label.add_theme_color_override(&"font_color", InkPalette.get_default().color(role))
	readouts.add_child(label)
	_readout_labels.append(label)
	_readout_texts.append(template)


## Shows the amount on offer over the button and the readouts as they stand.
func _refresh() -> void:
	price.text = Numbers.money(_offer())
	price.reset_size()
	var cap_top := button.position + button.cap_middle() - Vector2(0.0, button.cap_radius)
	price.position = cap_top - Vector2(price.size.x * 0.5, price.size.y + price_gap)
	var values := fills()
	for i in _readout_labels.size():
		_readout_labels[i].text = _readout_texts[i].format(values)
