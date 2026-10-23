class_name TallyStage
extends Stage
## A recap of the player's guesses about one thing, such as strangers, for the close of Everyone Else:
## a small bar for each guess, one under the next, as long as the room's share, with the guess as an
## amber mark across it. It reports how the guesses ran on average.
## Stage data: [code]{"type": "tally", "about": "strangers", "close": 8}[/code].
## Outcomes: [code]close[/code] when the guesses came within [code]close[/code] of the truth on average,
## [code]low[/code] when they ran under it, [code]high[/code] over it. With no guesses, close.

## The bar a recap row is drawn with, as long as the room.
@export_range(10.0, 1600.0, 1.0) var row_length := 640.0
## Height of each recap bar.
@export_range(2.0, 80.0, 0.5) var row_height := 22.0
## Where the first row's bar starts, its middle, and the distance down to the next.
@export var first_row := Vector2(640.0, 380.0)
@export_range(10.0, 300.0, 1.0) var row_gap := 82.0
## How close the guesses must run on average to count as close, when the data does not say.
@export_range(0.0, 50.0, 0.5) var default_close := 8.0
## Seconds between one row inking in and the next.
@export_range(0.0, 3.0, 0.05) var row_beat := 0.35
## Seconds each row's true bar takes to ink in.
@export_range(0.05, 3.0, 0.05) var fill_time := 0.6

var _rows: Array[CrowdBar] = []


func setup(for_question: QuestionData) -> void:
	super.setup(for_question)
	var about := str(question.stage.get("about", ""))
	var row := 0
	for id in run.guesses:
		var guess: Dictionary = run.guesses[id]
		if str(guess.get("about", "")) != about:
			continue
		var at := first_row + Vector2(0.0, row * row_gap)
		var bar := CrowdBar.new()
		bar.full_length = row_length
		bar.bar_height = row_height
		bar.value = float(guess.get("truth", 0.0))
		bar.fill = 0.0
		bar.position = at - Vector2(0.0, row_height * 0.5)
		bar.size = Vector2(row_length, row_height)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bar)
		_rows.append(bar)
		var mark := GuessScale.new()
		mark.length = row_length
		mark.bar_height = row_height
		mark.guess = float(guess.get("guess", 0.0))
		mark.position = at
		mark.z_index = 1
		add_child(mark)
		row += 1


func play_consequence(_index: int) -> StringName:
	for bar in _rows:
		create_tween().tween_property(bar, ^"fill", 1.0, fill_time)
		await get_tree().create_timer(row_beat, false).timeout
	var lean := run.guess_lean(StringName(str(question.stage.get("about", ""))))
	if absf(lean) <= float(question.stage.get("close", default_close)):
		return &"close"
	return &"low" if lean < 0.0 else &"high"
