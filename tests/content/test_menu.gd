extends GutTest
## The main menu's words in content/menu.json load cleanly and follow the text rules, name only what the
## menu knows, and the imp never says the same bark twice running nor says Continue is greyed out while
## there is a run to continue. The endings page names every ending the run can reach, once each.

const MENU_PATH := "res://content/menu.json"
const RUN_PATH := "res://content/run.json"
const CHAPTERS_DIR := "res://content/chapters"
## What the endings page's count may fill in.
const COUNT_FILLS := ["found", "total"]
## Barks to pick in a row, to see none comes twice running.
const PICKS := 200

var _menu: MenuData
var _problems := PackedStringArray()


func before_all() -> void:
	var loader := ContentLoader.new()
	_menu = loader.load_menu(MENU_PATH)
	_problems = loader.problems


func test_the_menu_loads_without_problems() -> void:
	assert_not_null(_menu)
	assert_eq(_problems, PackedStringArray(), "\n".join(_problems))
	if _menu != null:
		assert_ne(_menu.title, "")
		assert_gt(_menu.lines_in(&"barks").size(), 1)
		assert_eq(_menu.lines_in(&"new_game").size(), 1)


func test_the_menu_follows_the_text_rules() -> void:
	var offenders := PackedStringArray()
	var texts := PackedStringArray([_menu.title])
	for line in _menu.all_lines():
		texts.append(line.text)
		for problem in Markup.tag_problems(line.text):
			offenders.append("%s: %s" % [line.id, problem])
	for text in texts:
		if Markup.has_dash(text) or Markup.has_stray_brace(text):
			offenders.append(text)
	if Markup.has_tags(_menu.title):
		offenders.append("the title carries a tag")
	assert_eq(offenders, PackedStringArray(), "\n".join(offenders))


func test_the_endings_page_names_every_ending_the_run_can_reach_once() -> void:
	var reachable := {}
	for chapter in ContentLoader.new(Profile.axis_ids()).load_run(RUN_PATH, CHAPTERS_DIR):
		for beat in chapter.beats:
			if not beat is QuestionData:
				continue
			var question := beat as QuestionData
			for ending in [question.ending] + question.endings.values():
				reachable[ending] = true
			for option in question.options:
				for ending in [option.ending] + option.endings.values():
					reachable[ending] = true
	reachable.erase(&"")
	var listed := _menu.ending_ids()
	var twice := listed.filter(func(id: StringName) -> bool: return listed.count(id) > 1)
	assert_eq(twice, [], "listed twice")
	assert_eq(listed.filter(func(id: StringName) -> bool: return not reachable.has(id)), [], "listed but never reached")
	assert_eq(reachable.keys().filter(func(id: StringName) -> bool: return not id in listed), [], "reached but not listed")


func test_the_endings_page_follows_the_text_rules() -> void:
	var offenders := PackedStringArray()
	var texts := PackedStringArray([_menu.endings_heading])
	for group in _menu.ending_groups:
		for ending: Dictionary in group:
			texts.append(ending["name"])
	for text in texts:
		if text.is_empty() or Markup.has_dash(text) or Markup.has_stray_brace(text) or Markup.has_tags(text):
			offenders.append(text)
	var count := _menu.endings_count
	for fill in Markup.placeholders(count):
		if not fill in COUNT_FILLS:
			offenders.append("the count fills %s" % fill)
	if Markup.has_dash(count) or Markup.has_tags(count):
		offenders.append(count)
	assert_eq(offenders, PackedStringArray(), "\n".join(offenders))


func test_lines_on_the_menu_name_only_what_the_menu_knows() -> void:
	var offenders := PackedStringArray()
	for line in _menu.all_lines():
		for fact in line.requires + line.excludes:
			if not StringName(fact) in MenuData.FACTS:
				offenders.append("%s names %s" % [line.id, fact])
	assert_eq(offenders, PackedStringArray(), "\n".join(offenders))


func test_no_bark_comes_twice_running() -> void:
	var imp := _imp(false)
	var last: LineData = null
	for i in PICKS:
		var bark := imp.pick_bark()
		assert_ne(bark, last)
		last = bark


func test_continue_is_only_called_greyed_out_when_it_is() -> void:
	var greyed := _greyed_out_bark()
	assert_not_null(greyed, "one bark says Continue is greyed out")
	var saved := _imp(true)
	for i in PICKS:
		assert_ne(saved.pick_bark(), greyed)
	var unsaved := _imp(false)
	var said := false
	for i in PICKS:
		said = said or unsaved.pick_bark() == greyed
	assert_true(said, "with nothing saved it can be said")


## A menu imp barking from the menu's barks, knowing whether a run is saved.
func _imp(run_saved: bool) -> MenuImp:
	var imp := MenuImp.new()
	autofree(imp)
	var facts := RunState.new()
	if run_saved:
		facts.remember(MenuData.RUN_SAVED)
	imp.use_barks(_menu.lines_in(&"barks"), facts)
	return imp


func _greyed_out_bark() -> LineData:
	for line in _menu.lines_in(&"barks"):
		if String(MenuData.RUN_SAVED) in line.excludes:
			return line
	return null
