extends Node2D
## Development only: the imp in each expression, big and at his size in the game, every one moving his
## mouth along with a dialogue box that says a few voiced lines by itself, over and over; and one live
## imp, wired to the box as the game wires him, who appears, talks, changes face each page and hops.

## The live imp.
@export var imp: Imp
## The box that says the lines.
@export var dialogue: DialogueBox
## The chapter the lines come from.
@export_file("*.json") var chapter_path := "res://content/chapters/ch1_tracks.json"
## The beats whose lines the box says, in turn.
@export var beats: Array[StringName] = [&"intro"]
## Space between the faces in a row.
@export var spacing := 300.0
## Where the first big face stands.
@export var big_row := Vector2(330.0, 400.0)
## How big the big faces are drawn.
@export_range(0.5, 4.0, 0.05) var big_scale := 2.0
## Where the first face at the imp's size in the game stands.
@export var game_size_row := Vector2(330.0, 760.0)

var _pages := 0


func _ready() -> void:
	var faces := ImpDrawing.Face.values()
	for i in faces.size():
		_add_talking_face(faces[i], big_row + Vector2(spacing * i, 0.0), big_scale)
		_add_talking_face(faces[i], game_size_row + Vector2(spacing * i, 0.0), 1.0)
	dialogue.talking_changed.connect(imp.set_talking)
	dialogue.page_shown.connect(_on_page_shown)
	imp.set_speech(dialogue.spoken_character)
	var lines := _lines()
	await imp.appear(Imp.Wing.RIGHT)
	while is_inside_tree():
		await dialogue.say(lines, false, true)


## One face drawn at [param at] and [param size], its mouth moving with whatever the box says.
func _add_talking_face(face: ImpDrawing.Face, at: Vector2, size: float) -> void:
	var sample := ImpDrawing.new()
	sample.face = face
	sample.position = at
	sample.scale = Vector2.ONE * size
	add_child(sample)
	var mouth := ImpMouth.new()
	mouth.drawing = sample
	mouth.speech = dialogue.spoken_character
	dialogue.talking_changed.connect(func(talking: bool) -> void: mouth.talking = talking)
	sample.add_child(mouth)


## The lines of [member beats], or a line of its own when the chapter has none of them.
func _lines() -> Array[LineData]:
	var lines: Array[LineData] = []
	var chapter := ContentLoader.new(Profile.axis_ids()).load_chapter(chapter_path)
	for beat_id in beats:
		var beat: BeatData = chapter.find_beat(beat_id) if chapter != null else null
		if beat != null:
			lines.append_array(beat.all_lines())
	if lines.is_empty():
		lines.append(LineData.make("sampler.talk", "Nothing to say? Then I shall make something up, as usual."))
	return lines


## Each page the live imp tries the next face, and may hop.
func _on_page_shown(_line: LineData, _page: int, _page_count: int) -> void:
	var faces := ImpDrawing.Face.values()
	imp.set_face(faces[_pages % faces.size()])
	_pages += 1
	imp.hop_if_settled()
