extends GutTest
## The crowd reveal lays out only the bars it is showing: the last question's bars never push the next
## reveal off the top of the screen, however many there were.


func _reveal() -> CrowdReveal:
	# The reveal fills its parent, the screen.
	var screen := Control.new()
	screen.size = Vector2(ProjectSettings.get_setting("display/window/size/viewport_width"),
			ProjectSettings.get_setting("display/window/size/viewport_height"))
	add_child_autofree(screen)
	var reveal := (load("res://ui/reveal/crowd_reveal.tscn") as PackedScene).instantiate() as CrowdReveal
	screen.add_child(reveal)
	return reveal


func _split(count: int) -> RevealSplit:
	var split := RevealSplit.new()
	split.heading = "how others chose"
	for i in count:
		split.labels.append("Option %d" % (i + 1))
		split.shares.append(100.0 / count)
	split.pick = 0
	return split


func _rows_in(reveal: CrowdReveal) -> int:
	var count := 0
	for child in reveal.content.get_children():
		if child is CrowdRow:
			count += 1
	return count


func test_a_reveal_lays_out_only_its_own_bars() -> void:
	var reveal := _reveal()
	reveal.present(_split(4))
	reveal.dismiss()
	reveal.present(_split(5))
	assert_eq(_rows_in(reveal), 5, "the last reveal's four bars are gone at once")
	var first := reveal.content.position
	reveal.dismiss()
	reveal.present(_split(5))
	assert_eq(reveal.content.position, first, "the same bars sit in the same place, whatever came before")
	reveal.dismiss()


func test_a_tall_reveal_keeps_its_heading_on_the_screen() -> void:
	var reveal := _reveal()
	reveal.present(_split(6))
	assert_gte(reveal.content.position.y, reveal.top_margin)
	reveal.dismiss()
