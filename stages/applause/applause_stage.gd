class_name ApplauseStage
extends StudioStage
## 6.01, The Show's warm up: a contestant walks on, trips over nothing and lands flat on their face, and
## the APPLAUSE sign lights up over the stage while the audience claps on cue. Whatever the player does,
## the room claps; then the contestant gets up and throws their arms open.
## Stage data: [code]{"type": "applause", "sign": {"text": "APPLAUSE"}}[/code], the sign's word.

## Where the contestant walks on from, and where they trip.
@export var walk_from := 520.0
@export var trip_at := 960.0
## Where the sign hangs, its bottom middle.
@export var sign_spot := Vector2(960.0, 330.0)
## Seconds the audience claps once the sign lights, before the player is asked.
@export_range(0.0, 10.0, 0.05) var clap_time := 3.0
## Seconds the contestant lies on the floor before getting up, once the player has chosen.
@export_range(0.0, 5.0, 0.05) var lie_time := 0.6
## Seconds the contestant takes to get up.
@export_range(0.05, 5.0, 0.05) var rise_time := 0.9

const STAND := preload("res://figures/poses/stand.tres")
const CLEARED := preload("res://figures/poses/verdict_cleared.tres")
const FALL: Array[FigurePose] = [preload("res://figures/poses/buckle.tres"), preload("res://figures/poses/collapse.tres"),
		preload("res://figures/poses/down.tres")]

var _contestant: Soul
var _sign: InkDrawing


func setup(for_question: QuestionData) -> void:
	super.setup(for_question)
	_contestant = add_contestant(&"stranger", walk_from)
	_sign = add_prop("applause_sign", 0.0, 1.0, sign_spot)
	var words: Variant = question.stage.get("sign", {})
	if _sign != null and words is Dictionary and words.has("text"):
		_sign.set(&"word", str(words["text"]))


## The studio draws on, the contestant walks on and goes flat on their face, and the sign lights.
func enter() -> void:
	await super.enter()
	var figure := _contestant as StickFigure
	if figure == null:
		return
	await figure.walk_to(trip_at)
	figure.facing = StickFigure.Facing.FRONT
	await figure.play_motion(FALL)
	if _sign != null:
		_sign.set(&"lit", true)
	applaud(clap_time)


func play_consequence(_index: int) -> StringName:
	applaud(clap_time * 0.5)
	await get_tree().create_timer(lie_time, false).timeout
	var figure := _contestant as StickFigure
	if figure != null:
		await figure.blend_to(STAND, rise_time).finished
		figure.blend_to(CLEARED, rise_time * 0.5)
	if _sign != null:
		_sign.set(&"lit", false)
	return &""
