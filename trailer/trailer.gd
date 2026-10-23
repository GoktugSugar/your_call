class_name Trailer
extends Node
## The trailer, made from the game itself: the real stages, the imp and the dialogue box, played a shot
## at a time from the cut ([code]trailer/trailer_cut.json[/code]). Each shot is one run of this scene,
## recorded with Godot's Movie Maker; [code]tools/trailer/render_trailer.py[/code] records every shot
## the cut needs, then cuts, mixes and encodes them. The imp says the trailer's own lines
## ([code]trailer/trailer_lines.json[/code]), voiced like any other. While it plays, only the trailer's
## unseen pointer gets through: every real mouse and key is shut out, so nothing stray lands in a shot.
## The background music is muted: the trailer brings its own.
## [codeblock]
## Godot --path . res://trailer/trailer.tscn -- --shot=lever
## [/codeblock]
## Development only, like [code]dev/[/code]: it stays out of release exports.

## The cut: the shots, how they are cut together, and the sound over them.
@export_file("*.json") var cut_path := "res://trailer/trailer_cut.json"
## The trailer's lines, in the form of a chapter of narration.
@export_file("*.json") var lines_path := "res://trailer/trailer_lines.json"
## The run, whose questions the shots play.
@export_file("*.json") var run_path := "res://content/run.json"
## Where the chapter files are.
@export_dir var chapters_dir := "res://content/chapters"

@export var question_player: QuestionPlayer
@export var dialogue: DialogueBox
@export var choices: ChoiceRow
@export var reveal: CrowdReveal
@export var balance: BalanceReadout
@export var imp: Imp
@export var camera: TrailerCamera
@export var pointer: TrailerPointer
@export var title_card: TitleCard
## The shut eyes a shot can open on.
@export var eyelids: Eyelids
## Where cinematics are added.
@export var overlay_root: Node

@export_group("Pacing")
## Seconds a page stays up once it is said, before it moves on by itself.
@export_range(0.0, 3.0, 0.05) var auto_hold := 0.35
## Seconds the pointer takes to glide to something when a step does not say.
@export_range(0.05, 5.0, 0.05) var glide_time := 0.7
## Seconds the imp takes to scribble in when a shot has him already there.
@export_range(0.01, 1.0, 0.01) var instant := 0.01

@export_group("Sound")
## The bus whose music the trailer mutes, bringing its own.
@export var music_bus := &"Music"

## What the run remembers in this shot: the wallet, the kills, the profile nobody sees.
var run := RunState.new()

var _lines := {}
var _chapters: Array[ChapterData] = []
## Whether the imp hops as each page shows, as he does in the game.
var _hops := true
## Seconds since the shot started, in game time: in a recording, the time on the picture.
var _clock := 0.0
## Whether to print the shot's moments as they come ([code]--log[/code]).
var _logging := false


func _ready() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index(music_bus), true)
	PlayerSettings.auto_advance = true
	dialogue.auto_hold = auto_hold
	balance.watch(run)
	dialogue.page_shown.connect(_on_page_shown)
	dialogue.talking_changed.connect(imp.set_talking)
	question_player.imp_face_cued.connect(func(face: StringName) -> void: imp.set_face(face_named(face)))
	imp.set_speech(dialogue.spoken_character)
	var args := DevArgs.parse()
	if args.has("log"):
		_log_beats()
	var loader := ContentLoader.new(Profile.axis_ids())
	_load_lines(loader)
	_load_run(loader)
	for problem in loader.problems:
		push_error(problem)
	var cut: Variant = loader.read_json(cut_path)
	var shots: Dictionary = cut.get("shots", {}) if cut is Dictionary else {}
	var shot := str(args.get("shot", ""))
	if shot.is_empty() and not shots.is_empty():
		shot = str(shots.keys()[0])
	if not shots.has(shot):
		push_error("Trailer: no shot '%s' in %s" % [shot, cut_path])
		return
	await play_shot(shots[shot])
	_log("action done")


func _process(delta: float) -> void:
	_clock += delta


## Only the trailer's pointer plays: a real mouse or key while a shot records would spoil it.
func _input(event: InputEvent) -> void:
	if not TrailerPointer.made(event):
		get_viewport().set_input_as_handled()


## Sets the page up as [param settings] asks, then plays the shot's action.
func play_shot(settings: Dictionary) -> void:
	var shot := _shot_of_kind(StringName(str(settings.get("kind", ""))))
	if shot == null:
		push_error("Trailer: no kind of shot called '%s'" % settings.get("kind", ""))
		return
	_frame(settings.get("camera", {}))
	if bool(settings.get("eyes", false)):
		eyelids.open()
	for move: Dictionary in settings.get("moves", []):
		_move_camera_later(move)
	await _place_imp(settings.get("imp", {}))
	await shot.play(self, settings)


