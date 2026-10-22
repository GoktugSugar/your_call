class_name ReceiptStage
extends Stage
## The money chapter's receipt, a tableau with nothing to choose: an ink receipt draws in under the
## balance and prints itself a line at a time. A row for each thing still owned, its doodle, its name
## and what was paid in amber, the dearest few when there are many; then what the player started with,
## spent and was left with; then, lighter, the doodles of the dearest things they passed on. It reports
## which read the imp gives over it, by the share of the pot left, and quietly nudges the profile by that
## share. Stage data:
## [codeblock]
## {"type": "receipt", "title": {"text": "the receipt"}, "many": {"text": "{name} x{units}"},
##  "more": {"text": "and {more} more"}, "empty": {"text": "you bought nothing at all"},
##  "started": {"text": "started with {start}"}, "spent": {"text": "spent {spent}"},
##  "left": {"text": "left with {left}"}, "passed": {"caption": "passed on"},
##  "most_rows": 6, "most_passed": 4, "hoard_from": 80, "spend_upto": 20, "nudge": {"self_others": -0.2}}
## [/codeblock]
## Outcomes: [code]hoard[/code] with [code]hoard_from[/code] percent of the pot or more left,
## [code]spend[/code] with [code]spend_upto[/code] percent or less, [code]middle[/code] otherwise. The
## question's lines of that name are the imp's read. [code]nudge[/code] is the profile's nudge with the
## whole pot left, scaled by the share left.
## Placeholders, in its words only: [code]{name}[/code], [code]{units}[/code], [code]{more}[/code],
## [code]{start}[/code], [code]{spent}[/code] and [code]{left}[/code].

## The placeholders this stage fills.
const FILLS: PackedStringArray = ["name", "units", "more", "start", "spent", "left"]

## The paper slip.
@export var slip: ReceiptSlip
## Where the slip's words and doodles are added.
@export var content: Node2D
## The pot to read when no chapter has opened a wallet, as in a sampler.
@export var fallback_start := 10000

@export_group("Layout")
## Room between the slip's edges and what is printed on it, across and down.
@export var margin := Vector2(46.0, 28.0)
## Height of each row of a thing bought.
@export_range(10.0, 200.0, 1.0) var row_height := 58.0
## Height of each line of the money at the bottom.
@export_range(10.0, 200.0, 1.0) var sum_height := 44.0
## Gap between the parts of the receipt.
@export_range(0.0, 100.0, 1.0) var part_gap := 16.0
## How big the doodles on the rows are, as a share of their natural size.
@export_range(0.05, 1.0, 0.01) var row_doodle_scale := 0.22
## How big the doodles of things passed on are.
@export_range(0.05, 1.0, 0.01) var passed_doodle_scale := 0.26
## Room each doodle of a thing passed on takes, across.
@export_range(10.0, 300.0, 1.0) var passed_spacing := 120.0
## Height of the row of things passed on.
@export_range(10.0, 300.0, 1.0) var passed_height := 82.0
## Room left of a row's name for its doodle.
@export_range(0.0, 200.0, 1.0) var doodle_room := 72.0

@export_group("Words")
## Size of the title.
@export_range(8, 120) var title_size := 42
## Size of the rows and the money.
@export_range(8, 120) var words_size := 34
## Palette role of the title and the lighter words.
@export var quiet_role := &"heading"
## Palette role of the names and the money.
@export var words_role := &"ink"
## Palette role of what was paid and what is left.
@export var money_role := &"amber"
## How faint the things passed on are.
@export_range(0.0, 1.0, 0.01) var passed_alpha := 0.5

@export_group("Printing")
## Seconds the slip takes to draw on.
@export_range(0.05, 3.0, 0.01) var slip_duration := 0.7
## Seconds between one printed line and the next.
@export_range(0.0, 2.0, 0.01) var line_gap := 0.18
## Seconds each printed line takes to ink in.
@export_range(0.0, 2.0, 0.01) var line_fade := 0.25

var _wallet: Wallet
## What is printed, a line at a time, in order.
var _printed: Array[CanvasItem] = []


func setup(for_question: QuestionData) -> void:
	super.setup(for_question)
	_wallet = run.wallet if run.wallet != null else Wallet.new(fallback_start)
	_lay_out()


## The slip draws on by itself; the printing is the consequence.
func enter() -> void:
	for item in _printed:
		item.modulate.a = 0.0
	slip.reveal = 0.0
	await slip.draw_on(slip_duration).finished


func play_consequence(_index: int) -> StringName:
	for item in _printed:
		if item is InkDrawing:
			(item as InkDrawing).reveal = 1.0
		create_tween().tween_property(item, ^"modulate:a", passed_alpha if item.has_meta(&"passed") else 1.0, line_fade)
		await get_tree().create_timer(line_gap, false).timeout
	var share := _wallet.share_left()
	var nudge: Variant = question.stage.get("nudge", {})
	if nudge is Dictionary:
		var nudges: Dictionary[StringName, float] = {}
		for axis: Variant in nudge:
			nudges[StringName(str(axis))] = float(nudge[axis]) * share
		run.profile.apply(nudges)
	var percent := share * 100.0
	if percent >= float(question.stage.get("hoard_from", 80)):
		return &"hoard"
	if percent <= float(question.stage.get("spend_upto", 20)):
		return &"spend"
	return &"middle"


