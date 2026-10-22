extends GutTest
## The dialogue box knows which character is being said at every moment: by a schedule of when each
## character starts, which comes from a voice clip's timings or from the typing of an unvoiced page.

const BOX_SCENE := "res://ui/dialogue/dialogue_box.tscn"
## A line with no voice clip, so it is said as it types.
const UNVOICED_ID := "test.unvoiced"
const UNVOICED_TEXT := "Hello there."
## How fast the unvoiced line types in these tests: a character every tenth of a second.
const TYPING_SPEED := 10.0


func test_the_character_said_follows_the_schedule() -> void:
	var schedule := PackedFloat32Array([0.0, 0.1, 0.2, 0.5])
	assert_eq(DialogueBox.character_at("Hi.", schedule, 0.0), "H")
	assert_eq(DialogueBox.character_at("Hi.", schedule, 0.15), "i")
	assert_eq(DialogueBox.character_at("Hi.", schedule, 0.3), ".", "a pause lasts as long as the schedule holds it")


func test_nothing_is_said_before_the_first_character_or_after_the_last() -> void:
	var schedule := PackedFloat32Array([0.1, 0.2, 0.3, 0.5])
	assert_eq(DialogueBox.character_at("Hi.", schedule, 0.05), "")
	assert_eq(DialogueBox.character_at("Hi.", schedule, 0.5), "")
	assert_eq(DialogueBox.character_at("", PackedFloat32Array([0.0]), 0.0), "", "an empty page says nothing")


func test_a_voiced_page_is_said_on_its_clips_timings() -> void:
	# One character every tenth of a second; the page is the second sentence.
	var clip := VoiceClip.new()
	clip.text = "You pulled. One life."
	for i in clip.text.length():
		clip.starts.append(i * 0.1)
		clip.ends.append((i + 1) * 0.1)
	var schedule := clip.schedule(12, 21)
	assert_eq(DialogueBox.character_at("One life.", schedule, 0.05), "O")
	assert_eq(DialogueBox.character_at("One life.", schedule, 0.45), "l")
	assert_eq(DialogueBox.character_at("One life.", schedule, 0.95), "")


func test_an_unvoiced_page_is_said_as_it_types() -> void:
	var box := _box_saying_unvoiced()
	assert_eq(box.spoken_character(), "H")
	simulate(box, 1, 0.25)
	assert_eq(box.spoken_character(), "l")


func test_it_can_look_ahead() -> void:
	var box := _box_saying_unvoiced()
	assert_eq(box.spoken_character(0.45), "o")


func test_an_unvoiced_page_falls_silent_once_it_is_shown_in_full() -> void:
	var box := _box_saying_unvoiced()
	box.advance()
	assert_eq(box.spoken_character(), "")


func test_nothing_is_said_before_a_page_is_up() -> void:
	var box := (load(BOX_SCENE) as PackedScene).instantiate() as DialogueBox
	add_child_autofree(box)
	assert_eq(box.spoken_character(), "")


## A box that has just put up [constant UNVOICED_TEXT], typing it at [constant TYPING_SPEED].
func _box_saying_unvoiced() -> DialogueBox:
	var box := (load(BOX_SCENE) as PackedScene).instantiate() as DialogueBox
	add_child_autofree(box)
	box.characters_per_second = TYPING_SPEED
	# Not awaited: the page goes up at once, and the test steps its typing by hand.
	box.say([LineData.make(UNVOICED_ID, UNVOICED_TEXT)])
	return box