## Plays the pointer's [param steps] in turn. A step can wait for the question to reach a phase
## ([code]on[/code]: choosing, consequence, reacting, revealing), wait some seconds ([code]wait[/code]),
## glide the pointer ([code]glide[/code] seconds, [code]waver[/code] pixels) to an option where the stage
## shows it, or else in the choice row ([code]point[/code]: its index), to an option in the row
## ([code]row[/code]), to a point ([code]at[/code]) or through several ([code]path[/code]), click
## ([code]click[/code]), move the camera ([code]camera[/code], over [code]seconds[/code]) or change the
## imp's face ([code]face[/code]).
func act(steps: Array) -> void:
	for raw: Variant in steps:
		if not raw is Dictionary:
			continue
		var step: Dictionary = raw
		if step.has("on"):
			await _reach(StringName(str(step["on"])))
		await wait(float(step.get("wait", 0.0)))
		if step.has("camera"):
			camera.move_to(_framing(step["camera"]), float(step.get("seconds", 0.0)))
		if step.has("face"):
			imp.set_face(face_named(StringName(str(step["face"]))))
		var points := _points(step)
		if not points.is_empty():
			await pointer.glide(points, float(step.get("glide", glide_time)), float(step.get("waver", -1.0)))
		if bool(step.get("click", false)):
			await pointer.click()


## The trailer's lines with these [param names], in order.
func lines_named(names: Array) -> Array[LineData]:
	var lines: Array[LineData] = []
	for name: Variant in names:
		if _lines.has(StringName(str(name))):
			lines.append_array(_lines[StringName(str(name))])
		else:
			push_error("Trailer: no lines called '%s' in %s" % [name, lines_path])
	return lines


## The question at [param path] in the run, such as [code]ch1.lever[/code], freshly loaded so a shot
## can change what it says. Null if there is none.
func question_named(path: String) -> QuestionData:
	var parts := path.split(".")
	if parts.size() != 2:
		return null
	for chapter in _chapters:
		if chapter.id == StringName(parts[0]):
			var beat := chapter.find_beat(StringName(parts[1]))
			return beat as QuestionData
	return null


## Waits [param seconds] of game time, or not at all.
func wait(seconds: float) -> void:
	if seconds > 0.0:
		await get_tree().create_timer(seconds, false).timeout


## Sets [param settings] on [param node], each by name: how a shot changes a stage or a cinematic,
## such as the country a pin lands on. [param settings] comes last, so it can be bound to a signal that
## hands over the node.
static func tune(node: Node, settings: Dictionary) -> void:
	for key: String in settings:
		node.set(StringName(key), settings[key])


## A shot of the kind the cut calls [param kind], or null when there is no such kind.
static func _shot_of_kind(kind: StringName) -> TrailerShot:
	match kind:
		&"narration":
			return NarrationShot.new()
		&"question":
			return QuestionShot.new()
		&"cinematic":
			return CinematicShot.new()
		&"title":
			return TitleShot.new()
		&"reveal":
			return RevealShot.new()
	return null


## The imp's face called [param face_name], or his grin when it names none he has.
static func face_named(face_name: StringName) -> ImpDrawing.Face:
	var key := String(face_name).to_upper() if face_name != &"" else "GRIN"
	return ImpDrawing.Face.get(key, ImpDrawing.Face.GRIN)


func _load_lines(loader: ContentLoader) -> void:
	var chapter := loader.load_chapter(lines_path)
	if chapter == null:
		return
	for beat in chapter.beats:
		if beat is NarrationData:
			_lines[beat.id] = (beat as NarrationData).lines


func _load_run(loader: ContentLoader) -> void:
	var data: Variant = loader.read_json(run_path)
	for file: Variant in data.get("chapters", []) if data is Dictionary else []:
		var chapter := loader.load_chapter(chapters_dir.path_join(str(file)))
		if chapter != null:
			_chapters.append(chapter)


## Brings the imp on as [param settings] says: already there ([code]appear[/code] instant, the
## default), scribbling in (scribble) or not at all (none); in his wing ([code]wing[/code], left or
## right) or at a spot ([code]at[/code]); with a face ([code]face[/code]); hopping as each page shows,
## as in the game, unless he is at a spot or [code]hops[/code] is false; and making trips across the
## page in hops ([code]travel[/code]: each [code]after[/code] some seconds, [code]to[/code] a spot).
func _place_imp(settings: Dictionary) -> void:
	var appear := str(settings.get("appear", "instant"))
	if appear == "none":
		return
	if appear == "instant":
		imp.scribble_duration = instant
		imp.pop_settle = instant
	var wing := Imp.Wing.LEFT if str(settings.get("wing", "right")) == "left" else Imp.Wing.RIGHT
	var spot: Variant = _vector(settings.get("at"))
	_hops = bool(settings.get("hops", spot == null))
	imp.free_to_roam = bool(settings.get("roam", false))
	# He takes his spot as he starts to appear, so a spot of the shot's own goes in just after.
	imp.appear(wing)
	if spot != null:
		imp.position = spot
	imp.set_face(face_named(StringName(str(settings.get("face", "")))))
	for trip: Dictionary in settings.get("travel", []):
		_travel_later(trip)
	await imp.appeared