func leave() -> void:
	var fade := create_tween().set_parallel(true)
	for item in _printed:
		if not item is InkDrawing:
			fade.tween_property(item, ^"modulate:a", 0.0, leave_duration)
	await super.leave()


func fills() -> Dictionary:
	return {"start": Numbers.money(_wallet.start), "spent": Numbers.money(_wallet.spent()),
			"left": Numbers.money(_wallet.balance)}


## Prints the receipt onto the slip and sizes the slip to it.
func _lay_out() -> void:
	var data := question.stage
	var most_rows := maxi(int(data.get("most_rows", 6)), 1)
	var width := slip.size.x - margin.x * 2.0
	var left := -width * 0.5
	var y := margin.y
	y = _print_line(_words_in(data, "title"), title_size, quiet_role, Vector2(0.0, y), HORIZONTAL_ALIGNMENT_CENTER, width)
	y += part_gap
	var owned := _wallet.bought.duplicate()
	var shown := owned
	if owned.size() > most_rows:
		shown = owned.duplicate()
		shown.sort_custom(func(a: Purchase, b: Purchase) -> bool: return a.paid > b.paid)
		shown = shown.slice(0, most_rows)
		# Back into the order they were bought.
		shown.sort_custom(func(a: Purchase, b: Purchase) -> bool: return owned.find(a) < owned.find(b))
	if owned.is_empty():
		y = _print_line(_words_in(data, "empty"), words_size, quiet_role, Vector2(0.0, y), HORIZONTAL_ALIGNMENT_CENTER, width)
	for item: Purchase in shown:
		_print_row(item, data, left, y, width)
		y += row_height
	if owned.size() > shown.size():
		var more := _words_in(data, "more").format({"more": Numbers.grouped(owned.size() - shown.size())})
		y = _print_line(more, words_size, quiet_role, Vector2(left + doodle_room, y), HORIZONTAL_ALIGNMENT_LEFT, width)
	y += part_gap
	var values := fills()
	for key: String in ["started", "spent", "left"]:
		var role := money_role if key == "left" else words_role
		_print_line(_words_in(data, key).format(values), words_size, role, Vector2(left, y), HORIZONTAL_ALIGNMENT_LEFT, width)
		y += sum_height
	var passed := _dearest_passed(int(data.get("most_passed", 4)))
	if not passed.is_empty():
		y += part_gap
		y = _print_line(_words_in(data, "passed", "caption"), words_size, quiet_role, Vector2(0.0, y), HORIZONTAL_ALIGNMENT_CENTER, width)
		var row := Node2D.new()
		row.position = Vector2(0.0, y + passed_height)
		row.set_meta(&"passed", true)
		content.add_child(row)
		_printed.append(row)
		for i in passed.size():
			var doodle := DoodlesStage.make_doodle(passed[i].doodle)
			if doodle != null:
				doodle.position = Vector2((i - (passed.size() - 1) * 0.5) * passed_spacing, 0.0)
				doodle.scale = Vector2.ONE * passed_doodle_scale
				row.add_child(doodle)
		y += passed_height
	slip.size = Vector2(slip.size.x, y + margin.y)


## One row for a thing still owned: its doodle, its name, and what was paid for it.
func _print_row(item: Purchase, data: Dictionary, left: float, y: float, width: float) -> void:
	var row := Node2D.new()
	row.position = Vector2(0.0, y)
	content.add_child(row)
	_printed.append(row)
	var doodle := DoodlesStage.make_doodle(item.doodle)
	if doodle != null:
		doodle.position = Vector2(left + doodle_room * 0.5, row_height * 0.85)
		doodle.scale = Vector2.ONE * row_doodle_scale
		row.add_child(doodle)
	var name := item.label
	if item.units > 1:
		name = _words_in(data, "many").format({"name": item.label, "units": Numbers.grouped(item.units)})
	var name_label := _label(name, words_size, words_role)
	row.add_child(name_label)
	name_label.position = Vector2(left + doodle_room, (row_height - name_label.size.y) * 0.5)
	var paid := _label(Numbers.money(item.paid), words_size, money_role)
	row.add_child(paid)
	paid.position = Vector2(left + width - paid.size.x, (row_height - paid.size.y) * 0.5)


## Prints [param text] as a line of its own at [param at], aligned across [param width] when centred.
## Returns where the next line goes down the slip.
func _print_line(text: String, font_size: int, role: StringName, at: Vector2, align: HorizontalAlignment, width: float) -> float:
	var label := _label(text, font_size, role)
	content.add_child(label)
	_printed.append(label)
	label.position = Vector2(at.x - label.size.x * 0.5 if align == HORIZONTAL_ALIGNMENT_CENTER else at.x, at.y)
	return at.y + label.size.y


## The dearest things passed on, up to [param most], dearest first.
func _dearest_passed(most: int) -> Array[Purchase]:
	var passed := _wallet.passed.duplicate()
	passed.sort_custom(func(a: Purchase, b: Purchase) -> bool: return a.paid > b.paid)
	return passed.slice(0, maxi(most, 0))


func _words_in(data: Dictionary, key: String, field := "text") -> String:
	var entry: Variant = data.get(key, {})
	return str(entry.get(field, "")) if entry is Dictionary else ""


func _label(text: String, font_size: int, role: StringName) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = text
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", InkPalette.get_default().color(role))
	label.reset_size()
	return label
