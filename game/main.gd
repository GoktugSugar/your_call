class_name Main
extends Node
## The game's entry point. For now it plays the run, the chapters in content/run.json from the crash to
## the last chapter's closing line, then starts it over with a fresh portrait, so the chapters can be
## played through while the rest is built.

## The run: which chapters play, in order.
@export_file("*.json") var run_path := "res://content/run.json"
## Where the chapter files are.
@export_dir var chapters_dir := "res://content/chapters"
## The chapter to start from, by id. Empty starts at the first.
@export var start_chapter := &""
## The beat to start from in that chapter. Empty starts at the top of the chapter.
@export var start_beat := &""
## Seconds between one run ending and the next starting.
@export_range(0.0, 10.0, 0.05) var pause_between := 1.2

@export var run_player: RunPlayer
@export var question_player: QuestionPlayer
@export var imp: Imp
@export var dialogue: DialogueBox
## Development tools added in debug builds only.
@export var dev_tools_scene: PackedScene

## The silent portrait of the player, started fresh for each run.
var profile := Profile.new()
## The chapters of the run, in order.
var chapters: Array[ChapterData] = []


func _ready() -> void:
	if OS.is_debug_build() and dev_tools_scene != null:
		var tools := dev_tools_scene.instantiate()
		tools.set(&"main", self)
		add_child(tools)
	chapters = _load_run()
	if chapters.is_empty():
		push_error("Main: no chapters to play in %s" % run_path)
		return
	_check_start(chapters)
	dialogue.page_shown.connect(_on_page_shown)
	question_player.imp_face_cued.connect(_on_imp_face_cued)
	dialogue.talking_changed.connect(imp.set_talking)
	dialogue.talking_changed.connect(Music.duck)
	imp.set_speech(dialogue.spoken_character)
	while is_inside_tree():
		profile = Profile.new()
		await run_player.play_run(chapters, profile, start_chapter, start_beat)
		await get_tree().create_timer(pause_between, false).timeout


## The chapters of the run, in order.
func _load_run() -> Array[ChapterData]:
	var chapters: Array[ChapterData] = []
	var loader := ContentLoader.new(Profile.axis_ids())
	var run: Variant = loader.read_json(run_path)
	for file: Variant in run.get("chapters", []) if run is Dictionary else []:
		var chapter := loader.load_chapter(chapters_dir.path_join(str(file)))
		if chapter != null:
			chapters.append(chapter)
	for problem in loader.problems:
		push_error(problem)
	return chapters


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


## Each page sets the imp's face (his grin unless the line asks for another) and may send him hopping.
func _on_page_shown(line: LineData, _page: int, _page_count: int) -> void:
	imp.set_face(_face(line.face))
	imp.hop_if_settled()


## A stage cues the imp's face, such as his surprise when a button comes alive. It holds until the next
## page sets his face.
func _on_imp_face_cued(face: StringName) -> void:
	imp.set_face(_face(face))


## The imp's face called [param face_name], or his grin when it names none he has.
static func _face(face_name: StringName) -> ImpDrawing.Face:
	var key := String(face_name).to_upper() if face_name != &"" else "GRIN"
	return ImpDrawing.Face.get(key, ImpDrawing.Face.GRIN)
