extends GutTest
## Lines with placeholders: the names are found, a filling keeps everything but the text, and each
## filling gets an id of its own, from the values the line uses, so it can have a voice clip of its own.


func test_placeholders_are_found_in_order() -> void:
	var line := LineData.make("ch2.nuke.press.mid.1", "Oh, [amber]{country}[/amber]. [amber]{people}[/amber] people.")
	assert_eq(Array(line.placeholders()), ["country", "people"])


func test_a_filled_line_reads_its_fills_and_is_named_by_the_values_it_uses() -> void:
	var line := LineData.make("ch2.price.refuse.1", "[amber]{amount}[/amber] was the number.", &"imp", &"smug")
	line.direction = "[flat]"
	var filled := line.filled({"amount": "$3,125", "count": "5"}, {"amount": "3125", "count": "5"})
	assert_eq(filled.text, "[amber]$3,125[/amber] was the number.")
	assert_eq(filled.id, "ch2.price.refuse.1.3125")
	assert_eq(filled.face, &"smug")
	assert_eq(filled.direction, "[flat]")
	assert_eq(line.text, "[amber]{amount}[/amber] was the number.", "the original is left as it was")


func test_values_that_share_a_key_name_the_filling_once() -> void:
	var line := LineData.make("ch2.nuke.press.huge.1", "{country}. {people} people. So is {country}.")
	var filled := line.filled({"country": "India", "people": "1,430,000,000"}, {"country": "IN", "people": "IN"})
	assert_eq(filled.id, "ch2.nuke.press.huge.1.IN")


func test_a_value_without_a_key_is_named_by_its_letters_and_digits() -> void:
	var line := LineData.make("a.1", "{amount} is yours.")
	assert_eq(line.filled({"amount": "$5,000"}).id, "a.1.5000")


func test_a_line_without_placeholders_comes_back_as_it_is() -> void:
	var plain := LineData.make("a.1", "No placeholders.")
	assert_same(plain.filled({"amount": "$5"}), plain)


func test_filling_a_list_fills_each_line() -> void:
	var plain := LineData.make("a.1", "No placeholders.")
	var held := LineData.make("a.2", "{count} dead.")
	var lines: Array[LineData] = [plain, held]
	var filled := LineData.fill_all(lines, {"count": "3"}, {"count": "3"})
	assert_same(filled[0], plain)
	assert_eq(filled[1].text, "3 dead.")
	assert_eq(filled[1].id, "a.2.3")


func test_a_brace_that_frames_nothing_is_stray() -> void:
	assert_false(Markup.has_stray_brace("{amount} banked"))
	assert_true(Markup.has_stray_brace("an {open brace"))
	assert_true(Markup.has_stray_brace("{Amount}"))


func test_a_filled_line_keeps_its_voice() -> void:
	var line := LineData.make("ch7.loan.ask.3", "I carried him for {amount}.", &"confessor")
	line.voice = &"loan"
	assert_eq(line.filled({"amount": "a year"}).voice, &"loan")
