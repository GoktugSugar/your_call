extends Node
## Development only: Main adds this in debug builds. F5 restarts, F3 shows the overlay with the
## question's phase and the silent profile. Switches after [code]--[/code] on the command line:
## [codeblock]
## --autoplay=N     pick option N (counting from 1) and click through everything else
## --autoplay=lever  point at the stage's lever, then click it, with synthetic pointer events
## --speed=X        run the game X times faster
## --shots=PATH     save a screenshot just before each autoplay click, as PATH_01.png and on
## --quit-after=N   quit once N questions have finished
## --burst=S        with --shots, also save a screenshot every S seconds while a consequence plays
## --window=WxH     a plain window of exactly that size, to check a resolution
## --log-talk       print when each page starts, finishes inking on, and stops being spoken
## [/codeblock]

## Seconds autoplay waits before each click.
@export_range(0.0, 5.0, 0.05) var autoplay_delay := 0.6
## Shows the phase and the profile.
@export var overlay: Label

## The main scene, set by Main before this enters the tree.
var main: Main

var _shot_path := ""
var _shot_count := 0
var _burst := 0.0
var _questions_done := 0
var _quit_after := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.visible = false
	var args := DevArgs.parse()
	DevArgs.apply_window(get_window(), args)
	if args.has("speed"):
		Engine.time_scale = float(args["speed"])
	var player: QuestionPlayer = main.question_player
	player.phase_changed.connect(_on_phase_changed)
	_quit_after = int(args.get("quit-after", "0"))
	if args.has("log-talk"):
		var box := player.dialogue
		box.page_shown.connect(func(line: LineData, page: int, count: int) -> void:
			print("%7.2f s  page %d of %d of %s" % [_now(), page + 1, count, line.id]))
		box.typing_changed.connect(func(typing: bool) -> void:
			if not typing:
				print("%7.2f s    text inked on" % _now()))
		box.talking_changed.connect(func(talking: bool) -> void:
			print("%7.2f s    %s" % [_now(), "talking" if talking else "quiet"]))
	if args.has("autoplay"):
		_shot_path = args.get("shots", "")
		_burst = float(args.get("burst", "0"))
		_autoplay(args["autoplay"])


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"dev_restart"):
		get_tree().reload_current_scene()
	elif event.is_action_pressed(&"dev_overlay"):
		overlay.visible = not overlay.visible


func _process(_delta: float) -> void:
	if not overlay.visible:
		return
	var player: QuestionPlayer = main.question_player
	var lines := PackedStringArray()
	var question := player.question
	lines.append("%s  %s" % [question.number + " " + question.title if question != null else "between questions",
			QuestionPlayer.Phase.keys()[player.phase].to_lower()])
	var profile: Profile = main.profile
	for axis in profile.leanings:
		lines.append("%s  %+.0f" % [axis, profile.leanings[axis]])
	overlay.text = "\n".join(lines)


func _autoplay(pick: String) -> void:
	var player: QuestionPlayer = main.question_player
	player.dialogue.waiting_changed.connect(func(waiting: bool) -> void:
		if waiting:
			_act(&"advance"))
	if pick == "lever":
		player.choices.offered.connect(func(_count: int) -> void: _pull_lever())
	else:
		player.choices.offered.connect(func(_count: int) -> void: _act(StringName("choose_%d" % int(pick))))
	player.reveal.settled.connect(func() -> void: _act(&"advance"))


func _pull_lever() -> void:
	var player: QuestionPlayer = main.question_player
	var stage := player.stage as TrolleyStage
	if stage == null:
		push_error("autoplay: this stage has no lever")
		return
	await get_tree().create_timer(autoplay_delay, true).timeout
	var at := get_viewport().get_screen_transform() * stage.lever.grip_point()
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	Input.parse_input_event(motion)
	await get_tree().create_timer(autoplay_delay, true).timeout
	if not _shot_path.is_empty():
		await _shoot()
	for pressed: bool in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		click.position = at
		click.global_position = at
		Input.parse_input_event(click)


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


func _act(action: StringName) -> void:
	await get_tree().create_timer(autoplay_delay, true).timeout
	if not _shot_path.is_empty():
		await _shoot()
	var press := InputEventAction.new()
	press.action = action
	press.pressed = true
	Input.parse_input_event(press)
	var release := InputEventAction.new()
	release.action = action
	Input.parse_input_event(release)


func _shoot() -> void:
	await RenderingServer.frame_post_draw
	_shot_count += 1
	get_viewport().get_texture().get_image().save_png("%s_%02d.png" % [_shot_path, _shot_count])


func _shoot_consequence() -> void:
	var player: QuestionPlayer = main.question_player
	while player.phase == QuestionPlayer.Phase.CONSEQUENCE:
		await _shoot()
		await get_tree().create_timer(_burst).timeout


func _on_phase_changed(phase: QuestionPlayer.Phase) -> void:
	if phase == QuestionPlayer.Phase.CONSEQUENCE and _burst > 0.0 and not _shot_path.is_empty():
		_shoot_consequence()
	if phase != QuestionPlayer.Phase.DONE:
		return
	_questions_done += 1
	if _quit_after > 0 and _questions_done >= _quit_after:
		get_tree().quit()
