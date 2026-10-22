extends GutTest
## The imp's talking mouth: how open each sound sets it, that it only moves while he talks and rests in
## his face's own shape when he stops, and that it changes shape in eased steps rather than every frame.

const IMP_SCENE := "res://figures/imp/imp.tscn"
## A rate and a frame length that add up exactly in binary, so a step lands on a known frame.
const SHAPES_PER_SECOND := 8.0
const FRAME := 1.0 / 32.0
const FRAMES_PER_SHAPE := 4
## Long enough for any shape to settle.
const SETTLE_FRAMES := 64

var _mouth: ImpMouth


func before_each() -> void:
	_mouth = autofree(ImpMouth.new())


func test_vowels_open_it_widest() -> void:
	for vowel in ["a", "e", "i", "o", "u", "y"]:
		assert_eq(_mouth.openness(vowel), _mouth.on_vowels, vowel)
	assert_gt(_mouth.on_vowels, _mouth.on_consonants)


func test_other_consonants_open_it_half_way() -> void:
	for sound in ["t", "k", "s", "r", "l", "n", "h", "w", "g", "d"]:
		assert_eq(_mouth.openness(sound), _mouth.on_consonants, sound)
	assert_gt(_mouth.on_consonants, _mouth.on_f_and_v)


func test_f_and_v_open_it_a_little() -> void:
	for sound in ["f", "v"]:
		assert_eq(_mouth.openness(sound), _mouth.on_f_and_v, sound)
	assert_gt(_mouth.on_f_and_v, _mouth.on_m_b_and_p)


func test_m_b_and_p_all_but_shut_it() -> void:
	for sound in ["m", "b", "p"]:
		assert_eq(_mouth.openness(sound), _mouth.on_m_b_and_p, sound)
	assert_gt(_mouth.on_m_b_and_p, _mouth.on_pauses)


func test_spaces_and_punctuation_shut_it() -> void:
	for pause in [" ", ".", ",", "?", "!", ":", ";", "'"]:
		assert_eq(_mouth.openness(pause), _mouth.on_pauses, "'%s'" % pause)
	assert_eq(_mouth.on_pauses, 0.0)


func test_nothing_being_said_shuts_it() -> void:
	assert_eq(_mouth.openness(""), _mouth.on_pauses)


func test_capitals_open_it_as_their_letters_do() -> void:
	for sound in ["a", "m", "f", "t"]:
		assert_eq(_mouth.openness(sound.to_upper()), _mouth.openness(sound), sound.to_upper())


func test_digits_are_said_aloud() -> void:
	assert_eq(_mouth.openness("7"), _mouth.on_consonants)


func test_his_mouth_rests_while_he_is_not_talking() -> void:
	var imp := _imp_saying("a")
	simulate(imp, SETTLE_FRAMES, FRAME)
	assert_eq(imp.drawing.mouth_open, 0.0)


func test_his_mouth_opens_to_what_he_says_while_he_talks() -> void:
	var imp := _imp_saying("a")
	imp.set_talking(true)
	simulate(imp, SETTLE_FRAMES, FRAME)
	assert_eq(imp.drawing.mouth_open, imp.mouth.on_vowels)


func test_his_mouth_rests_in_his_face_when_he_stops() -> void:
	var imp := _imp_saying("a")
	imp.set_talking(true)
	simulate(imp, SETTLE_FRAMES, FRAME)
	imp.set_talking(false)
	simulate(imp, SETTLE_FRAMES, FRAME)
	assert_eq(imp.drawing.mouth_open, 0.0)


func test_switched_off_his_mouth_keeps_his_face() -> void:
	var imp := _imp_saying("a")
	imp.mouth.moving = false
	imp.set_talking(true)
	simulate(imp, SETTLE_FRAMES, FRAME)
	assert_eq(imp.drawing.mouth_open, 0.0)


func test_without_speech_his_mouth_keeps_his_face() -> void:
	var imp := (load(IMP_SCENE) as PackedScene).instantiate() as Imp
	add_child_autofree(imp)
	imp.set_talking(true)
	simulate(imp, SETTLE_FRAMES, FRAME)
	assert_eq(imp.drawing.mouth_open, 0.0)


func test_his_mouth_changes_shape_in_steps() -> void:
	var imp := _imp_saying("a")
	imp.set_talking(true)
	var shown := imp.drawing.mouth_open
	var changes := 0
	for frame in range(1, SETTLE_FRAMES + 1):
		simulate(imp, 1, FRAME)
		if imp.drawing.mouth_open != shown:
			assert_eq(frame % FRAMES_PER_SHAPE, 0, "it changed shape on frame %d, between steps" % frame)
			shown = imp.drawing.mouth_open
			changes += 1
	assert_gt(changes, 1, "it eased over more than one shape")


func test_each_shape_eases_part_of_the_way_to_the_sound() -> void:
	var imp := _imp_saying("a")
	imp.set_talking(true)
	simulate(imp, FRAMES_PER_SHAPE, FRAME)
	assert_almost_eq(imp.drawing.mouth_open, imp.mouth.on_vowels * imp.mouth.easing, 0.0001)


## The imp from his scene, saying [param sound] for as long as he talks, at a rate the tests can count frames by.
func _imp_saying(sound: String) -> Imp:
	var imp := (load(IMP_SCENE) as PackedScene).instantiate() as Imp
	add_child_autofree(imp)
	imp.mouth.shapes_per_second = SHAPES_PER_SECOND
	imp.set_speech(func(_lead: float) -> String: return sound)
	return imp
