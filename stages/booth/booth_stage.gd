class_name BoothStage
extends Stage
## The confession booth, where the dead judge does his old job. A soul files into the booth, the words
## it stands by floating over the roof, and the imp announces its case; it states its side in the
## dialogue box, gesturing as it speaks, and the player rules one of three ways. The gavel is heard, not
## seen, as the gun is: a knock, and the page jolts. The soul takes the verdict, hanging its head,
## opening its arms or shrugging, and once the imp has had his say it files out and the booth goes.
## A case can have two souls, standing either side of the booth, or the walking button, which slides in
## as a plain button and comes alive, saying its lines over itself in its own voice.
## Stage data:
## [codeblock]
## {"type": "booth", "confessors": [{"voice": "recliner", "says": {"text": "...", "speaker": "headline"}}]}
## [/codeblock]
## A confessor's [code]voice[/code] matches the [code]voice[/code] of its lines in the ask, so the one
## speaking is the one who gestures. [code]"side": "left"[/code] or [code]"right"[/code] stands it
## beside the booth instead of in it, and [code]"button": true[/code] makes it the walking button. Its
## [code]says[/code] floats over it as it arrives. An option's outcome names the verdict,
## [code]{"verdict": "guilty"}[/code] ([code]cleared[/code] or [code]everyone[/code] otherwise), or one
## per confessor by voice: [code]{"verdict": {"her": "cleared", "him": "guilty"}}[/code]. The walking
## button says the question's [code]leave[/code] lines as it files out.

## The booth.
@export var booth: ConfessionBooth
## The walking button's scene, for a case the button confesses.
@export var walker_scene: PackedScene
## The words floating over a confessor that is not the walking button.
@export var words_scene: PackedScene
## The gavel's knock, on the SFX bus.
@export var gavel: AudioStreamPlayer

@export_group("Confessors")
## The kind of soul that confesses when the case does not say.
@export var default_kind := &"stranger"
## How much bigger than its kind's own size a confessor is drawn: the booth brings them close.
@export_range(0.5, 4.0, 0.05) var soul_scale := 1.7
## How far either side of the booth's middle two confessors stand.
@export_range(0.0, 800.0, 1.0) var side_offset := 330.0
## How far off a confessor starts before it walks in, from where it stands.
@export_range(0.0, 1500.0, 5.0) var enter_distance := 520.0
## The furthest left and right a confessor comes in from or walks off to, so it never crosses the imp's
## wing.
@export var walk_bounds := Vector2(60.0, 1600.0)
## How fast a confessor walks in, in pixels a second.
@export_range(10.0, 600.0, 5.0) var walk_speed := 150.0
## Seconds a confessor takes to ink in as it walks in.
@export_range(0.0, 3.0, 0.05) var ink_in := 0.8
## Gap between the top of the booth, or the head of a soul beside it, and the words floating over it.
@export_range(0.0, 200.0, 1.0) var words_gap := 22.0
## The walking button's look.
@export var button_look := &"green"
## How much bigger the walking button is drawn than its own size.
@export_range(0.2, 3.0, 0.05) var button_scale := 0.62
## Seconds the walking button takes to slide in as a plain button.
@export_range(0.05, 5.0, 0.05) var slide_time := 1.4

@export_group("Talking")
## The gestures a confessor moves through while it speaks, in turn.
@export var talk_poses: Array[FigurePose] = []
## Seconds each gesture takes.
@export_range(0.05, 3.0, 0.01) var talk_beat := 0.55
## Seconds a confessor takes to settle back once it stops speaking.
@export_range(0.05, 3.0, 0.01) var settle_time := 0.4
## Seconds the walking button pauses after each line it says.
@export_range(0.0, 3.0, 0.05) var button_beat := 0.3

@export_group("Verdict")
## How a soul found guilty takes it. Its eyes close too.
@export var guilty_pose: FigurePose
## How a soul cleared takes it.
@export var cleared_pose: FigurePose
## How a soul takes it when everyone sucks.
@export var everyone_pose: FigurePose
## How the walking button holds its arms when it is found guilty.
@export var button_guilty_arms: ButtonArmPose
## How the walking button holds its arms when it is cleared.
@export var button_cleared_arms: ButtonArmPose
## How the walking button holds its arms when everyone sucks.
@export var button_everyone_arms: ButtonArmPose
## How high a cleared soul hops with relief.
@export_range(0.0, 80.0, 0.5) var relief_hop := 14.0
## Seconds the hop takes, up and down.
@export_range(0.05, 2.0, 0.01) var relief_hop_time := 0.3
## How far the page jolts with the gavel's knock, in pixels.
@export_range(0.0, 40.0, 0.5) var knock_jolt := 5.0
## Seconds the jolt takes.
@export_range(0.01, 1.0, 0.01) var knock_jolt_time := 0.16
## Seconds the verdict holds before the imp has his say, for a light case.
@export_range(0.0, 5.0, 0.05) var hold_light := 0.7
## Seconds it holds for a medium case.
@export_range(0.0, 5.0, 0.05) var hold_medium := 1.0
## Seconds it holds for a heavy case.
@export_range(0.0, 5.0, 0.05) var hold_heavy := 1.6

