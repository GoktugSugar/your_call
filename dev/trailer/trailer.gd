class_name Trailer
extends Node
## The trailers, made from the game itself: the real stages, the imp, the dialogue box and the crowd
## reveal, played a shot at a time from the cut ([code]dev/trailer/trailer_cut.json[/code]) in one of
## its formats, wide (16:9) or tall (9:16, for phones). Each shot is one run of this scene, recorded
## with Godot's Movie Maker; [code]tools/trailer/render_trailer.py[/code] records every shot the cut
## needs, in both formats, then cuts, mixes and encodes them.
##
## The imp says the trailers' own lines ([code]dev/trailer/trailer_lines.json[/code]), voiced like any
## other. A question's ask and reactions can be swapped for them, so the question player says them in
## the game's own box, and a shot's steps can have him say them at moments of their own in a second box,
## the voice over, which no question closes. Real mouse and key input is shut out, so nothing stray
## lands in a shot, and the game's music is muted: the cut brings the trailers' own.
## [codeblock]
## Godot --path . res://dev/trailer/trailer.tscn -- --shot=open --format=tall --log
## [/codeblock]
## Development only, like the rest of [code]dev/[/code]: it stays out of both exports.

## The cut: the formats, the shots, how they are cut together and the sound over them.
@export_file("*.json") var cut_path := "res://dev/trailer/trailer_cut.json"
## The trailers' lines, in the form of a chapter of narration.
@export_file("*.json") var lines_path := "res://dev/trailer/trailer_lines.json"
## The run, whose questions the shots play.
@export_file("*.json") var run_path := "res://content/run.json"
## Where the chapter files are.
@export_dir var chapters_dir := "res://content/chapters"

@export var question_player: QuestionPlayer
## The game's own box, where the question player says a question's lines.
@export var dialogue: DialogueBox
## The trailers' box, where the steps have the imp say lines at moments of their own.
@export var voice_over: DialogueBox
@export var choices: ChoiceRow
@export var reveal: CrowdReveal
@export var balance: BalanceReadout
@export var imp: Imp
@export var camera: TrailerCamera
## The layer the words are on: the boxes, the choice row, the reveal and the balance.
@export var words_layer: CanvasLayer
## The room the words lay out in, the whole screen in the wide format.
@export var words_frame: Control
@export var eyelids: Eyelids
@export var title_card: TitleCard
## Where a shot's own scenery goes, such as the studio.
@export var set_root: Node2D

@export_group("Pacing")
## Seconds a page stays up once it is said, before it moves on by itself.
@export_range(0.0, 3.0, 0.05) var auto_hold := 0.35
## Seconds the imp takes to scribble in when a shot has him there from the start.
@export_range(0.01, 1.0, 0.01) var instant := 0.01

@export_group("Sound")
## The bus whose music the trailers mute, bringing their own in the cut.
@export var music_bus := &"Music"

## What the run remembers in this shot: the wallet, the kills, the profile nobody sees.
var run := RunState.new()
## The format's settings from the cut: its size and how its words are laid out.
var format := {}
## The format's name, wide or tall: settings in a shot can differ by it.
var format_name := &"wide"
## Seconds since the shot started, in game time: in a recording, the time on the picture.
var clock := 0.0
## The studio, when the shot has one.
var studio: StudioSet

var _lines := {}
var _chapters: Array[ChapterData] = []
## Whether each box is talking, the imp's mouth and nods following whichever is his.
var _talking := {}
## Who says the page up in the game's box: only the imp's own pages move his mouth.
var _speaker := &"imp"
## Whether the imp drifts to a fresh spot as each page shows, as he does in the game.
var _drifts := false
## The shot's lists of steps, kept while they play.
var _tracks: Array[TrailerSteps] = []
var _logging := false


