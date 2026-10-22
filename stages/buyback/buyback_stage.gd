class_name BuybackStage
extends Stage
## The buyback: everything the player owns, in rows, each with its doodle, its name and what the imp
## will give back for it in amber, all dimmed. He walks the rows one at a time in the order things were
## bought, lighting each, and the player sells it back or keeps it: a sold row fades away and the money
## goes back in the wallet, a kept one dims again. Owning nothing, there is nothing to choose. Stage data:
## [codeblock]
## {"type": "buyback", "share": 50, "round_to": 10, "least": 10}
## [/codeblock]
## The offer is [code]share[/code] percent of what was paid, or the thing's own share when the shop gave
## it one, rounded to the nearest [code]round_to[/code] and never under [code]least[/code].
## The option whose outcome has [code]sell[/code] sells; the other keeps.
## How it is asked: [code]nothing[/code] when nothing is owned; the first thing's question id, such as
## [code]poverty[/code], when the question has an ask of that name; [code]items[/code] otherwise.
## Outcomes: the thing's question id when the picked option has a reaction for it; for the last row
## [code]last[/code], or [code]none[/code] for keeping it with nothing sold; otherwise [code]sold[/code]
## and [code]kept[/code] the first time each is picked, and [code]again[/code] after.

## Where the rows go. Each row's doodle, name and offer are added under it.
@export var rows_root: Node2D

@export_group("Layout")
## Where the middle of the rows sits, down the page.
@export_range(0.0, 1080.0, 1.0) var rows_middle := 500.0
## Distance from one row's baseline to the next, when there is room for it.
@export_range(20.0, 400.0, 1.0) var row_height := 122.0
## The first row's baseline goes no higher than this, clear of the balance at the top.
@export_range(0.0, 1080.0, 1.0) var rows_top := 250.0
## The last row's baseline goes no lower than this, clear of the dialogue box.
@export_range(0.0, 1080.0, 1.0) var rows_bottom := 780.0
## Where each row's doodle stands, across the page.
@export_range(0.0, 1920.0, 1.0) var doodle_x := 690.0
## How big the doodles are, as a share of their natural size.
@export_range(0.05, 2.0, 0.01) var doodle_scale := 0.4
## Where each row's name starts, across the page.
@export_range(0.0, 1920.0, 1.0) var name_x := 790.0
## Where each row's offer ends, across the page.
@export_range(0.0, 1920.0, 1.0) var offer_right := 1300.0
## How far above the baseline the middle of a row's words sits.
@export_range(0.0, 300.0, 1.0) var words_height := 40.0

@export_group("Words")
## Size of the names.
@export_range(8, 120) var name_size := 40
## Palette role of the names.
@export var name_role := &"ink"
## Size of the offers.
@export_range(8, 120) var offer_size := 44
## Palette role of the offers.
@export var offer_role := &"amber"

@export_group("Lighting")
## How faint a row is while it waits, or once it has been kept.
@export_range(0.0, 1.0, 0.01) var dim_alpha := 0.35
## Seconds a row takes to light up or dim.
@export_range(0.0, 2.0, 0.01) var light_duration := 0.3
## Seconds a sold row takes to fade away.
@export_range(0.0, 3.0, 0.01) var sold_fade := 0.6
## Seconds the stage holds still once a row has gone.
@export_range(0.0, 3.0, 0.01) var hold_duration := 0.3

## What is owned, in the order it was bought.
var _items: Array[Purchase] = []
## One node per row, holding its doodle and words.
var _rows: Array[Node2D] = []
var _row := 0
var _sell := -1
var _sold := 0
var _kept := 0
var _another := false


func setup(for_question: QuestionData) -> void:
	super.setup(for_question)
	if run.wallet != null:
		_items = run.wallet.bought.duplicate()
	for i in for_question.options.size():
		if bool(for_question.options[i].outcome.get("sell", false)):
			_sell = i
	var step := row_height
	if _items.size() > 1:
		step = minf(row_height, (rows_bottom - rows_top) / (_items.size() - 1))
	var top := maxf(rows_middle - (_items.size() - 1) * step * 0.5, rows_top)
	for i in _items.size():
		_rows.append(_make_row(_items[i], top + i * step))
	for i in _rows.size():
		_rows[i].modulate.a = 1.0 if i == 0 else dim_alpha


