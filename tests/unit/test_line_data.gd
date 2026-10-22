extends GutTest
## Lines with placeholders: the names are found, a filling keeps everything but the text, and each
## filling gets an id of its own so it can have a voice clip of its own.


func test_placeholders_are_found_in_order() -> void:
	var line := LineData.make("ch2.nuke.press.mid.1", "Oh, [amber]{country}[/amber]. [amber]{people}[/amber] people.")
	assert_eq(Array(line.placeholders()), ["country", "people"])


func test_a_filled_line_reads_its_fills_and_names_its_variant() -> void:
	var line := LineData.make("ch2.price.refuse.1", "[amber]{amount}[/amber] was the number.", &"imp", &"smug")
	line.direction = "[flat]"
	var filled := line.filled({"amount": "$3,125"}, "3125")
	assert_eq(filled.text, "[amber]$3,125[/amber] was the number.")
	assert_eq(filled.id, "ch2.price.refuse.1.3125")
	assert_eq(filled.face, &"smug")
	assert_eq(filled.direction, "[flat]")
	assert_eq(line.text, "[amber]{amount}[/amber] was the number.", "the original is left as it was")


func test_filling_without_a_variant_keeps_the_id() -> void:
	var line := LineData.make("ch2.price.ask.1", "{amount} is yours.")
	assert_eq(line.filled({"amount": "$5"}).id, "ch2.price.ask.1")


func test_filling_a_list_leaves_plain_lines_alone() -> void:
	var plain := LineData.make("a.1", "No placeholders.")
	var held := LineData.make("a.2", "{count} dead.")
	var lines: Array[LineData] = [plain, held]
	var filled := LineData.fill_all(lines, {"count": "3"}, "3")
	assert_same(filled[0], plain)
	assert_eq(filled[1].text, "3 dead.")


func test_a_brace_that_frames_nothing_is_stray() -> void:
	assert_false(Markup.has_stray_brace("{amount} banked"))
	assert_true(Markup.has_stray_brace("an {open brace"))
	assert_true(Markup.has_stray_brace("{Amount}"))
