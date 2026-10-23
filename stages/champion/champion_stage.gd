class_name ChampionStage
extends StudioStage
## 6.04: the walking button, The Show's returning champion, standing beside its trophy with its wins on
## the board, saying its own lines over itself. The room votes on it, the first option voting it off:
## voted off, it flinches, and storms off the stage as the round ends; kept, it shakes its fists in
## triumph. Stage data: [code]{"type": "champion", "random": 20, "line": 50, "board": {"text": "40 wins"}}[/code].
## Outcomes [code]off[/code] or [code]stays[/code].

## The walking button.
@export var walker_scene: PackedScene
## Where the button stands, and the size it is drawn at.
@export var walker_x := 900.0
@export_range(0.2, 3.0, 0.01) var walker_scale := 1.2
## Where its trophy stands, and how big.
@export var trophy_x := 1130.0
@export_range(0.2, 3.0, 0.01) var trophy_scale := 0.8
## How far over the floor its board sits, over the trophy, clear of the words over the button.
@export_range(0.0, 600.0, 1.0) var board_height := 210.0
## Seconds after its line before the round goes on.
@export_range(0.0, 3.0, 0.05) var button_beat := 0.25
## Seconds the stage holds once the room has spoken.
@export_range(0.0, 3.0, 0.05) var after_hold := 0.5

const FISTS := preload("res://figures/walking_button/arms/fist.tres")
const FLINCH := preload("res://figures/walking_button/arms/flinch.tres")
const HIPS := preload("res://figures/walking_button/arms/hips.tres")

var _walker: WalkingButton
var _voted_off := false


func setup(for_question: QuestionData) -> void:
	super.setup(for_question)
	_walker = walker_scene.instantiate() as WalkingButton
	_walker.scale = Vector2.ONE * walker_scale
	_walker.words_keep_size = true
	_walker.position = Vector2(walker_x, floor_y)
	add_child(_walker)
	_walker.alive = true
	_walker.hold_arms(HIPS)
	add_prop("trophy", trophy_x, trophy_scale)
	add_board("board", Vector2(trophy_x, floor_y - board_height))


func speaks(line: LineData) -> bool:
	return line.speaker == &"button" and _walker != null


func say_line(line: LineData) -> void:
	_walker.say(line.text, VoiceLibrary.clip_for(line))
	await _walker.finish_saying()
	await get_tree().create_timer(button_beat, false).timeout


func play_consequence(_index: int) -> StringName:
	await count_votes()
	_voted_off = room_picks_first()
	_walker.hold_arms(FLINCH if _voted_off else FISTS)
	await get_tree().create_timer(after_hold, false).timeout
	return &"off" if _voted_off else &"stays"


## Voted off, the button storms off the stage before it all dissolves.
func leave() -> void:
	if _voted_off and _walker != null:
		_walker.fade_words()
		await _walker.walk_off(-1)
	await super.leave()