func enter() -> void:
	var fade := create_tween().set_parallel(true)
	for label in _labels():
		label.modulate.a = 0.0
		fade.tween_property(label, ^"modulate:a", 1.0, enter_duration)
	await super.enter()


func ask_key() -> StringName:
	if _items.is_empty():
		return &"nothing"
	if question.asks.has(_items[0].id):
		return _items[0].id
	return &"items"


func offers_choice() -> bool:
	return not _items.is_empty()


func play_consequence(index: int) -> StringName:
	_another = false
	if _row >= _items.size():
		return &""
	var item := _items[_row]
	var selling := index == _sell
	var row := _rows[_row]
	var result := _outcome(index, item, selling)
	if selling:
		run.wallet.sell(item, offer_for(item, question.stage))
		_sold += 1
		await create_tween().tween_property(row, ^"modulate:a", 0.0, sold_fade).finished
	else:
		_kept += 1
		await create_tween().tween_property(row, ^"modulate:a", dim_alpha, light_duration).finished
	_row += 1
	if _row < _rows.size():
		create_tween().tween_property(_rows[_row], ^"modulate:a", 1.0, light_duration)
		_another = true
	await get_tree().create_timer(hold_duration, false).timeout
	return result


func another_round() -> bool:
	return _another


## The player's bar is the selling one if anything was sold back at all.
func reveal_split(pick: int) -> RevealSplit:
	var split := super.reveal_split(pick)
	if _sell >= 0 and question.options.size() == 2:
		split.pick = _sell if _sold > 0 else 1 - _sell
	return split


func leave() -> void:
	var fade := create_tween().set_parallel(true)
	for label in _labels():
		fade.tween_property(label, ^"modulate:a", 0.0, leave_duration)
	await super.leave()


## What the buyback gives back for [param item], by the stage data [param data].
static func offer_for(item: Purchase, data: Dictionary) -> int:
	var share := item.buyback_share if item.buyback_share >= 0.0 else float(data.get("share", 50))
	var round_to := maxi(int(data.get("round_to", 10)), 1)
	var least := int(data.get("least", 10))
	return maxi(roundi(item.paid * share / 100.0 / round_to) * round_to, least)


## How the row for [param item] came out, picked with the option at [param index].
func _outcome(index: int, item: Purchase, selling: bool) -> StringName:
	if question.options[index].reactions.has(item.id):
		return item.id
	if _row == _items.size() - 1:
		return &"last" if selling or _sold > 0 else &"none"
	if selling:
		return &"sold" if _sold == 0 else &"again"
	return &"kept" if _kept == 0 else &"again"


func _make_row(item: Purchase, baseline: float) -> Node2D:
	var row := Node2D.new()
	row.position = Vector2(0.0, baseline)
	rows_root.add_child(row)
	var doodle := DoodlesStage.make_doodle(item.doodle)
	if doodle != null:
		doodle.position = Vector2(doodle_x, 0.0)
		doodle.scale = Vector2.ONE * doodle_scale
		row.add_child(doodle)
	var palette := InkPalette.get_default()
	var name_label := _label(item.label, name_size, palette.color(name_role))
	row.add_child(name_label)
	name_label.position = Vector2(name_x, -words_height - name_label.size.y * 0.5)
	var offer := _label(Numbers.money(offer_for(item, question.stage)), offer_size, palette.color(offer_role))
	row.add_child(offer)
	offer.position = Vector2(offer_right - offer.size.x, -words_height - offer.size.y * 0.5)
	return row


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = text
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	label.reset_size()
	return label


func _labels() -> Array[Label]:
	var labels: Array[Label] = []
	for row in _rows:
		for child in row.get_children():
			if child is Label:
				labels.append(child)
	return labels
