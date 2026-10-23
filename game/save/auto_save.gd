class_name AutoSave
extends Node
## Saves the run silently as each beat begins, so quitting loses at most the beat under way, which
## plays again from its start when the run is continued. What it keeps is what the run remembered as
## the beat began, so a beat half played never counts twice. The pause menu's Save keeps that same
## moment again. An ending is added to the record of endings reached and leaves the save at the moment
## the last choice began: the question that fired a secret ending, or the lever before a posting, so
## Continue picks the run up just before the ending and the player can go after the others. The end of
## the run with no ending to record clears the save.

## The run player whose beats are saved.
@export var run_player: RunPlayer
## Off, nothing is written or cleared: a run driven from the command line for checking never touches
## the player's own save.
@export var enabled := true

## What the run remembers. Main hands over each run's.
var run: RunState

var _chapter := &""
## The save as the beat under way began. Empty once the run is over.
var _moment: Dictionary = {}
## The save as the last beat the player chose in began, a question with options rather than a tableau:
## where the run picks up after an ending.
var _last_choice: Dictionary = {}


func _ready() -> void:
	run_player.chapter_started.connect(func(chapter: ChapterData) -> void: _chapter = chapter.id)
	run_player.beat_started.connect(_on_beat_started)
	run_player.ending_reached.connect(_on_ending_reached)


## Keeps the moment the beat under way began, again. Returns whether it was kept.
func save_now() -> bool:
	if not enabled or _moment.is_empty():
		return false
	return RunSave.write(_moment)


## Whether there is a moment to keep: false before the run's first beat and once it is over.
func can_save() -> bool:
	return enabled and not _moment.is_empty()


## The run went to its end with no ending: there is nothing left to continue.
func finish() -> void:
	_moment = {}
	if enabled:
		RunSave.clear()


func _on_beat_started(beat: BeatData) -> void:
	if run == null:
		return
	_moment = RunSave.snapshot(_chapter, beat.id, run)
	if beat is QuestionData and not (beat as QuestionData).options.is_empty():
		_last_choice = _moment
	save_now()


func _on_ending_reached(ending: StringName) -> void:
	_moment = {}
	if not enabled:
		return
	if _last_choice.is_empty():
		RunSave.clear()
	else:
		RunSave.write(_last_choice)
	EndingsRecord.add(ending)