## Sends the imp hopping [code]to[/code] a spot [code]after[/code] some seconds.
func _travel_later(trip: Dictionary) -> void:
	await wait(float(trip.get("after", 0.0)))
	var spot: Variant = _vector(trip.get("to"))
	if spot != null:
		await imp.travel_to(spot)


func _frame(settings: Dictionary) -> void:
	var framing := _framing(settings)
	camera.frame(float(framing.get("zoom", 1.0)), framing.get("at", camera.page_middle))
	camera.frame_words(float(framing.get("words_zoom", 1.0)), framing.get("words_at", camera.page_middle))


## A move of the camera [code]after[/code] seconds, over [code]seconds[/code], to [code]to[/code].
func _move_camera_later(move: Dictionary) -> void:
	await wait(float(move.get("after", 0.0)))
	camera.move_to(_framing(move.get("to", {})), float(move.get("seconds", 0.0)))


## A framing from the cut's JSON, its points made vectors.
func _framing(settings: Dictionary) -> Dictionary:
	var framing := settings.duplicate()
	for key: String in ["at", "words_at"]:
		if framing.has(key):
			framing[key] = _vector(framing[key])
	return framing


## Where a step sends the pointer, on the canvas: through its path, to its point, or to an option.
func _points(step: Dictionary) -> Array[Vector2]:
	var points: Array[Vector2] = []
	if step.has("path"):
		for point: Variant in step["path"]:
			points.append(_vector(point))
	elif step.has("at"):
		points.append(_vector(step["at"]))
	elif step.has("point"):
		var on_stage := question_player.stage.option_point(int(step["point"])) if question_player.stage != null else Vector2.INF
		points.append(on_stage if on_stage.is_finite() else _row_point(int(step["point"])))
	elif step.has("row"):
		points.append(_row_point(int(step["row"])))
	var found: Array[Vector2] = []
	for point in points:
		if point.is_finite():
			found.append(point)
	return found


## The middle of the choice row's word for the option at [param index], on the canvas.
func _row_point(index: int) -> Vector2:
	var question := question_player.question
	var shown := question.shown_options() if question != null else PackedInt32Array()
	var place := shown.find(index)
	for word: Node in choices.row.get_children():
		if word is ChoiceWord and (word as ChoiceWord).index == place:
			var control := word as Control
			return control.get_global_transform_with_canvas() * (control.size * 0.5)
	return Vector2.INF


## Waits until the question reaches the phase called [param phase_name].
func _reach(phase_name: StringName) -> void:
	var phase: int = QuestionPlayer.Phase.get(String(phase_name).to_upper(), -1)
	if phase < 0:
		push_error("Trailer: no phase called '%s'" % phase_name)
		return
	while question_player.phase != phase:
		await question_player.phase_changed


## Prints when each moment of the shot comes, in the shot's own time, for setting the cut's points.
func _log_beats() -> void:
	_logging = true
	question_player.phase_changed.connect(func(phase: QuestionPlayer.Phase) -> void:
		_log("phase %s" % String(QuestionPlayer.Phase.keys()[phase]).to_lower()))
	dialogue.page_shown.connect(func(line: LineData, page: int, count: int) -> void:
		_log("page %d of %d of %s" % [page + 1, count, line.id]))
	dialogue.talking_changed.connect(func(talking: bool) -> void: _log("talking" if talking else "quiet"))
	reveal.settled.connect(_log.bind("reveal inked in"))


func _log(text: String) -> void:
	if _logging:
		print("%7.3f  %s" % [_clock, text])


## Each page sets the imp's face from its line, and sends him hopping as in the game when he may.
func _on_page_shown(line: LineData, page: int, _page_count: int) -> void:
	imp.set_face(face_named(line.face))
	if not _hops:
		return
	if page == 0:
		imp.hop_for_line()
	else:
		imp.hop_if_settled()


## [param value] as a vector, from a JSON pair, or null.
static func _vector(value: Variant) -> Variant:
	if value is Vector2:
		return value
	if value is Array and (value as Array).size() == 2:
		return Vector2(float(value[0]), float(value[1]))
	return null
