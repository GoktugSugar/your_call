class_name MainMenu
extends Node
## The main menu, the page the game opens on: the hand-lettered title, then New Game, Continue, Endings,
## Settings and Quit, the current one in amber, with the imp beside them saying his barks. Continue is
## greyed out when there is no saved run to pick up; after an ending there is one, just before it.
## New Game asks first when there is one: the imp puts the question and the column turns into its
## answers. Endings turns the column into the endings found so far, Settings into the settings page,
## and the imp keeps quiet over either.
## Leaving for the run, the eyes close on the page, and the run opens behind them.

@export_file("*.json") var menu_path := "res://content/menu.json"
## The run: which chapters play, in order. Continue checks its save against them.
@export_file("*.json") var run_path := "res://content/run.json"
## Where the chapter files are.
@export_dir var chapters_dir := "res://content/chapters"
## The run's scene, which New Game and Continue go to.
@export_file("*.tscn") var run_scene := "res://game/main.tscn"

@export var title: MenuTitle
## The menu's entries.
@export var column: MenuList
@export var new_game_word: MenuWord
@export var continue_word: MenuWord
@export var endings_word: MenuWord
@export var settings_word: MenuWord
@export var quit_word: MenuWord
## The answers to New Game's question, when there is a run to lose.
@export var confirm: MenuList
@export var start_over_word: MenuWord
@export var keep_word: MenuWord
## The settings, in place of the entries.
@export var settings: SettingsPage
## The endings found so far, in place of the entries.
@export var endings: EndingsPage
## The imp on the page, and his barks.
@export var menu_imp: MenuImp
## The eyes that close on the page as it is left, and open on it after the run was quit.
@export var eyelids: Eyelids
## Development tools added in debug builds only.
@export var dev_tools_scene: PackedScene

@export_group("Timing")
## Seconds after the title starts inking on before the entries come up.
@export_range(0.0, 5.0, 0.05) var column_delay := 0.5
## Seconds the entries take to fade in.
@export_range(0.0, 3.0, 0.05) var column_fade := 0.35
## Seconds after the entries before the imp scribbles in.
@export_range(0.0, 10.0, 0.05) var imp_delay := 0.6

## Whether the eyes open on the page as it comes up: they had closed on the run that was left for it.
static var opens_eyes := false

## The chapters of the run, for Continue's check and the dev tools.
var chapters: Array[ChapterData] = []
## The menu's words: the title and the imp's lines.
var menu: MenuData

## The saved run Continue picks up, or null.
var _save: RunSave
var _leaving := false


func _ready() -> void:
	PlayerSettings.load_saved()
	get_tree().paused = false
	Music.play()
	Music.duck(false)
	Sfx.duck(false)
	var loader := ContentLoader.new(Profile.axis_ids())
	chapters = loader.load_run(run_path, chapters_dir)
	menu = loader.load_menu(menu_path)
	for problem in loader.problems:
		push_error(problem)
	_save = RunSave.load_valid(chapters)
	if OS.is_debug_build() and dev_tools_scene != null:
		var tools := dev_tools_scene.instantiate()
		tools.set(&"main_menu", self)
		add_child(tools)
	if _leaving:
		return
	_wire()
	_come_up()


## Goes to the run at once, with no eyes closing: the dev tools drop straight into it.
func go_to_run() -> void:
	_leaving = true
	get_tree().change_scene_to_file.call_deferred(run_scene)


## Whether there is a saved run Continue can pick up.
func has_save() -> bool:
	return _save != null


func _wire() -> void:
	new_game_word.pressed.connect(_on_new_game)
	continue_word.pressed.connect(_on_continue)
	endings_word.pressed.connect(_on_endings)
	settings_word.pressed.connect(_on_settings)
	quit_word.pressed.connect(func() -> void:
		if not _leaving:
			get_tree().quit())
	start_over_word.pressed.connect(_on_start_over)
	keep_word.pressed.connect(_on_keep)
	settings.closed.connect(_on_settings_closed)
	endings.closed.connect(_on_endings_closed)
	settings.volume_changed.connect(_on_volume_changed)
	continue_word.set_greyed(_save == null)
	confirm.hide()
	column.modulate.a = 0.0


## The page comes up: the eyes open if they had closed on the run, the title inks on, the entries come
## up with the current one lit, and the imp scribbles himself in.
func _come_up() -> void:
	if opens_eyes:
		opens_eyes = false
		eyelids.shut()
		await eyelids.open()
	title.set_title(menu.title if menu != null else "")
	title.ink_on()
	await get_tree().create_timer(column_delay).timeout
	create_tween().tween_property(column, ^"modulate:a", 1.0, column_fade)
	column.link()
	column.focus(continue_word if has_save() else new_game_word)
	await get_tree().create_timer(imp_delay).timeout
	if menu != null and not _leaving:
		menu_imp.start(menu.lines_in(&"barks"), _facts())


func _unhandled_input(event: InputEvent) -> void:
	if confirm.visible and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_keep()


## What the menu knows, for which of the imp's lines hold.
func _facts() -> RunState:
	var facts := RunState.new()
	if has_save():
		facts.remember(MenuData.RUN_SAVED)
	return facts


func _on_new_game() -> void:
	if _leaving:
		return
	if not has_save():
		_leave_for_run(null)
		return
	column.hide()
	confirm.show()
	confirm.link()
	confirm.focus(keep_word)
	var question := menu.lines_in(&"new_game") if menu != null else []
	if not question.is_empty():
		menu_imp.ask(question[0])


func _on_start_over() -> void:
	if _leaving:
		return
	RunSave.clear()
	_save = null
	_leave_for_run(null)


func _on_keep() -> void:
	if _leaving or not confirm.visible:
		return
	confirm.hide()
	column.show()
	column.focus(new_game_word)
	menu_imp.let_go()


func _on_continue() -> void:
	if _leaving or not has_save():
		return
	_leave_for_run(_save)


func _on_endings() -> void:
	if _leaving or menu == null:
		return
	column.hide()
	menu_imp.hush()
	endings.open(menu, EndingsRecord.seen())


func _on_endings_closed() -> void:
	column.show()
	column.focus(endings_word)
	menu_imp.let_go()


func _on_settings() -> void:
	if _leaving:
		return
	column.hide()
	menu_imp.hush()
	settings.open()


func _on_settings_closed() -> void:
	column.show()
	column.focus(settings_word)
	menu_imp.let_go()


## A change to the voices' volume is heard at once: the imp says a bark at the new level, unless he is
## saying one already, which the new level reaches as it plays.
func _on_volume_changed(bus: StringName, _level: int) -> void:
	if bus != &"Voice" or menu_imp.is_saying():
		return
	var bark := menu_imp.pick_bark()
	if bark != null:
		menu_imp.say_once(bark)


## The imp falls silent, the eyes close on the page, and the run begins: a new one, or [param save]
## picked up where it was left.
func _leave_for_run(save: RunSave) -> void:
	_leaving = true
	RunSave.pending = save
	var focused := get_viewport().gui_get_focus_owner()
	if focused != null:
		focused.release_focus()
	menu_imp.hush()
	await eyelids.close()
	get_tree().change_scene_to_file(run_scene)
