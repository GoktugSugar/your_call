extends GutTest
## Floating words: they ink on at a steady pace, or are said aloud and ink on in time with a voice,
## and they are done being said only once the voice has played out.

const SCENE := "res://stages/trolley/plea.tscn"
## How long the test's silent take lasts, in seconds.
const TAKE_SECONDS := 0.6
## Seconds to wait for the words to be said before giving up.
const MAX_WAIT := 5.0


func _plea(words: String) -> Plea:
	var plea := (load(SCENE) as PackedScene).instantiate() as Plea
	add_child_autofree(plea)
	plea.set_words(words)
	return plea


## A silent take of [param text], [constant TAKE_SECONDS] long, its characters spread evenly over it.
func _take(text: String) -> VoiceClip:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var data := PackedByteArray()
	data.resize(int(TAKE_SECONDS * stream.mix_rate) * 2)
	stream.data = data
	var clip := VoiceClip.new()
	clip.stream = stream
	clip.text = text
	for i in text.length():
		clip.starts.append(TAKE_SECONDS * i / text.length())
		clip.ends.append(TAKE_SECONDS * (i + 1) / text.length())
	return clip


func test_words_without_a_voice_ink_on_and_are_said() -> void:
	var plea := _plea("Please.")
	plea.write_on()
	assert_true(plea.is_saying())
	assert_true(await wait_for_signal(plea.said, MAX_WAIT), "the words are said")
	assert_false(plea.is_saying())


func test_words_with_a_voice_play_it() -> void:
	var plea := _plea("Ow.")
	plea.write_on(_take("Ow."))
	assert_true(plea.voice_player.playing)
	assert_eq(plea.voice_player.bus, &"Voice")


func test_words_with_a_voice_are_said_once_it_has_played_out() -> void:
	var plea := _plea("Ow.")
	var started := Time.get_ticks_msec()
	plea.write_on(_take("Ow."))
	assert_true(await wait_for_signal(plea.said, MAX_WAIT), "the words are said")
	assert_false(plea.voice_player.playing)
	assert_gt((Time.get_ticks_msec() - started) / 1000.0, TAKE_SECONDS * 0.8, "the take plays out first")


func test_a_line_kept_silent_has_no_voice() -> void:
	var line := LineData.make("ch2.walks_away.stage.1", "Ow!", &"button")
	line.voiced = false
	assert_null(VoiceLibrary.clip_for(line))
