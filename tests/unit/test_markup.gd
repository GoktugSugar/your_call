extends GutTest
## The colour tags and the mechanical text rules.


func test_strip_removes_tags_and_keeps_words() -> void:
	assert_eq(Markup.strip("the [amber]five[/amber] on the track will [red]die[/red]"), "the five on the track will die")


func test_to_bbcode_turns_tags_into_palette_colours() -> void:
	var palette := InkPalette.get_default()
	var bbcode := Markup.to_bbcode("[amber]five[/amber] souls", palette)
	assert_eq(bbcode, "[color=#%s]five[/color] souls" % palette.amber.to_html(false))


func test_to_bbcode_shows_unknown_tags_and_brackets_literally() -> void:
	var bbcode := Markup.to_bbcode("[green]grass[/green] and [", InkPalette.get_default())
	assert_eq(bbcode, "[lb]green]grass[lb]/green] and [lb]")


func test_well_formed_text_has_no_tag_problems() -> void:
	assert_eq(Markup.tag_problems("You pulled. [amber]One[/amber] life swapped for [amber]five[/amber]."), PackedStringArray())


func test_unknown_tag_is_a_problem() -> void:
	assert_eq(Markup.tag_problems("[green]go[/green]").size(), 2)


func test_unclosed_tag_is_a_problem() -> void:
	assert_eq(Markup.tag_problems("[red]dead"), PackedStringArray(["[red] is never closed"]))


func test_nested_tags_are_a_problem() -> void:
	assert_has(Markup.tag_problems("[red]a [amber]b[/amber][/red]"), "[amber] opens inside [red]")


func test_mismatched_close_is_a_problem() -> void:
	assert_has(Markup.tag_problems("[red]a[/amber]"), "[/amber] closes [red]")


func test_stray_bracket_is_a_problem() -> void:
	assert_has(Markup.tag_problems("a [b"), "stray square bracket")


func test_every_dash_counts_as_a_dash() -> void:
	for dash in Markup.DASHES:
		assert_true(Markup.has_dash("six%syear old" % dash), "should catch U+%04X" % dash.unicode_at(0))


func test_plain_text_has_no_dash() -> void:
	assert_false(Markup.has_dash("six year old children, a 100 dollar cucumber"))