@export_group("Filing out")
## How far a confessor walks off once the imp has had his say: on past the booth for one in it, or
## away to its own side for one beside it.
@export_range(0.0, 1500.0, 5.0) var exit_distance := 480.0
## How fast it walks off, in pixels a second.
@export_range(10.0, 600.0, 5.0) var exit_speed := 170.0
## How much slower a soul found guilty walks off, as a share of that pace.
@export_range(0.1, 1.0, 0.05) var guilty_pace := 0.65
## Seconds over which it fades at the end of its walk.
@export_range(0.0, 3.0, 0.05) var exit_fade := 0.8
## Which way the walking button walks off: -1 left, 1 right. Left keeps it clear of the imp's wing.
@export_range(-1, 1, 2) var button_exit := -1

## A verdict a confessor can take.
const GUILTY := &"guilty"
const CLEARED := &"cleared"
const EVERYONE := &"everyone"

const _CONFESSORS_KEY := "confessors"
## The question's lines the walking button says as it files out.
const _LEAVE_LINES := &"leave"


## One soul confessing: who it is, where it stands, and the words it stands by.
class Confessor:
	## The stick figure, or the walking button.
	var body: Node2D
	## The voice its lines carry, matched to theirs.
	var voice := &""
	## Where it stands, on the stage.
	var spot := Vector2.ZERO
	## Whether it stands in the booth rather than beside it.
	var in_booth := true
	## Which side it comes in from: -1 left, 1 right.
	var side := -1
	## The words it arrives with, floating over it, or null.
	var said: LineData
	## Its floating words, for a stick figure.
	var words: Plea
	## The verdict it took.
	var verdict := &""
	## Counts its turns to speak, so a gesture under way knows when it has been stopped.
	var talk_count := 0


var _confessors: Array[Confessor] = []
## The one speaking in the box right now, or null.
var _speaking: Confessor
var _rng := RandomNumberGenerator.new()


func setup(for_question: QuestionData) -> void:
	super.setup(for_question)
	var said := for_question.stage_lines
	var next_said := 0
	for entry: Variant in for_question.stage.get(_CONFESSORS_KEY, []):
		if not entry is Dictionary:
			continue
		var data: Dictionary = entry
		var confessor := Confessor.new()
		confessor.voice = StringName(str(data.get("voice", "")))
		match str(data.get("side", "")):
			"left":
				confessor.in_booth = false
				confessor.side = -1
			"right":
				confessor.in_booth = false
				confessor.side = 1
		confessor.spot = booth.position + Vector2(0.0 if confessor.in_booth else side_offset * confessor.side, 0.0)
		if data.has("says") and next_said < said.size():
			confessor.said = said[next_said]
			next_said += 1
		confessor.body = _make_walker() if bool(data.get("button", false)) else _make_soul(data)
		confessor.body.position = Vector2(_bounded(confessor.spot.x + enter_distance * confessor.side), confessor.spot.y)
		confessor.body.visible = false
		add_child(confessor.body)
		if confessor.said != null and confessor.body is StickFigure and words_scene != null:
			confessor.words = words_scene.instantiate() as Plea
			add_child(confessor.words)
			confessor.words.set_words(confessor.said.text)
			confessor.words.modulate.a = 0.0
		_confessors.append(confessor)
	if dialogue != null:
		dialogue.page_shown.connect(_on_page_shown)
		dialogue.talking_changed.connect(_on_talking_changed)


## The booth draws itself on, then the confessors file in and say the words they stand by.
func enter() -> void:
	await super.enter()
	await _all_at_once(_file_in)


func speaks(line: LineData) -> bool:
	return line.speaker == &"button" and _walker() != null


