extends GutTest
## Outside a browser every voice is in the game already: a chapter's voice is always ready, and waiting
## for it never holds the run up.

const PACKS_SCENE := "res://game/voice/voice_packs.tscn"


func test_outside_a_browser_every_chapter_is_ready_at_once() -> void:
	var packs: Node = (load(PACKS_SCENE) as PackedScene).instantiate()
	add_child_autofree(packs)
	assert_true(packs.call(&"ready_for", &"ch8"))
	assert_eq(packs.get(&"packs"), PackedStringArray(), "nothing to fetch")
	var started := Time.get_ticks_msec()
	await packs.call(&"wait_for", &"ch8", 5.0)
	assert_lt(Time.get_ticks_msec() - started, 100, "no wait")
