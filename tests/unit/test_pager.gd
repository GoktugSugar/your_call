extends GutTest
## Paging narration into dialogue boxes by whole sentences.


## A box that fits at most [param limit] characters of plain text.
func _fits_up_to(limit: int) -> Callable:
	return func(markup: String) -> bool: return Markup.strip(markup).length() <= limit


func test_sentences_split_at_full_stops_question_and_exclamation_marks() -> void:
	assert_eq(Pager.sentences("One. Two? Three! Four"), PackedStringArray(["One.", "Two?", "Three!", "Four"]))


func test_sentence_keeps_a_tag_that_closes_after_its_full_stop() -> void:
	assert_eq(Pager.sentences("Look at the [amber]five.[/amber] Then decide."),
			PackedStringArray(["Look at the [amber]five.[/amber]", "Then decide."]))


func test_a_full_stop_inside_a_word_does_not_split() -> void:
	assert_eq(Pager.sentences("It costs 2.50 now. Pay."), PackedStringArray(["It costs 2.50 now.", "Pay."]))


func test_text_that_fits_stays_on_one_page() -> void:
	assert_eq(Pager.paginate("One. Two. Three.", _fits_up_to(100)), PackedStringArray(["One. Two. Three."]))


func test_long_text_uses_as_few_pages_as_fit() -> void:
	var pages := Pager.paginate("Aaaa. Bbbb. Cccc. Dddd.", _fits_up_to(11))
	assert_eq(pages.size(), 2)


func test_pages_are_spread_evenly() -> void:
	# Packing greedily would fill the first box with three sentences and leave one alone on the second.
	var pages := Pager.paginate("Aaaa. Bbbb. Cccc. Dddd.", _fits_up_to(17))
	assert_eq(pages, PackedStringArray(["Aaaa. Bbbb.", "Cccc. Dddd."]))


func test_a_sentence_too_long_for_a_box_is_never_split() -> void:
	var pages := Pager.paginate("This sentence is far too long. Short.", _fits_up_to(10))
	assert_eq(pages, PackedStringArray(["This sentence is far too long.", "Short."]))


func test_a_tag_open_across_a_page_break_closes_and_reopens() -> void:
	var pages := Pager.paginate("[red]One. Two.[/red]", _fits_up_to(5))
	assert_eq(pages, PackedStringArray(["[red]One.[/red]", "[red]Two.[/red]"]))
