class_name WheelStage
extends StudioStage
## 6.03: a contestant behind a podium, their winnings on its board, and a prize wheel beside them, half
## its wedges double and half nothing. The room decides whether they spin, the first option spinning:
## the wheel turns a few times and slows onto a wedge, and the board doubles or drops to nothing. Kept,
## the contestant hops for joy and the board stays.
## Stage data: [code]{"type": "wheel", "random": 40, "line": 50, "contestant": "stranger",
## "prize": 10000, "board": {"text": "{prize}"}}[/code]. Outcomes [code]kept[/code], [code]doubled[/code],
## [code]lost[/code].

## Where the contestant stands, behind the podium.
@export var contestant_x := 800.0
## Where the wheel stands.
@export var wheel_x := 1240.0
## How big the podium is drawn, and the size of the winnings on the band across its front.
@export_range(0.2, 3.0, 0.01) var podium_scale := 1.3
@export_range(8, 200) var winnings_size := 42
## How far over the floor the winnings sit when the podium cannot say where its band is.
@export_range(0.0, 600.0, 1.0) var board_height := 130.0
## Whole turns the wheel makes before it settles.
@export_range(0, 12) var spin_turns := 4
## Seconds the spin takes.
@export_range(0.1, 10.0, 0.1) var spin_time := 3.4
## Seed for where the wheel lands. Zero spins it fresh every play.
@export var wheel_seed := 0
## How high the contestant hops.
@export_range(0.0, 200.0, 1.0) var hop_height := 40.0
## Seconds the stage holds once the wheel has settled.
@export_range(0.0, 3.0, 0.05) var after_hold := 0.6

var _contestant: Soul
var _wheel: InkDrawing
var _board: Label
var _prize := 0


static func fill_names() -> PackedStringArray:
	return PackedStringArray(["prize"])


func setup(for_question: QuestionData) -> void:
	super.setup(for_question)
	_prize = int(question.stage.get("prize", 0))
	_contestant = add_contestant(StringName(str(question.stage.get("contestant", "stranger"))), contestant_x)
	var podium := add_prop("podium", contestant_x, podium_scale)
	var board_at := Vector2(contestant_x, floor_y - board_height)
	if podium != null:
		podium.z_index = 1
		if podium.has_method(&"band_middle"):
			board_at = podium.position + (podium.call(&"band_middle") as Vector2) * podium.scale
	_wheel = add_prop("prize_wheel", wheel_x)
	_board = add_board("board", board_at, winnings_size)


func play_consequence(_index: int) -> StringName:
	await count_votes()
	if not room_picks_first():
		await hop(_contestant, hop_height, 0.5)
		await get_tree().create_timer(after_hold, false).timeout
		return &"kept"
	var doubled := await _spin()
	var won := _prize * 2 if doubled else 0
	if _board != null:
		set_board(_board, Numbers.money(won), _board.position + _board.size * 0.5)
	if doubled:
		await hop(_contestant, hop_height, 0.5)
	await get_tree().create_timer(after_hold, false).timeout
	return &"doubled" if doubled else &"lost"


## Spins the wheel onto a wedge picked at random. Returns whether it landed on a double.
func _spin() -> bool:
	var rng := RandomNumberGenerator.new()
	if wheel_seed != 0:
		rng.seed = wheel_seed
	else:
		rng.randomize()
	if _wheel == null or not _wheel.has_method(&"turn_to_show"):
		return rng.randf() < 0.5
	var wedges := int(_wheel.get(&"segments"))
	var wedge := rng.randi_range(0, maxi(wedges, 1) - 1)
	var start := float(_wheel.get(&"turn"))
	var land := float(_wheel.call(&"turn_to_show", wedge))
	var target := start - fposmod(start, 360.0) + 360.0 * spin_turns + land
	var tween := create_tween()
	tween.tween_property(_wheel, ^"turn", target, spin_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tween.finished
	return wedge % 2 == 0
