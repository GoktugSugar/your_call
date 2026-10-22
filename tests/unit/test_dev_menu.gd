extends GutTest
## The dev menu: the list of chapters with the picked chapter's questions beside it, a long chapter in even
## columns, the question being played marked and focused, and a pick naming its chapter and beat.

const MENU_SCENE := "res://dev/dev_menu.tscn"


func test_lists_every_chapter_and_shows_the_one_being_played() -> void:
	var menu := _menu()
	menu.open(_chapters([3, 5, 2]), &"c2", &"")
	assert_eq(menu.chapter_list.get_child_count(), 3)
	assert_eq(_shown(menu), [&"c2"])
	menu.close()


func test_a_long_chapter_breaks_into_even_columns() -> void:
	var menu := _menu()
	menu.most_rows = 16
	menu.open(_chapters([23]), &"c1", &"")
	var page := menu.pages.get_child(0)
	assert_eq(page.get_child_count(), 2)
	assert_eq(page.get_child(0).get_child_count(), 12)
	assert_eq(page.get_child(1).get_child_count(), 12)
	menu.close()


func test_reaching_or_clicking_a_chapter_shows_its_questions() -> void:
	var menu := _menu()
	menu.open(_chapters([3, 5, 2]), &"c1", &"")
	(menu.chapter_list.get_child(2) as Button).grab_focus()
	assert_eq(_shown(menu), [&"c3"])
	(menu.chapter_list.get_child(1) as Button).pressed.emit()
	assert_eq(_shown(menu), [&"c2"])
	menu.close()


func test_the_question_being_played_is_marked_and_focused() -> void:
	var menu := _menu()
	menu.open(_chapters([3, 5]), &"c2", &"c2_q4")
	var focused := menu.get_viewport().gui_get_focus_owner() as Button
	assert_not_null(focused)
	if focused != null:
		assert_eq(focused.text, "%s 2.04  Question 4" % menu.now_mark)
	menu.close()


func test_picking_an_entry_names_its_chapter_and_beat() -> void:
	var menu := _menu()
	watch_signals(menu)
	menu.open(_chapters([3, 5]), &"c1", &"")
	var page := menu.pages.get_child(1)
	(page.get_child(0).get_child(3) as Button).pressed.emit()
	assert_signal_emitted_with_parameters(menu, "picked", [&"c2", &"c2_q3"])
	menu.close()


## The ids of the chapters whose questions [param menu] shows.
func _shown(menu: DevMenu) -> Array[StringName]:
	var shown: Array[StringName] = []
	for i in menu.pages.get_child_count():
		if (menu.pages.get_child(i) as Control).visible:
			shown.append(StringName("c%d" % (i + 1)))
	return shown


## Chapters c1, c2 and on, each with as many questions as [param counts] says, numbered like 2.04.
func _chapters(counts: Array[int]) -> Array[ChapterData]:
	var chapters: Array[ChapterData] = []
	for c in counts.size():
		var chapter := ChapterData.new()
		chapter.id = StringName("c%d" % (c + 1))
		chapter.title = "Chapter %d" % (c + 1)
		for q in counts[c]:
			var question := QuestionData.new()
			question.id = StringName("c%d_q%d" % [c + 1, q + 1])
			question.number = "%d.%02d" % [c + 1, q + 1]
			question.title = "Question %d" % (q + 1)
			chapter.beats.append(question)
		chapters.append(chapter)
	return chapters


func _menu() -> DevMenu:
	var menu := (load(MENU_SCENE) as PackedScene).instantiate() as DevMenu
	add_child_autofree(menu)
	return menu