func say_line(line: LineData) -> void:
	var walker := _walker()
	if walker == null:
		return
	walker.say(line.text, VoiceLibrary.clip_for(line))
	await walker.finish_saying()
	await get_tree().create_timer(button_beat, false).timeout


## The gavel comes down, heard and not seen, and each confessor takes its verdict.
func play_consequence(index: int) -> StringName:
	if index < 0 or index >= question.options.size():
		return &""
	_stop_talking()
	var verdict: Variant = question.options[index].outcome.get("verdict", "")
	for confessor in _confessors:
		var taken: Variant = verdict.get(String(confessor.voice), "") if verdict is Dictionary else verdict
		confessor.verdict = StringName(str(taken))
	_knock()
	await _all_at_once(_take_verdict)
	await get_tree().create_timer(_verdict_hold(), false).timeout
	return &""


## Once the imp has had his say, the confessors file out, the walking button saying its goodbye on the
## way, and the booth goes.
func leave() -> void:
	_stop_talking()
	await _all_at_once(_file_out)
	await super.leave()


func _exit_tree() -> void:
	if dialogue == null:
		return
	if dialogue.page_shown.is_connected(_on_page_shown):
		dialogue.page_shown.disconnect(_on_page_shown)
	if dialogue.talking_changed.is_connected(_on_talking_changed):
		dialogue.talking_changed.disconnect(_on_talking_changed)


## A soul of the kind the entry names, drawn at the booth's size.
func _make_soul(data: Dictionary) -> Node2D:
	var kind := SoulKind.find(StringName(str(data.get("kind", default_kind))))
	if kind == null:
		kind = SoulKind.find(default_kind)
	var soul := kind.make()
	soul.scale *= soul_scale
	return soul


## The walking button, dormant: a plain button until it is in the booth.
func _make_walker() -> Node2D:
	var walker := walker_scene.instantiate() as WalkingButton
	walker.scale = Vector2.ONE * button_scale
	walker.words_keep_size = true
	walker.body.look = ButtonLook.find(button_look)
	return walker


## The walking button among the confessors, or null.
func _walker() -> WalkingButton:
	for confessor in _confessors:
		if confessor.body is WalkingButton:
			return confessor.body as WalkingButton
	return null


## Runs [param action] on every confessor at once, and returns once each of them is done.
func _all_at_once(action: Callable) -> void:
	var running := [_confessors.size()]
	for confessor in _confessors:
		_run(action, confessor, running)
	while running[0] > 0:
		await get_tree().process_frame


func _run(action: Callable, confessor: Confessor, running: Array) -> void:
	await action.call(confessor)
	running[0] -= 1