func _ready() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index(music_bus), true)
	PlayerSettings.auto_advance = true
	get_viewport().gui_disable_input = true
	eyelids.hide()
	for box: DialogueBox in [dialogue, voice_over]:
		box.auto_hold = auto_hold
		box.page_shown.connect(_on_page_shown.bind(box))
		box.talking_changed.connect(_on_talking_changed.bind(box))
	question_player.imp_face_cued.connect(func(face: StringName) -> void: imp.set_face(ImpDrawing.face_named(face)))
	imp.set_speech(_spoken_character)
	balance.watch(run)
	var args := DevArgs.parse()
	_logging = args.has("log")
	if _logging:
		_log_moments()
	var loader := ContentLoader.new(Profile.axis_ids())
	_load_lines(loader)
	_chapters = loader.load_run(run_path, chapters_dir)
	var cut: Variant = loader.read_json(cut_path)
	for problem in loader.problems:
		push_error(problem)
	if not cut is Dictionary:
		push_error("Trailer: no cut at %s" % cut_path)
		return
	format_name = StringName(str(args.get("format", "wide")))
	format = (cut as Dictionary).get("formats", {}).get(format_name, {})
	_lay_out_words(format.get("words", {}))
	var shots: Dictionary = (cut as Dictionary).get("shots", {})
	var shot := str(args.get("shot", shots.keys()[0] if not shots.is_empty() else ""))
	if not shots.has(shot):
		push_error("Trailer: no shot '%s' in %s" % [shot, cut_path])
		return
	_log("shot %s, %s" % [shot, format_name])
	await play_shot(shots[shot])
	_log("shot done")


func _process(delta: float) -> void:
	clock += delta


## Only the steps play: a real mouse or key while a shot records would spoil it.
func _input(_event: InputEvent) -> void:
	get_viewport().set_input_as_handled()


## Sets the page up as [param settings] asks, then plays the shot: its question, if it has one, with its
## steps alongside, and its picks alongside those, so an option can be picked while a line is said.
func play_shot(settings: Dictionary) -> void:
	var framing: Dictionary = by_format(settings.get("camera", {}))
	camera.frame(float(framing.get("zoom", default_zoom())), vector(framing.get("at"), camera.page_middle))
	if bool(settings.get("eyes_shut", false)):
		eyelids.shut()
	if settings.has("studio"):
		_build_studio(by_format(settings["studio"]))
	if settings.has("wallet"):
		run.open_wallet(int(settings["wallet"]))
	await place_imp(by_format(settings.get("imp", {})))
	var steps := TrailerSteps.new(self)
	var picks := TrailerSteps.new(self)
	_tracks = [steps, picks]
	picks.run(settings.get("picks", []))
	if not settings.has("question"):
		await steps.run(settings.get("steps", []))
		return
	var question := TrailerQuestion.prepare(question_named(str(settings["question"])), settings, self)
	if question == null:
		push_error("Trailer: no question '%s' in the run" % settings["question"])
		return
	_park_box(dialogue, str(settings.get("park", "")))
	steps.run(settings.get("steps", []))
	await question_player.play(question, run)


## Brings the imp on as [param settings] says: already there (instant, the default), scribbling in
## (scribble) or not at all (none); in his wing ([code]wing[/code], left or right) or at a spot
## ([code]at[/code]); with a face; at a size of his own ([code]scale[/code]); and drifting to a fresh spot
## as each page shows, as in the game, unless he is at a spot or [code]drifts[/code] says not.
func place_imp(settings: Dictionary) -> void:
	var appear := str(settings.get("appear", "instant"))
	if appear == "none":
		return
	if appear == "instant":
		imp.scribble_duration = instant
		imp.pop_settle = instant
		imp.appear_sound = null
	var wing := Imp.Wing.LEFT if str(settings.get("wing", "right")) == "left" else Imp.Wing.RIGHT
	var spot: Variant = vector(settings.get("at"))
	_drifts = bool(settings.get("drifts", spot == null))
	imp.appear(wing)
	# He picks a spot in his wing as he starts to appear, so a spot of the shot's own goes in after.
	if spot != null:
		imp.position = spot
	imp.drawing.width_scale = float(settings.get("line", imp.drawing.width_scale))
	imp.set_face(ImpDrawing.face_named(StringName(str(settings.get("face", "")))))
	await imp.appeared
	imp.scale = Vector2.ONE * float(settings.get("scale", 1.0))


