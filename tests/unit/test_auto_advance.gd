extends GutTest
## Auto skip: with the player setting on, each page moves on by itself once it has been said, while the
## page a choice follows stays up; with it off, a page waits for a click.

const BOX_SCENE := "res://ui/dialogue/dialogue_box.tscn"
## Seconds to wait for a page to move on before giving up.
const MAX_WAIT := 5.0
## Seconds to watch a page that should stay up.
const WATCH := 1.5

var _auto_advance := false


func before_each() -> void:
	_auto_advance = PlayerSettings.auto_advance


func after_each() -> void:
	PlayerSettings.auto_advance = _auto_advance


## A box that types fast and moves on quickly, so the tests do not wait on its pacing.
func _box() -> DialogueBox:
	var box := (load(BOX_SCENE) as PackedScene).instantiate() as DialogueBox
	add_child_autofree(box)
	box.characters_per_second = 400.0
	box.auto_hold = 0.1
	return box


## Two unvoiced lines.
func _lines() -> Array[LineData]:
	return [LineData.make("test.auto.1", "One."), LineData.make("test.auto.2", "Two.")]


func test_with_auto_skip_on_a_page_moves_on_by_itself() -> void:
	PlayerSettings.auto_advance = true
	var box := _box()
	box.say(_lines())
	assert_true(await wait_for_signal(box.advanced, MAX_WAIT), "the page moves on")


func test_with_auto_skip_off_a_page_waits_for_a_click() -> void:
	PlayerSettings.auto_advance = false
	var box := _box()
	box.say(_lines())
	assert_false(await wait_for_signal(box.advanced, WATCH), "the page waits")
	assert_true(box.is_waiting())


func test_turning_auto_skip_on_takes_a_waiting_page_along() -> void:
	PlayerSettings.auto_advance = false
	var box := _box()
	box.say(_lines())
	assert_true(await wait_until(box.is_waiting, MAX_WAIT), "the page is up and waiting")
	PlayerSettings.auto_advance = true
	assert_true(await wait_for_signal(box.advanced, MAX_WAIT), "the page moves on")


func test_the_page_a_choice_follows_stays_up() -> void:
	PlayerSettings.auto_advance = true
	var box := _box()
	await box.say([LineData.make("test.auto.1", "Your call.")], true)
	assert_false(await wait_for_signal(box.advanced, WATCH), "the page stays up for the choice")
