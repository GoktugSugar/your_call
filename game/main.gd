class_name Main
extends Node
## The run, once the menu hands over to it: it plays the chapters in content/run.json in order, from the
## crash, or from the beat a continued run was saved at, the eyes opening on it first. It wires the imp to
## the dialogue box, saves as each beat begins, holds the run still on Esc, and goes back to the main menu
## when the run is over, after an ending's credits or the last chapter's closing line, or when the player
## quits to it.

## The run: which chapters play, in order.
@export_file("*.json") var run_path := "res://content/run.json"
## Where the chapter files are.
@export_dir var chapters_dir := "res://content/chapters"
## The main menu, which the run goes back to.
@export_file("*.tscn") var menu_scene := "res://ui/menu/main_menu.tscn"
## The chapter to start from, by id. Empty starts at the first.
@export var start_chapter := &""
## The beat to start from in that chapter. Empty starts at the top of the chapter.
@export var start_beat := &""
## The cinematic a continued run opens on, unless the beat it picks up at is a cinematic of its own.
@export var resume_opening := &"eyes_open"
## Seconds between the run ending and the menu coming up.
@export_range(0.0, 10.0, 0.05) var pause_between := 1.2

@export var run_player: RunPlayer
@export var question_player: QuestionPlayer
@export var imp: Imp
@export var dialogue: DialogueBox
## The money chapter's balance, at the top of the screen while its wallet is open.
@export var balance: BalanceReadout
## Saves the run as each beat begins.
@export var auto_save: AutoSave
## Holds the run still on Esc.
@export var pause_menu: PauseMenu
## Development tools added in debug builds only.
@export var dev_tools_scene: PackedScene

## What the run remembers, the silent portrait among it: fresh for a new run, the save's for a
## continued one.
var run := RunState.new()
## The silent portrait of the player, for this run.
var profile: Profile:
	get:
		return run.profile
## The chapters of the run, in order.
var chapters: Array[ChapterData] = []

## Who says the page up in the dialogue box: only the imp's own pages move his mouth and his feet.
var _speaker := &"imp"
## Whether the run has been left for the menu.
var _left := false


func _ready() -> void:
	PlayerSettings.load_saved()
	if OS.is_debug_build() and dev_tools_scene != null:
		var tools := dev_tools_scene.instantiate()
		tools.set(&"main", self)
		add_child(tools)
	chapters = _load_run()
	if chapters.is_empty():
		push_error("Main: no chapters to play in %s" % run_path)
		return
	var resumed := RunSave.take_pending()
	if resumed != null:
		start_chapter = resumed.chapter
		start_beat = resumed.beat
		run = resumed.run
	_check_start(chapters)
	dialogue.page_shown.connect(_on_page_shown)
	question_player.imp_face_cued.connect(_on_imp_face_cued)
	dialogue.talking_changed.connect(_on_talking_changed)
	dialogue.talking_changed.connect(Music.duck)
	imp.set_speech(dialogue.spoken_character)
	pause_menu.quit_requested.connect(_leave_for_menu)
	auto_save.run = run
	if balance != null:
		balance.watch(run)
	pause_menu.active = true
	if resumed != null and not _starts_on_cinematic():
		await run_player.play_cinematic(resume_opening)
	var ending := await run_player.play_run(chapters, run, start_chapter, start_beat, resumed == null)
	if ending == &"":
		auto_save.finish()
	await get_tree().create_timer(pause_between, false).timeout
	_leave_for_menu()


## Goes back to the main menu, the game no longer held still and the music no longer dipped.
func _leave_for_menu() -> void:
	if _left or not is_inside_tree():
		return
	_left = true
	MainMenu.opens_eyes = pause_menu.is_open()
	pause_menu.active = false
	get_tree().paused = false
	Music.duck(false)
	get_tree().change_scene_to_file(menu_scene)


## Whether the run starts on a cinematic, such as the crash or a chapter's waking.
func _starts_on_cinematic() -> bool:
	for chapter in chapters:
		if chapter.id == start_chapter or start_chapter == &"":
			var beat: BeatData = chapter.find_beat(start_beat) if start_beat != &"" else null
			if beat == null and not chapter.beats.is_empty():
				beat = chapter.beats[0]
			return beat is CinematicData
	return false


## The chapters of the run, in order.
func _load_run() -> Array[ChapterData]:
	var loader := ContentLoader.new(Profile.axis_ids())
	var loaded := loader.load_run(run_path, chapters_dir)
	for problem in loader.problems:
		push_error(problem)
	return loaded


## Falls back to the top of the run when the chapter or beat to start from does not exist. A beat
## given without a chapter starts in the first chapter that has it.
func _check_start(chapters: Array[ChapterData]) -> void:
	var first: ChapterData = chapters[0]
	if start_chapter == &"" and start_beat != &"":
		for chapter in chapters:
			if chapter.find_beat(start_beat) != null:
				start_chapter = chapter.id
				break
	if start_chapter != &"":
		first = null
		for chapter in chapters:
			if chapter.id == start_chapter:
				first = chapter
		if first == null:
			push_error("Main: no chapter '%s' in the run, starting at the top." % start_chapter)
			start_chapter = &""
			start_beat = &""
			return
	if start_beat != &"" and first.find_beat(start_beat) == null:
		push_error("Main: no beat '%s' in %s, starting at its top." % [start_beat, first.id])
		start_beat = &""


## Each page of the imp's sets his face (his grin unless the line asks for another) and may send him
## drifting to a fresh spot; a new line may send him roaming, when the page is his. While someone else
## speaks in the box, such as a confessor, he keeps still and listens.
func _on_page_shown(line: LineData, page: int, _page_count: int) -> void:
	_speaker = line.speaker
	if _speaker != &"imp":
		return
	imp.set_face(ImpDrawing.face_named(line.face))
	if page == 0:
		imp.move_for_line()
	else:
		imp.move_if_settled()


## The imp talks while his own pages ink on and their voice plays, and only then.
func _on_talking_changed(talking: bool) -> void:
	imp.set_talking(talking and _speaker == &"imp")


## A stage cues the imp's face, such as his surprise when a button comes alive. It holds until the next
## page sets his face.
func _on_imp_face_cued(face: StringName) -> void:
	imp.set_face(ImpDrawing.face_named(face))
