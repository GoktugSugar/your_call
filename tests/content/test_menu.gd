extends GutTest
## The main menu's words in content/menu.json load cleanly and follow the text rules, name only what the
## menu knows, and the imp never says the same bark twice running nor says Continue is greyed out while
## there is a run to continue.

const MENU_PATH := "res://content/menu.json"
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
