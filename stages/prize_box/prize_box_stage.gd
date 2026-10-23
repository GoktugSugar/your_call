class_name PrizeBoxStage
extends StudioStage
## 6.07, the final: the finalist stands between a pile of money, its amount on the board, and a box tied
## with a bow. The room decides which they take, the first option the money. The money: they hop beside
## it. The box: it opens, and up out of it rises a cucumber. The finalist is whoever stayed on their
## trapdoor in 6.02: the stage data's [code]finalist[/code] kind, or another when the run remembers a
## fact in [code]finalist_if[/code].
## Stage data: [code]{"type": "prize_box", "random": 40, "line": 50, "prize": 50000,
## "board": {"text": "{prize}"}, "finalist": "calm", "finalist_if": {"kept_old_soul": "elderly"}}[/code].
## Outcomes [code]money[/code] or [code]box[/code].

## Where the finalist stands, the money, and the box.
@export var finalist_x := 960.0
@export var money_x := 620.0
@export var box_x := 1300.0
## How big the money and the box are drawn.
@export_range(0.2, 3.0, 0.01) var money_scale := 1.0
@export_range(0.2, 3.0, 0.01) var box_scale := 1.1
## How far over the floor the board sits, over the money.
@export_range(0.0, 600.0, 1.0) var board_height := 210.0
## How far the cucumber rises out of the box, and the seconds it takes.
@export_range(0.0, 600.0, 1.0) var rise := 170.0
@export_range(0.05, 3.0, 0.05) var rise_time := 0.7
## Seconds the box takes to open.
@export_range(0.05, 3.0, 0.05) var open_time := 0.5
## How high the finalist hops.
@export_range(0.0, 200.0, 1.0) var hop_height := 36.0
## Seconds the stage holds at the end.
@export_range(0.0, 3.0, 0.05) var after_hold := 0.7

var _finalist: Soul
var _box: InkDrawing


static func fill_names() -> PackedStringArray:
	return PackedStringArray(["prize"])


func setup(for_question: QuestionData) -> void:
	super.setup(for_question)
	_finalist = add_contestant(_finalist_kind(), finalist_x)
	add_prop("coin_stack", money_x, money_scale)
	_box = add_prop("gift_box", box_x, box_scale)
	add_board("board", Vector2(money_x, floor_y - board_height))


func play_consequence(_index: int) -> StringName:
	await count_votes()
	if room_picks_first():
		await hop(_finalist, hop_height, 0.5)
		await get_tree().create_timer(after_hold, false).timeout
		return &"money"
	await _open_box()
	await get_tree().create_timer(after_hold, false).timeout
	return &"box"


## The box opens, and a cucumber rises up out of it.
func _open_box() -> void:
	if _box == null:
		return
	var open := create_tween()
	open.tween_property(_box, ^"open", 1.0, open_time)
	await open.finished
	var cucumber := add_prop("cucumber", box_x, box_scale * 0.7)
	if cucumber == null:
		return
	cucumber.z_index = _box.z_index - 1
	var tween := create_tween().set_parallel(true)
	tween.tween_property(cucumber, ^"position:y", floor_y - rise, rise_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(cucumber, ^"reveal", 1.0, rise_time * 0.6).from(0.0)
	await tween.finished
	# Risen clear of the box, it comes in front of the open lid.
	cucumber.z_index = _box.z_index + 1


## The finalist's kind: the stage data's, or another when the run remembers a fact that names one.
func _finalist_kind() -> StringName:
	var named: Variant = question.stage.get("finalist_if", {})
	if named is Dictionary:
		for fact: Variant in named:
			if run.remembers(StringName(str(fact))):
				return StringName(str(named[fact]))
	return StringName(str(question.stage.get("finalist", "calm")))
