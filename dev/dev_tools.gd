extends Node
## Development only: Main adds this in debug builds. F2 opens a menu to jump to any chapter or question,
## F5 restarts (at the last jump, if there was one), F3 shows the overlay with the chapter, the
## question's phase and the silent profile. Switches after [code]--[/code] on the command line:
## [codeblock]
## --autoplay=N     pick option N (counting from 1) and click through everything else
## --autoplay=1,1,2  pick these in turn, one per choice, the last one from then on (an offer ladder
##                  comes round again, so this presses twice and then stops)
## --point          with --autoplay, point at the option on the stage and click it there (a track,
##                  a doodle, a button) with synthetic pointer events, instead of picking it in the choice row
## --autoplay=lever  point at the stage's lever and click it; on a stage without one, its first option
##                  On a stage that takes the choice by itself, such as the timer, autoplay clicks the
##                  option where the stage shows it, or leaves it alone to let the stage decide.
## --speed=X        run the game X times faster
## --shots=PATH     save a screenshot just before each autoplay click, as PATH_01.png and on
## --quit-after=N   quit once N questions have finished
## --burst=S        with --shots, also save a screenshot every S seconds while a consequence plays
## --every=S        with --shots, also save a screenshot every S seconds all the way through
## --window=WxH     a plain window of exactly that size, to check a resolution
## --log-talk       print when each page starts, finishes inking on, and stops being spoken
## --target=XX      on the nuke stage, the pin lands on the country with this code, such as VA
## --home=XX        on the nuke stage, treat the country with this code as the player's own
## --menu=S         open the jump menu S seconds in, once per launch, for a screenshot of it
## --menu-pick=CH:BEAT  with --menu, then pick that entry from it, such as ch2:timer (ch2: is its top)
## --chapter=ID     start the run at the chapter with this id, such as ch2, instead of the first
## --beat=ID        start at the beat with this id, in that chapter or the first chapter that has it
## [/codeblock]

## Seconds autoplay waits before each click.
@export_range(0.0, 5.0, 0.05) var autoplay_delay := 0.6
## Shows the phase and the profile.
@export var overlay: Label
## Lists every chapter and question to jump to.
@export var menu: DevMenu

## Where the last jump from the menu starts the run. Kept across restarts, so F5 starts there again.
static var _jump_chapter := &""
static var _jump_beat := &""
## Whether --menu has opened the menu already in this launch, so a jump's restart does not open it again.
static var _menu_opened := false
## Screenshots taken so far, counted across restarts so a jump does not write over earlier ones.
static var _shot_count := 0

## The main scene, set by Main before this enters the tree.
var main: Main

var _shot_path := ""
var _burst := 0.0
var _questions_done := 0
var _quit_after := 0
## The picks autoplay makes, one per choice, the last one from then on.
var _picks := PackedStringArray()
var _choices_made := 0
var _chapter := &""
var _beat := &""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.visible = false
	var args := DevArgs.parse()
	DevArgs.apply_window(get_window(), args)
	if args.has("chapter"):
		main.start_chapter = StringName(args["chapter"])
	if args.has("beat"):
		main.start_beat = StringName(args["beat"])
	if _jump_chapter != &"":
		main.start_chapter = _jump_chapter
		main.start_beat = _jump_beat
	main.run_player.chapter_started.connect(func(chapter: ChapterData) -> void: _chapter = chapter.id)
	main.run_player.beat_started.connect(func(beat: BeatData) -> void: _beat = beat.id)
	menu.picked.connect(_jump_to)
	if args.has("menu") and not _menu_opened:
		_menu_opened = true
		_open_menu_after(float(args["menu"]), str(args.get("menu-pick", "")))
	if args.has("target") or args.has("home"):
		# A stage is set up just after it enters the tree, so this lands before the nuke stage picks.
		# Any other stage has no such property and ignores it.
		main.question_player.stage_root.child_entered_tree.connect(func(node: Node) -> void:
			node.set(&"target_override", str(args.get("target", "")))
			node.set(&"home_override", str(args.get("home", ""))))
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
		_autoplay(args["autoplay"], args.has("point"))
		if args.has("every") and not _shot_path.is_empty():
			_shoot_every(float(args["every"]))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"dev_menu"):
		get_viewport().set_input_as_handled()
		if menu.is_open():
			menu.close()
		else:
			menu.open(main.chapters, _chapter, _beat)
	elif event.is_action_pressed(&"dev_restart"):
		_restart()
	elif event.is_action_pressed(&"dev_overlay"):
		overlay.visible = not overlay.visible


