extends GutTest
## Voice clips: a page plays and inks on to its own stretch of a line's take, and a clip only plays
## while its line still says what it was made from.

const LINE_TEXT := "You pulled. [amber]One[/amber] life."


func _clip(text: String) -> VoiceClip:
	# One character every tenth of a second, each lasting a tenth.
	var clip := VoiceClip.new()
	clip.text = text
	for i in text.length():
		clip.starts.append(i * 0.1)
		clip.ends.append((i + 1) * 0.1)
	return clip


func test_a_page_plays_its_own_stretch_of_the_take() -> void:
	var clip := _clip("You pulled. One life.")
	var stretch := clip.span(12, 21)
	assert_almost_eq(stretch.x, 1.2, 0.0001)
	assert_almost_eq(stretch.y, 2.1, 0.0001)


func test_a_page_inks_on_to_the_timings_from_its_own_start() -> void:
	var times := _clip("You pulled. One life.").schedule(12, 15)
	assert_eq(times.size(), 4)
	assert_almost_eq(times[0], 0.0, 0.0001)
	assert_almost_eq(times[2], 0.2, 0.0001)
	assert_almost_eq(times[3], 0.3, 0.0001)


func test_a_page_knows_when_the_next_word_starts() -> void:
	var clip := _clip("You pulled. One life.")
	assert_almost_eq(clip.next_start(11), 1.2, 0.0001)
	assert_eq(clip.next_start(21), INF)


func test_without_timings_the_take_is_shared_out_evenly() -> void:
	var clip := VoiceClip.new()
	clip.text = "abcd"
	var times := clip.schedule(0, 4)
	assert_eq(times.size(), 5)
	assert_almost_eq(times[2] * 2.0, times[4], 0.0001)


func test_a_clip_plays_while_its_line_is_unchanged() -> void:
	assert_false(VoiceLibrary.find_entry(_manifest(), LineData.make("ch1.lever.pull.1", LINE_TEXT)).is_empty())


func test_a_rewritten_line_goes_quiet() -> void:
	assert_true(VoiceLibrary.find_entry(_manifest(), LineData.make("ch1.lever.pull.1", "You pulled. Two lives.")).is_empty())


func test_recolouring_a_line_keeps_its_voice() -> void:
	var recoloured := "You pulled. [red]One[/red] life."
	assert_false(VoiceLibrary.find_entry(_manifest(), LineData.make("ch1.lever.pull.1", recoloured)).is_empty())


func test_a_line_without_a_clip_has_none() -> void:
	assert_true(VoiceLibrary.find_entry(_manifest(), LineData.make("ch1.lever.ask.1", LINE_TEXT)).is_empty())


## A manifest holding one clip, made from [constant LINE_TEXT].
func _manifest() -> Dictionary:
	return {"ch1.lever.pull.1": {"speaker": "imp", "audio": "res://nowhere.mp3", "timing": "res://nowhere.json",
			"text_sha1": Markup.strip(LINE_TEXT).sha1_text()}}
