class_name MenuImp
extends Node
## The imp on the menu page. Every so often he says one of his barks as ink floating over his head, in
## the bark's face and his own voice, never the same bark twice running and never in the way of the menu;
## once the words clear, he warps somewhere fresh. Asked a line outright, such as whether to throw the run
## away, he says it at once in place of any bark and holds it up until he is let go. Hushed, he keeps his
## barks to himself, as while the settings are open, though he can still be given one line to say.

## The imp, already on the page.
@export var imp: Imp
## The floating words he speaks in, a [Plea].
@export var words_scene: PackedScene
## The page his words float on.
@export var words_parent: Node2D

@export_group("Timing")
## Seconds after he appears before his first bark.
@export_range(0.0, 30.0, 0.1) var first_bark := 3.0
## Shortest and longest pause between one bark clearing and the next, in seconds.
@export var bark_gap := Vector2(5.0, 9.0)
## Seconds a bark stays up once it has been said, before it fades.
@export_range(0.0, 10.0, 0.05) var words_hold := 1.6

@export_group("Place")
## Where his feet may land on the page, clear of the title and the menu.
@export var spots: Array[Rect2] = []
## How far above his feet his words sit, clear of his horns.
@export_range(0.0, 400.0, 1.0) var words_height := 196.0
## Size of his words on the menu page.
@export_range(8, 120) var words_size := 40
## The shortest move to a fresh spot, in pixels.
@export_range(0.0, 1500.0, 1.0) var min_move := 240.0
## The middle of the page across, which side of it says which way he faces the menu.
@export_range(0.0, 1920.0, 1.0) var page_middle := 960.0
## Seed for which bark he picks and where he warps. Zero picks a new one every time.
@export var bark_seed := 0

var _barks: Array[LineData] = []
var _facts: RunState
var _last: LineData
var _words: Plea
## Each bark or line said takes a turn; whatever is still waiting from an earlier turn gives up.
var _turn := 0
var _asking := false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	if bark_seed != 0:
		_rng.seed = bark_seed
	else:
		_rng.randomize()


## Scribbles him in at a fresh spot and sets him barking from [param barks], saying only those that
## hold for what [param facts] remembers, such as there being a run to continue.
func start(barks: Array[LineData], facts: RunState) -> void:
	use_barks(barks, facts)
	imp.wing = Imp.Wing.LEFT if _rng.randf() < 0.5 else Imp.Wing.RIGHT
	await imp.appear(imp.wing)
	_keep_barking()


## Says [param line] at once, in place of any bark, and holds it up until [method let_go].
func ask(line: LineData) -> void:
	_asking = true
	var turn := _next_turn()
	_clear_words(true)
	await _say(line, turn)


## Lets go of the line he was asked, or of being hushed: his words fade, and the barks carry on.
func let_go() -> void:
	_asking = false
	_next_turn()
	_clear_words()


## Keeps his barks to himself until [method let_go], his words fading.
func hush() -> void:
	_asking = true
	_next_turn()
	_clear_words()


## Says [param line] at once, in place of whatever he was saying, and lets it fade once said, whether or
## not he is hushed.
func say_once(line: LineData) -> void:
	var turn := _next_turn()
	_clear_words(true)
	await _say(line, turn)
	if turn != _turn:
		return
	await _wait(words_hold)
	if turn == _turn:
		_clear_words()


## Whether his words are being said right now.
func is_saying() -> bool:
	return _words != null and is_instance_valid(_words) and _words.is_saying()


## Barks from [param barks] from now on, those that hold for what [param facts] remembers.
func use_barks(barks: Array[LineData], facts: RunState) -> void:
	_barks = barks
	_facts = facts
	_last = null


## The bark he says next: one that holds, never the last one again while there is another. Picking it
## counts it as said, for the next pick.
func pick_bark() -> LineData:
	var holding := LineData.for_run(_barks, _facts)
	if holding.size() > 1:
		holding.erase(_last)
	if holding.is_empty():
		return null
	_last = holding[_rng.randi_range(0, holding.size() - 1)]
	return _last


func _process(_delta: float) -> void:
	if _words != null and is_instance_valid(_words):
		_words.place(imp.position + Vector2(0.0, -words_height))


func _keep_barking() -> void:
	await _wait(first_bark)
	while is_inside_tree():
		if not _asking:
			await _bark()
		await _wait(_rng.randf_range(bark_gap.x, bark_gap.y))


func _bark() -> void:
	var line := pick_bark()
	if line == null:
		return
	var turn := _next_turn()
	await _say(line, turn)
	if turn != _turn:
		return
	await _wait(words_hold)
	if turn != _turn:
		return
	await _clear_words()
	if turn != _turn or spots.is_empty():
		return
	var spot := _fresh_spot()
	imp.wing = Imp.Wing.LEFT if spot.x < page_middle else Imp.Wing.RIGHT
	await imp.warp_to(spot)


## Floats [param line] over his head and says it, his face and mouth with it. Returns once it has been
## said, or as soon as another turn has begun.
func _say(line: LineData, turn: int) -> void:
	var words := words_scene.instantiate() as Plea
	words_parent.add_child(words)
	words.label.add_theme_font_size_override(&"normal_font_size", words_size)
	words.place(imp.position + Vector2(0.0, -words_height))
	words.set_words(line.text)
	_words = words
	imp.set_face(ImpDrawing.face_named(line.face))
	imp.set_speech(words.spoken_character)
	imp.set_talking(true)
	Music.duck(true)
	Sfx.duck(true)
	words.write_on(VoiceLibrary.clip_for(line))
	while turn == _turn and is_inside_tree() and is_instance_valid(words) and words.is_saying():
		await get_tree().process_frame
	if turn == _turn:
		_quiet()


## Fades his words away, or takes them away at once with [param at_once].
func _clear_words(at_once := false) -> void:
	var words := _words
	_words = null
	_quiet()
	if words == null or not is_instance_valid(words):
		return
	words.stop_saying()
	if at_once:
		words.queue_free()
		return
	await words.fade_out()
	if is_instance_valid(words):
		words.queue_free()


func _quiet() -> void:
	imp.set_talking(false)
	Music.duck(false)
	Sfx.duck(false)


func _next_turn() -> int:
	_turn += 1
	return _turn


func _wait(seconds: float) -> void:
	if is_inside_tree():
		await get_tree().create_timer(seconds, false).timeout


## A spot in one of [member spots], far enough from where he floats to be worth the warp.
func _fresh_spot() -> Vector2:
	var spot := imp.position
	for attempt in 12:
		var area := spots[_rng.randi_range(0, spots.size() - 1)]
		spot = Vector2(_rng.randf_range(area.position.x, area.end.x), _rng.randf_range(area.position.y, area.end.y))
		if spot.distance_to(imp.position) >= min_move:
			break
	return spot