## Starts the run over at [param chapter], from [param beat] or its top, and keeps that as the place
## F5 starts from.
func _jump_to(chapter: StringName, beat: StringName) -> void:
	_jump_chapter = chapter
	_jump_beat = beat
	_restart()


func _restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


## Opens the menu [param seconds] in, then picks [param pick] (chapter:beat) from it, if given.
func _open_menu_after(seconds: float, pick: String) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout
	menu.open(main.chapters, _chapter, _beat)
	if pick.is_empty():
		return
	await get_tree().create_timer(autoplay_delay * 2.0, true, false, true).timeout
	if not _shot_path.is_empty():
		await _shoot()
	var parts := pick.split(":")
	menu.pick(StringName(parts[0]), StringName(parts[1] if parts.size() > 1 else ""))


func _process(_delta: float) -> void:
	if not overlay.visible:
		return
	var player: QuestionPlayer = main.question_player
	var lines := PackedStringArray()
	var question := player.question
	lines.append("%s  %s  %s" % [_chapter, question.number + " " + question.title if question != null else "between questions",
			QuestionPlayer.Phase.keys()[player.phase].to_lower()])
	var profile: Profile = main.profile
	for axis in profile.leanings:
		lines.append("%s  %+.0f" % [axis, profile.leanings[axis]])
	overlay.text = "\n".join(lines)


func _autoplay(picks: String, pointing: bool) -> void:
	_picks = picks.split(",")
	var player: QuestionPlayer = main.question_player
	player.dialogue.waiting_changed.connect(func(waiting: bool) -> void:
		if waiting:
			_act(&"advance"))
	player.choosing_started.connect(func() -> void: _pick(_next_pick(), pointing))
	player.reveal.settled.connect(func() -> void: _act(&"advance"))


## The pick for the next choice: the next in the list, or the last one once the list runs out.
func _next_pick() -> String:
	var pick := _picks[mini(_choices_made, _picks.size() - 1)]
	_choices_made += 1
	return pick


## Picks the option autoplay was asked for: on the stage when pointing and the stage shows it there,
## and otherwise in the choice row. On a stage that takes the choice by itself, it clicks the option
## where the stage shows it, or leaves the stage to decide.
func _pick(pick: String, pointing: bool) -> void:
	var stage: Stage = main.question_player.stage
	var lever := pick == "lever"
	var index := _first_shown(stage) if lever else int(pick) - 1
	var at := stage.option_point(index) if stage != null else Vector2.INF
	if stage != null and stage.chooses_alone():
		if at.is_finite():
			await _click_at(at)
		return
	if lever or pointing:
		if at.is_finite():
			await _click_at(at)
			return
		push_warning("autoplay: the stage does not show option %d, picking it in the choice row" % (index + 1))
	_act(StringName("choose_%d" % (index + 1)))


## The first option [param stage] shows in the scene, or the first option when it shows none.
func _first_shown(stage: Stage) -> int:
	if stage == null:
		return 0
	for i in stage.question.options.size():
		if stage.option_point(i).is_finite():
			return i
	return 0


## Moves the pointer to [param point] on the canvas, then clicks there, with synthetic pointer events.
func _click_at(point: Vector2) -> void:
	await get_tree().create_timer(autoplay_delay, true).timeout
	var at := get_viewport().get_screen_transform() * point
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


func _shoot_every(seconds: float) -> void:
	while seconds > 0.0:
		await get_tree().create_timer(seconds, true).timeout
		await _shoot()


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