## [param confessor] files in, inking in as it comes, and the words it stands by float up over it. The
## walking button slides in as a plain button and comes alive in the booth, and says its words aloud.
func _file_in(confessor: Confessor) -> void:
	confessor.body.visible = true
	confessor.body.modulate.a = 0.0
	create_tween().tween_property(confessor.body, ^"modulate:a", 1.0, ink_in)
	var walker := confessor.body as WalkingButton
	if walker != null:
		var slide := create_tween()
		slide.tween_property(walker, ^"position:x", confessor.spot.x, slide_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await slide.finished
		walker.words_spot = walker.to_local(to_global(_words_spot(confessor)))
		await walker.come_alive()
		if confessor.said != null:
			await say_line(confessor.said)
		return
	var figure := confessor.body as StickFigure
	if figure != null:
		await figure.walk_to(confessor.spot.x, walk_speed)
		figure.facing = StickFigure.Facing.FRONT
	if confessor.words != null:
		confessor.words.place(_words_spot(confessor))
		confessor.words.modulate.a = 1.0
		await confessor.words.write_on(VoiceLibrary.clip_for(confessor.said))


## Where the words over [param confessor] go: over the booth's roof for one in it, over its head for
## one beside it.
func _words_spot(confessor: Confessor) -> Vector2:
	if confessor.in_booth:
		return booth.position + booth.top() - Vector2(0.0, words_gap)
	var figure := confessor.body as StickFigure
	var head := to_local(figure.to_global(figure.head_top())) if figure != null else confessor.spot
	return head - Vector2(0.0, words_gap)


## [param confessor] takes its verdict: a soul hangs its head and shuts its eyes when found guilty, opens
## its arms with a hop of relief when cleared, and shrugs when everyone sucks; the walking button holds
## its arms the same ways.
func _take_verdict(confessor: Confessor) -> void:
	var walker := confessor.body as WalkingButton
	if walker != null:
		var arms := {GUILTY: button_guilty_arms, CLEARED: button_cleared_arms, EVERYONE: button_everyone_arms}
		if arms.get(confessor.verdict) != null:
			walker.hold_arms(arms[confessor.verdict])
		return
	var figure := confessor.body as StickFigure
	if figure == null:
		return
	var poses := {GUILTY: guilty_pose, CLEARED: cleared_pose, EVERYONE: everyone_pose}
	var pose: FigurePose = poses.get(confessor.verdict)
	if pose == null:
		return
	if confessor.verdict == GUILTY:
		figure.eyes = StickFigure.Eyes.CLOSED
	var taking := figure.blend_to(pose, pose.arrive_duration, pose.arrive_transition, pose.arrive_ease)
	if confessor.verdict == CLEARED and relief_hop > 0.0:
		var ground := figure.position.y
		var hop := create_tween()
		hop.tween_property(figure, ^"position:y", ground - relief_hop, relief_hop_time * 0.5) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		hop.tween_property(figure, ^"position:y", ground, relief_hop_time * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await taking.finished


## [param confessor] files out, its words fading: one in the booth walks on past it, one beside it walks
## off its own way, slower when found guilty, fading as it goes. The walking button says its goodbye and
## waddles off.
func _file_out(confessor: Confessor) -> void:
	if confessor.words != null:
		confessor.words.fade_out()
	var walker := confessor.body as WalkingButton
	if walker != null:
		for line in question.lines_in(_LEAVE_LINES):
			await say_line(line)
		await walker.walk_off(button_exit)
		return
	var figure := confessor.body as StickFigure
	if figure == null:
		return
	var way := 1 if confessor.in_booth else confessor.side
	var speed := exit_speed * (guilty_pace if confessor.verdict == GUILTY else 1.0)
	var to := _bounded(figure.position.x + exit_distance * way)
	figure.walk_to(to, speed)
	await get_tree().create_timer(maxf(absf(to - figure.position.x) / speed - exit_fade, 0.0), false).timeout
	await figure.dissolve_away(exit_fade).finished
	figure.visible = false


## [param x] kept within [member walk_bounds].
func _bounded(x: float) -> float:
	return clampf(x, walk_bounds.x, walk_bounds.y)


## The gavel's knock: heard, and the page jolts.
func _knock() -> void:
	if gavel != null and gavel.stream != null:
		gavel.play()
	var home := position
	var jolting := create_tween()
	for i in 3:
		var shake := Vector2(_rng.randf_range(-knock_jolt, knock_jolt), _rng.randf_range(-knock_jolt, knock_jolt))
		jolting.tween_property(self, ^"position", home + shake, knock_jolt_time / 4.0)
	jolting.tween_property(self, ^"position", home, knock_jolt_time / 4.0)


## Seconds the verdict holds before the imp has his say, by how heavy the case is.
func _verdict_hold() -> float:
	match question.weight:
		&"heavy":
			return hold_heavy
		&"medium":
			return hold_medium
	return hold_light


## A page appears: when it is a confessor's, that one is the one speaking.
func _on_page_shown(line: LineData, _page: int, _page_count: int) -> void:
	_stop_talking()
	if line.speaker != &"confessor":
		return
	for confessor in _confessors:
		if confessor.voice == line.voice:
			_speaking = confessor


## The one speaking gestures while its words ink on and its voice plays, and settles once it stops.
func _on_talking_changed(talking: bool) -> void:
	if _speaking == null:
		return
	if talking:
		_gesture(_speaking)
	else:
		_settle(_speaking)


## [param confessor] moves through its talking gestures, one after another, until it is stopped.
func _gesture(confessor: Confessor) -> void:
	var figure := confessor.body as StickFigure
	if figure == null or talk_poses.is_empty():
		return
	confessor.talk_count += 1
	var turn := confessor.talk_count
	var i := 0
	while confessor.talk_count == turn and is_instance_valid(figure):
		figure.blend_to(talk_poses[i % talk_poses.size()], talk_beat)
		i += 1
		await get_tree().create_timer(talk_beat, false).timeout


## [param confessor] stops gesturing and settles back into its pose.
func _settle(confessor: Confessor) -> void:
	confessor.talk_count += 1
	var figure := confessor.body as StickFigure
	if figure != null:
		figure.blend_to(figure.pose if figure.pose != null else FigurePose.new(), settle_time)


## Whoever was speaking settles, and nobody is.
func _stop_talking() -> void:
	if _speaking != null:
		_settle(_speaking)
	_speaking = null
