class_name Main
extends Node
## The game's entry point. For now it plays Chapter 1 from the crash to the imp's closing line, then
## starts it over with a fresh portrait, so the chapter can be played through while the rest is built.

## The chapter to play.
@export_file("*.json") var chapter_path := "res://content/chapters/ch1_tracks.json"
## The beat to start from. Empty starts at the top of the chapter.
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


func _ready() -> void:
	if OS.is_debug_build() and dev_tools_scene != null:
		var tools := dev_tools_scene.instantiate()
		tools.set(&"main", self)
		add_child(tools)
	var loader := ContentLoader.new(Profile.axis_ids())
	var chapter := loader.load_chapter(chapter_path)
	for problem in loader.problems:
		push_error(problem)
	if chapter == null:
		push_error("Main: could not load %s" % chapter_path)
		return
	if start_beat != &"" and chapter.find_beat(start_beat) == null:
		push_error("Main: no beat '%s' in %s, starting at the top." % [start_beat, chapter_path])
		start_beat = &""
	dialogue.page_shown.connect(_on_page_shown)
	dialogue.talking_changed.connect(imp.set_talking)
	dialogue.talking_changed.connect(Music.duck)
	while is_inside_tree():
		profile = Profile.new()
		await run_player.play_chapter(chapter, profile, start_beat)
		await get_tree().create_timer(pause_between, false).timeout


## Each page sets the imp's face (his grin unless the line asks for another) and may send him hopping.
func _on_page_shown(line: LineData, _page: int, _page_count: int) -> void:
	var face := String(line.face).to_upper() if line.face != &"" else "GRIN"
	imp.set_face(ImpDrawing.Face.get(face, ImpDrawing.Face.GRIN))
	imp.hop_if_settled()
