class_name CollapseStage
extends StudioStage
## 6.06: during the break a contestant crumples to their knees at the side of the stage. The room decides
## whether enough of it gets up to help: the share standing is the first option's crowd, give or take
## the stage data's [code]random[/code], and the audience stands up by that share, row by row, while it
## is counted. If it passes the [code]line[/code], the contestant gets back to their feet; if not, they
## fold where they knelt. Stage data: [code]{"type": "collapse", "random": 40, "line": 30,
## "contestant": "stranger"}[/code]. Outcomes [code]lives[/code] or [code]dies[/code].

## Where the contestant stands, and crumples.
@export var contestant_x := 620.0
## Seconds the contestant takes to crumple, once the stage is drawn.
@export_range(0.05, 5.0, 0.05) var crumple_time := 0.9
## Seconds the room stays on its feet before it sits back down.
@export_range(0.0, 5.0, 0.05) var stand_hold := 0.9
## Seconds the contestant takes to get back up.
@export_range(0.05, 5.0, 0.05) var rise_time := 1.0
## Seconds the stage holds at the end.
@export_range(0.0, 3.0, 0.05) var after_hold := 0.5

const STAND := preload("res://figures/poses/stand.tres")
const SLUMPED := preload("res://figures/poses/slumped.tres")

var _contestant: Soul


func setup(for_question: QuestionData) -> void:
	super.setup(for_question)
	# The dying kind kneels and falls from its knees; it starts here on its feet.
	_contestant = add_contestant(&"dying", contestant_x)
	var figure := _contestant as StickFigure
	if figure != null:
		figure.pose = STAND
		figure.blend_to(STAND, 0.001)


## The stage draws on, then the contestant crumples to their knees.
func enter() -> void:
	await super.enter()
	var figure := _contestant as StickFigure
	if figure != null:
		await figure.blend_to(SLUMPED, crumple_time, Tween.TRANS_QUAD, Tween.EASE_IN).finished


func play_consequence(_index: int) -> StringName:
	var share := room_share()
	await audience.stand(share)
	await get_tree().create_timer(stand_hold, false).timeout
	var lives := share > room_line()
	audience.sit()
	var figure := _contestant as StickFigure
	if lives:
		if figure != null:
			await figure.blend_to(STAND, rise_time).finished
	else:
		await _contestant.fold(-1.0)
	await get_tree().create_timer(after_hold, false).timeout
	return &"lives" if lives else &"dies"