## Says [param names], the trailers' lines, in the voice over box, each page moving on by itself once
## said and held for [param hold] seconds. Closes the box after unless [param keep]. Returns once said.
func say(names: Array, hold := -1.0, keep := false) -> void:
	voice_over.auto_hold = auto_hold if hold < 0.0 else hold
	await voice_over.say(lines_named(names), false, true)
	if not keep:
		await voice_over.close()


## Lights the option at [param index] on the stage and in the choice row, as pointing at it would.
func highlight(index: int) -> void:
	var row := _row_index(index)
	choices.highlight(row)
	if question_player.stage != null:
		question_player.stage.highlight_option(index)


## Picks the option at [param index] in the choice row.
func commit(index: int) -> void:
	choices.commit(_row_index(index))


## The trailers' lines with these [param names], in order.
func lines_named(names: Array) -> Array[LineData]:
	var lines: Array[LineData] = []
	for name: Variant in names:
		if _lines.has(StringName(str(name))):
			lines.append_array(_lines[StringName(str(name))])
		else:
			push_error("Trailer: no lines called '%s' in %s" % [name, lines_path])
	return lines


## The question at [param path] in the run, such as [code]ch1.lever[/code], or null.
func question_named(path: String) -> QuestionData:
	var parts := path.split(".")
	if parts.size() != 2:
		return null
	for chapter in _chapters:
		if chapter.id == StringName(parts[0]):
			return chapter.find_beat(StringName(parts[1])) as QuestionData
	return null


## Waits [param seconds] of game time, or not at all.
func wait(seconds: float) -> void:
	if seconds > 0.0:
		await get_tree().create_timer(seconds, false).timeout


## Waits until the question reaches the phase called [param phase_name].
func reach(phase_name: StringName) -> void:
	var phase: int = QuestionPlayer.Phase.get(String(phase_name).to_upper(), -1)
	if phase < 0:
		push_error("Trailer: no phase called '%s'" % phase_name)
		return
	while question_player.phase != phase:
		await question_player.phase_changed


## Notes a moment of the shot in its log, for the cut to find by name.
func mark(name: String) -> void:
	_log("mark %s" % name)


## [param value] as this format has it: the value under the format's name when it differs by format,
## otherwise the value itself.
func by_format(value: Variant) -> Variant:
	if value is Dictionary and ((value as Dictionary).has("wide") or (value as Dictionary).has("tall")):
		return (value as Dictionary).get(format_name, {})
	return value


## How far in the camera is when a shot does not say: the whole page across the screen.
func default_zoom() -> float:
	return get_viewport().get_visible_rect().size.x / (camera.page_middle.x * 2.0)


## [param value] as a vector, from a JSON pair, or [param otherwise].
static func vector(value: Variant, otherwise: Variant = null) -> Variant:
	if value is Vector2:
		return value
	if value is Array and (value as Array).size() == 2:
		return Vector2(float(value[0]), float(value[1]))
	return otherwise


## Lays the words out as the format asks: brought in by [code]scale[/code], in a room the height of the
## screen less [code]clear_below[/code] (where a phone app puts its own buttons), the balance lowered by
## [code]clear_above[/code] (where the app puts its tabs), each box at most [code]box_width[/code] wide,
## and the reveal's middle at [code]reveal_y[/code].
func _lay_out_words(settings: Dictionary) -> void:
	var screen := get_viewport().get_visible_rect().size
	var scale := float(settings.get("scale", 1.0))
	words_layer.scale = Vector2.ONE * scale
	words_frame.set_anchors_preset(Control.PRESET_TOP_LEFT)
	words_frame.position = Vector2.ZERO
	words_frame.size = Vector2(screen.x, screen.y - float(settings.get("clear_below", 0.0))) / scale
	var lowered := float(settings.get("clear_above", 0.0)) / scale
	balance.offset_top += lowered
	balance.offset_bottom += lowered
	if settings.has("box_width"):
		for box: DialogueBox in [dialogue, voice_over]:
			box.max_text_width = float(settings["box_width"])
			box.measure_label.size = Vector2(box.max_text_width, 0.0)
	reveal.center = Vector2(words_frame.size.x * 0.5, float(settings.get("reveal_y", reveal.center.y)))


