extends GutTest
## The choice row lays out only the words it is offering, so the last offer's words never push a row
## off the screen.


func _row() -> ChoiceRow:
	# The row fills its parent, the screen.
	var screen := Control.new()
	screen.size = Vector2(ProjectSettings.get_setting("display/window/size/viewport_width"),
			ProjectSettings.get_setting("display/window/size/viewport_height"))
	add_child_autofree(screen)
	var row := (load("res://ui/choices/choice_row.tscn") as PackedScene).instantiate() as ChoiceRow
	screen.add_child(row)
	return row


func test_a_row_holds_only_the_words_on_offer() -> void:
	var row := _row()
	row.lay_out(PackedStringArray(["For the gold", "For the glory", "To save someone", "Nowhere else to be"]))
	row.lay_out(PackedStringArray(["Take the job", "Haggle harder", "Threaten him"]))
	assert_eq(row.row.get_child_count(), 3, "the last offer's words are gone at once")
	assert_true(row.fits())


func test_a_long_row_closes_up_to_fit() -> void:
	var row := _row()
	row.lay_out(PackedStringArray(["Take the job", "Haggle harder", "Threaten him", "Walk away",
			"Make him swear it on his honour"]))
	assert_true(row.fits())
	assert_lte(row.row.get_combined_minimum_size().x, row.size.x)
