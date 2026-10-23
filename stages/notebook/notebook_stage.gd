class_name NotebookStage
extends Stage
## The imp's notebook, for The Portrait: open on the page, it writes itself a line at a time with the
## strangest picks of the run, those hardly anybody made, rarest first, each with the share of the room
## that made it too; then on the facing page how many times the player was the odd one out, picking
## what the fewest picked. A tableau. Stage data:
## [codeblock]
## {"type": "notebook", "line": {"text": "{number} {pick}"}, "share": {"text": "{share} in 100"},
##  "count": {"text": "the odd one out {count} times"}, "most_rows": 3}
## [/codeblock]
## Outcome: [code]notebook[/code]. Placeholders, in its words only: [code]{number}[/code],
## [code]{pick}[/code], [code]{share}[/code] and [code]{count}[/code].

## The placeholders this stage fills.
const FILLS: PackedStringArray = ["number", "pick", "share", "count"]

## Where the notebook lies, and how big.
@export var notebook_spot := Vector2(960.0, 640.0)
@export_range(0.2, 4.0, 0.01) var notebook_scale := 1.9
## The pages to write on when there is no notebook drawing to say where they are, left and right, in
## the notebook's own space.
@export var fallback_pages: Array[Rect2] = [Rect2(-180.0, -200.0, 160.0, 170.0), Rect2(20.0, -200.0, 160.0, 170.0)]
## The most picks written.
@export_range(1, 10) var default_rows := 3
## Size of the writing, and of the count.
@export_range(8, 120) var line_size := 30
@export_range(8, 160) var count_size := 40
## Palette roles of the picks, their shares and the count.
@export var line_role := &"ink"
@export var share_role := &"secondary"
@export var count_role := &"amber"
## Space between written lines.
@export_range(0.0, 40.0, 0.5) var line_gap := 6.0
## Seconds between one line and the next, as the hand writes.
@export_range(0.0, 3.0, 0.05) var write_beat := 0.8
## Seconds the stage holds once it has written everything.
@export_range(0.0, 3.0, 0.05) var after_hold := 0.4

var _notebook: InkDrawing
var _written: Array[Label] = []


func setup(for_question: QuestionData) -> void:
	super.setup(for_question)
	_notebook = DoodlesStage.make_doodle("notebook")
	if _notebook == null:
		_notebook = InkDrawing.new()
	_notebook.position = notebook_spot
	_notebook.scale = Vector2.ONE * notebook_scale
	add_child(_notebook)
	_lay_out()


func play_consequence(_index: int) -> StringName:
	for label in _written:
		create_tween().tween_property(label, ^"modulate:a", 1.0, write_beat * 0.6)
		await get_tree().create_timer(write_beat, false).timeout
	await get_tree().create_timer(after_hold, false).timeout
	return &"notebook"


func leave() -> void:
	for label in _written:
		create_tween().tween_property(label, ^"modulate:a", 0.0, leave_duration)
	await super.leave()


func _lay_out() -> void:
	var picks := run.picks.duplicate()
	picks.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.get("share", 0.0)) < float(b.get("share", 0.0)))
	var left := _page(0)
	var y := left.position.y
	for i in mini(int(question.stage.get("most_rows", default_rows)), picks.size()):
		var pick: Dictionary = picks[i]
		var line := _write(_words("line").format({"number": str(pick.get("number", "")), "pick": str(pick.get("pick", ""))}),
				line_size, line_role, Vector2(left.position.x, y), left.size.x)
		y += line.size.y
		var share := _write(_words("share").format({"share": str(roundi(float(pick.get("share", 0.0))))}),
				line_size, share_role, Vector2(left.position.x, y), left.size.x)
		y += share.size.y + line_gap * 2.0
	var odd := 0
	for pick: Dictionary in run.picks:
		if pick.get("least", false):
			odd += 1
	var right := _page(1)
	_write(_words("count").format({"count": str(odd)}), count_size, count_role, right.position + Vector2(0.0, right.size.y * 0.3),
			right.size.x)


## The page [param index] (0 left, 1 right) to write on, in the stage's space.
func _page(index: int) -> Rect2:
	var rect: Rect2 = fallback_pages[index] if index < fallback_pages.size() else Rect2()
	if _notebook.has_method(&"page_rect"):
		rect = _notebook.call(&"page_rect", index)
	return Rect2(_notebook.position + rect.position * _notebook.scale, rect.size * _notebook.scale)


## Writes [param text] at [param at], wrapped to [param width], unseen until its turn comes.
func _write(text: String, font_size: int, role: StringName, at: Vector2, width: float) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", InkPalette.get_default().color(role))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.position = at
	label.size = Vector2(width, 0.0)
	label.modulate.a = 0.0
	label.z_index = 1
	add_child(label)
	label.size = Vector2(width, label.get_combined_minimum_size().y)
	_written.append(label)
	return label


func _words(key: String) -> String:
	var data: Variant = question.stage.get(key, {})
	return str(data.get("text", "")) if data is Dictionary else ""