## Puts the game's box where the first page of the trailers' line called [param over] would sit, or a
## page of one line when it names none, so a choice row offered before the box has said anything sits
## clear of the voice over saying that line. The box fills the words' room, which is laid out already
## even when the box itself has not caught up with it yet.
func _park_box(box: DialogueBox, over := "") -> void:
	var first := "Ag"
	if over != "":
		var lines := lines_named([over])
		if not lines.is_empty():
			first = box.paginate(lines[0].text)[0]
	var page := box.text_size_for(Markup.to_bbcode(first, InkPalette.get_default())) + box.padding * 2.0
	var room := words_frame.size
	box.frame.size = page
	box.frame.position = Vector2((room.x - page.x) * 0.5, room.y - box.bottom_margin - page.y)


func _build_studio(settings: Dictionary) -> void:
	studio = StudioSet.new()
	if settings.has("audience"):
		var blocks: Array[Rect2] = []
		for raw: Variant in settings["audience"]:
			blocks.append(Rect2(float(raw[0]), float(raw[1]), float(raw[2]), float(raw[3])))
		studio.audience_blocks = blocks
	set_root.add_child(studio)
	studio.draw_on(float(settings.get("draw", -1.0)))


func _load_lines(loader: ContentLoader) -> void:
	var chapter := loader.load_chapter(lines_path)
	for beat in chapter.beats if chapter != null else []:
		if beat is NarrationData:
			_lines[beat.id] = (beat as NarrationData).lines


## The place in the choice row of the option at [param index].
func _row_index(index: int) -> int:
	var question := question_player.question
	return question.shown_options(run).find(index) if question != null else index


## The character the imp is saying now, from whichever box has him talking.
func _spoken_character(lead := 0.0) -> String:
	if _talking.get(voice_over, false):
		return voice_over.spoken_character(lead)
	if _talking.get(dialogue, false) and _speaker == &"imp":
		return dialogue.spoken_character(lead)
	return ""


## Each of the imp's pages sets his face, and drifts him to a fresh spot when the shot lets him.
func _on_page_shown(line: LineData, page: int, _page_count: int, box: DialogueBox) -> void:
	if box == dialogue:
		_speaker = line.speaker
	if line.speaker != &"imp":
		return
	imp.set_face(ImpDrawing.face_named(line.face))
	if not _drifts:
		return
	if page == 0:
		imp.move_for_line()
	else:
		imp.move_if_settled()


## The imp talks while one of his own pages inks on and its voice plays; the sound effects dip while
## anyone talks, as in the game.
func _on_talking_changed(talking: bool, box: DialogueBox) -> void:
	_talking[box] = talking
	var anyone: bool = _talking.get(dialogue, false) or _talking.get(voice_over, false)
	var his: bool = _talking.get(voice_over, false) or (_talking.get(dialogue, false) and _speaker == &"imp")
	imp.set_talking(his)
	Sfx.duck(anyone)


## Prints when each moment of the shot comes, in the shot's own time, for the cut to find.
func _log_moments() -> void:
	question_player.phase_changed.connect(func(phase: QuestionPlayer.Phase) -> void:
		_log("phase %s" % String(QuestionPlayer.Phase.keys()[phase]).to_lower()))
	for box: DialogueBox in [dialogue, voice_over]:
		var which := "box" if box == dialogue else "over"
		var last := [""]
		box.page_shown.connect(func(line: LineData, page: int, count: int) -> void:
			last[0] = line.id if page == count - 1 else ""
			_log("%s page %d of %d of %s" % [which, page + 1, count, line.id]))
		box.talking_changed.connect(func(talking: bool) -> void:
			_log("%s %s" % [which, "talking" if talking else "quiet"])
			if not talking and last[0] != "":
				_log("%s said %s" % [which, last[0]])
				last[0] = "")
	reveal.settled.connect(_log.bind("reveal inked in"))


func _log(text: String) -> void:
	if _logging:
		print("%8.3f  %s" % [clock, text])
