class_name Main
extends Node
## The game's entry point. For now it plays the first slice, question 1.02 The Lever, over and over,
## so the loop can be tuned. The imp scribbles in once, then the question repeats.

## The chapter to play from.
@export_file("*.json") var chapter_path := "res://content/chapters/ch1_tracks.json"
## The beat to play.
@export var start_beat := &"lever"
## Seconds between one play of the question and the next.
@export_range(0.0, 10.0, 0.05) var pause_between := 1.2

@export var question_player: QuestionPlayer
@export var imp: Imp
@export var dialogue: DialogueBox
## Development tools added in debug builds only.
@export var dev_tools_scene: PackedScene

## The silent portrait of the player.
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
	var beat := chapter.find_beat(start_beat) as QuestionData if chapter != null else null
	if beat == null:
		push_error("Main: no question '%s' in %s" % [start_beat, chapter_path])
		return
	dialogue.page_shown.connect(_on_page_shown)
	dialogue.typing_changed.connect(imp.set_talking)
	await imp.appear(Imp.Wing.RIGHT)
	while is_inside_tree():
		await question_player.play(beat, profile)
		await get_tree().create_timer(pause_between, false).timeout


func _on_page_shown(line: LineData, _page: int, _page_count: int) -> void:
	if line.face != &"":
		imp.set_face(ImpDrawing.Face.get(String(line.face).to_upper(), ImpDrawing.Face.GRIN))
	imp.hop_if_settled()
