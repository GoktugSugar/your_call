class_name OddsStage
extends Stage
## The Odds of You, a tableau: a slip prints itself a line at a time with the run's picks, the rarest
## few when there are many, each beside the share of the room that made the same one, then how many more
## there were, and at the bottom the share of the room that made every one of them, the shares
## multiplied all the way down, as one in so many. Stage data:
## [codeblock]
## {"type": "odds", "title": {"text": "the odds of you"}, "line": {"text": "{number}  {pick}"},
##  "more": {"text": "and {more} more"}, "total": {"text": "one in {odds}"}, "most_rows": 6}
## [/codeblock]
## Outcome: [code]odds[/code]. Placeholders, in its words only: [code]{number}[/code], [code]{pick}[/code],
## [code]{more}[/code] and [code]{odds}[/code].

## The placeholders this stage fills.
const FILLS: PackedStringArray = ["number", "pick", "more", "odds"]

## The slip the lines print on.
@export var slip: ReceiptSlip
## Where the printed lines go, over the slip.
@export var content: Node2D

@export_group("Layout")
## Room between the slip's edges and its lines, across and down.
@export var margin := Vector2(46.0, 26.0)
## The most picks printed; the rest are counted.
@export_range(1, 20) var default_rows := 6
## Size of the title, the lines, and the total.
@export_range(8, 120) var title_size := 40
@export_range(8, 120) var line_size := 34
@export_range(8, 160) var total_size := 46
## Space between lines.
@export_range(0.0, 60.0, 0.5) var line_gap := 8.0

@export_group("Look")
## Palette roles of the title, the picks, their shares, and the total.
@export var title_role := &"heading"
@export var line_role := &"ink"
@export var share_role := &"crowd"
@export var total_role := &"amber"

@export_group("Timing")
## Seconds between one printed line and the next.
@export_range(0.0, 3.0, 0.05) var print_beat := 0.4
## Seconds the stage holds once the total is printed.
@export_range(0.0, 3.0, 0.05) var after_hold := 0.6

var _printed: Array[Control] = []


func setup(for_question: QuestionData) -> void:
	super.setup(for_question)
	_lay_out()


func play_consequence(_index: int) -> StringName:
	for each in _printed:
		create_tween().tween_property(each, ^"modulate:a", 1.0, print_beat * 0.6)
		await get_tree().create_timer(print_beat, false).timeout
	await get_tree().create_timer(after_hold, false).timeout
	return &"odds"


func leave() -> void:
	for each in _printed:
		create_tween().tween_property(each, ^"modulate:a", 0.0, leave_duration)
	await super.leave()


## Prints nothing yet: lays every line out on the slip, unseen, so it can print them one by one.
func _lay_out() -> void:
	var width := slip.size.x - margin.x * 2.0
	var y := margin.y
	y += _print_line(_words("title"), title_size, title_role, y, width, HORIZONTAL_ALIGNMENT_CENTER).size.y + line_gap
	var picks := run.picks.duplicate()
	picks.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.get("share", 0.0)) < float(b.get("share", 0.0)))
	var rows := int(question.stage.get("most_rows", default_rows))
	for i in mini(rows, picks.size()):
		var pick: Dictionary = picks[i]
		var text := _words("line").format({"number": str(pick.get("number", "")), "pick": str(pick.get("pick", ""))})
		var line := _print_line(text, line_size, line_role, y, width, HORIZONTAL_ALIGNMENT_LEFT)
		# The share rides on its line, right aligned over the same width, so the two print together.
		var share := _label(str(roundi(float(pick.get("share", 0.0)))), line_size, share_role, HORIZONTAL_ALIGNMENT_RIGHT)
		line.add_child(share)
		share.size = line.size
		y += line.size.y + line_gap
	if picks.size() > rows:
		var more := _words("more").format({"more": str(picks.size() - rows)})
		y += _print_line(more, line_size, share_role, y, width, HORIZONTAL_ALIGNMENT_LEFT).size.y + line_gap
	var odds := run.odds_of_every_pick()
	var total := Numbers.huge(1.0 / odds) if odds > 0.0 else "0"
	_print_line(_words("total").format({"odds": total}), total_size, total_role, y + line_gap * 2.0, width,
			HORIZONTAL_ALIGNMENT_CENTER)


## A line of [param text] at [param y] down the slip, unseen until it is printed.
func _print_line(text: String, font_size: int, role: StringName, y: float, width: float, align: HorizontalAlignment) -> Label:
	var label := _label(text, font_size, role, align)
	label.position = Vector2(margin.x, y)
	label.size = Vector2(width, 0.0)
	label.modulate.a = 0.0
	content.add_child(label)
	label.size = Vector2(width, label.get_combined_minimum_size().y)
	_printed.append(label)
	return label


func _label(text: String, font_size: int, role: StringName, align: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", InkPalette.get_default().color(role))
	label.horizontal_alignment = align
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _words(key: String) -> String:
	var data: Variant = question.stage.get(key, {})
	return str(data.get("text", "")) if data is Dictionary else ""
