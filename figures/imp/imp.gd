class_name Imp
extends Node2D
## The imp, who runs the game and narrates every word of it. He scribbles into being with a pop and
## never quite keeps still: his line jitters like boiling ink, his tail sways, and every few seconds he
## fidgets. His body moves softly and eased, never snapping. He nods and gestures while he talks, his
## mouth moving in time with his words, and hops to a fresh spot for each new page. While a stage is up
## he keeps to his wing; once the page is his, with no stage up, he roams it now and then between lines:
## forward to the middle, then about the open floor, a long trip a run of hops, until he hops home for
## the next stage. His origin is the ground between his feet.

## Emitted when he has finished scribbling into being.
signal appeared
## Emitted when a hop lands.
signal landed

enum Wing { LEFT, RIGHT }

## His drawing, which the idle life and the talking animate.
@export var drawing: ImpDrawing
## Moves his mouth in time with what he says.
@export var mouth: ImpMouth

@export_group("Wings")
## Where his feet may land left of the stage, in canvas pixels.
@export var left_wing := Rect2(110.0, 380.0, 120.0, 260.0)
## Where his feet may land right of the stage, in canvas pixels.
@export var right_wing := Rect2(1690.0, 380.0, 120.0, 260.0)
## The shortest hop worth making, in pixels.
@export_range(0.0, 400.0, 1.0) var min_hop := 70.0
## Seconds he stays put after arriving before he will hop again.
@export_range(0.0, 10.0, 0.05) var min_stay := 0.8
## Seed for where he hops and how he drifts. Zero picks a new one every run.
@export var hop_seed := 0

@export_group("Roaming")
## Where his feet may land when the page is his, with no stage up: the open floor, wings and all.
@export var open_floor := Rect2(110.0, 420.0, 1700.0, 220.0)
## The middle of the page, where he steps forward to once it is empty.
@export var middle := Rect2(800.0, 470.0, 320.0, 150.0)
## The chance, at a new line once the page is his, that he steps forward from his wing to the middle.
@export_range(0.0, 1.0, 0.01) var forward_chance := 0.7
## The chance, at a new line while he is out of his wing, that he wanders on to another spot.
@export_range(0.0, 1.0, 0.01) var roam_chance := 0.35
## The chance that a wander takes him back to the middle rather than anywhere on the floor.
@export_range(0.0, 1.0, 0.01) var middle_chance := 0.4
## Seconds he stays where he wandered to before he will wander again.
@export_range(0.0, 30.0, 0.1) var roam_stay := 4.0
## How far round the spot he wandered to his hops on the spot may take him, across and up or down, in
## pixels.
@export var roam_room := Vector2(140.0, 80.0)
## The furthest one hop carries him on a trip, in pixels; a longer trip takes several.
@export_range(40.0, 1200.0, 1.0) var stride := 380.0
## How high a full stride rises, in pixels; shorter ones rise less, down to a plain hop's height.
@export_range(0.0, 400.0, 1.0) var stride_height := 110.0
## Seconds he takes to ease back into shape between the hops of a trip.
@export_range(0.0, 1.0, 0.01) var stride_settle := 0.06

@export_group("Idle")
## How far he bobs at the knees, in pixels.
@export_range(0.0, 10.0, 0.1) var bob_depth := 0.6
## Seconds per bob.
@export_range(0.1, 10.0, 0.05) var bob_period := 1.6
## How far he sways side to side, in degrees.
@export_range(0.0, 15.0, 0.1) var sway := 2.5
## Seconds per sway.
@export_range(0.1, 10.0, 0.05) var sway_period := 4.2
## How much he swells with each breath, as a fraction of his height.
@export_range(0.0, 0.1, 0.001) var breath_swell := 0.0
## Seconds per breath.
@export_range(0.1, 10.0, 0.05) var breath_period := 2.8
## How far his tail sways, in degrees.
@export_range(0.0, 45.0, 0.5) var tail_sway := 6.0
## Seconds per tail sway.
@export_range(0.1, 10.0, 0.05) var tail_period := 1.9

@export_group("Jitter")
## How many times a second his line jumps to its next shape. The page boils at 5; he is a little livelier.
@export_range(0.0, 24.0, 0.05) var jitter_rate := 8.0
## How far he drifts off his spot, in pixels. Zero keeps him planted.
@export_range(0.0, 6.0, 0.05) var drift := 0.0
## How quickly he drifts, in wanders a second.
@export_range(0.0, 6.0, 0.05) var drift_rate := 1.1
## How far his head wavers on its own, in degrees.
@export_range(0.0, 10.0, 0.1) var head_waver := 0.0

@export_group("Fidgets")
## Shortest and longest pause between fidgets, in seconds.
@export var fidget_gap := Vector2(2.0, 5.0)
## Seconds a fidget takes, out and back.
@export_range(0.05, 3.0, 0.01) var fidget_duration := 0.6
## How far a shrug lifts his arms, in degrees.
@export_range(0.0, 60.0, 0.5) var shrug_lift := 24.0
## How far a tail flick swings, in degrees.
@export_range(0.0, 45.0, 0.5) var flick_swing := 22.0
## How far a lean in tips him toward the stage, in degrees.
@export_range(0.0, 30.0, 0.5) var lean_in := 8.0
## How far a head cock tips, in degrees.
@export_range(0.0, 30.0, 0.5) var head_cock := 10.0

@export_group("Talking")
## How far his head nods while he talks, in degrees.
@export_range(0.0, 20.0, 0.1) var nod_angle := 4.0
## Nods a second while he talks.
@export_range(0.1, 6.0, 0.05) var nod_rate := 1.8
## How far his arms wave while he talks, in degrees.
@export_range(0.0, 45.0, 0.5) var talk_gesture := 9.0

@export_group("Hopping")
## Seconds from takeoff to landing.
@export_range(0.05, 2.0, 0.01) var hop_duration := 0.42
## How high the hop rises above the higher of its two ends, in pixels.
@export_range(0.0, 300.0, 1.0) var hop_height := 70.0
## Seconds he crouches before he jumps.
@export_range(0.0, 0.5, 0.01) var hop_windup := 0.1
## His squash when he crouches and lands: wider and shorter.
@export var squash := Vector2(1.1, 0.9)
## His stretch as he takes off: narrower and taller.
@export var stretch := Vector2(0.94, 1.06)
## Seconds the landing squash takes to hit.
@export_range(0.0, 0.5, 0.01) var land_squash_time := 0.08
## Seconds he takes to ease back into shape after landing.
@export_range(0.0, 2.0, 0.01) var hop_settle := 0.3

@export_group("Shot")
## How far he is knocked back and forth when the player shoots him, in pixels.
@export_range(0.0, 80.0, 0.5) var shot_jolt := 26.0
## How many times he is knocked back and forth.
@export_range(1, 8) var shot_jolts := 3
## Seconds the knocking takes.
@export_range(0.01, 2.0, 0.01) var shot_jolt_time := 0.3
## How he is squashed the instant the shot hits him, before he springs back into shape.
@export var shot_squash := Vector2(1.25, 0.78)
## How much bigger he grows as he rounds on the camera, coming at it.
@export_range(1.0, 3.0, 0.01) var round_scale := 1.45
## Seconds he takes to round on the camera.
@export_range(0.05, 2.0, 0.01) var round_duration := 0.4

@export_group("Appearing")
## Seconds he takes to scribble into being.
@export_range(0.05, 3.0, 0.01) var scribble_duration := 0.55
## Scale he starts from as he scribbles in.
@export_range(0.1, 2.0, 0.01) var scribble_scale := 0.9
## Scale he pops to just as he finishes.
@export_range(0.5, 2.0, 0.01) var pop_scale := 1.08
## Seconds the pop takes to settle.
@export_range(0.0, 2.0, 0.01) var pop_settle := 0.3
## Seconds he takes to dissolve when he leaves.
@export_range(0.05, 3.0, 0.01) var vanish_duration := 0.5

## Which wing he is in.
var wing: Wing = Wing.RIGHT
## Whether he has rounded on the camera, shot: he stays big and glaring, and does not hop, until he
## next appears.
var rounded := false
## Whether the page is his to roam, with no stage up. The run says so; while it is not, he keeps to his
## wing.
var free_to_roam := false

## Offsets into the drift's noise, so his two axes and his head wander independently.
const _DRIFT_Y_OFFSET := 37.3
const _HEAD_WAVER_OFFSET := 71.9

var _talking := false
var _time := 0.0
var _arrived_at := 0.0
## Where his hops on the spot keep for now: his wing, or a stretch of floor round the spot he roamed to.
var _home_area := Rect2()
## When he last arrived where he wandered to.
var _roamed_at := -INF
var _rng := RandomNumberGenerator.new()
var _drift_seed := 0
var _hop: Tween
var _next_fidget_at := 0.0
var _fidget: Tween
## What the fidget under way adds to his pose. Tweened by name.
var _fidget_arms := 0.0
var _fidget_tail := 0.0
var _fidget_lean := 0.0
var _fidget_head := 0.0


func _ready() -> void:
	if hop_seed != 0:
		_rng.seed = hop_seed
	else:
		_rng.randomize()
	_drift_seed = _rng.randi()
	visible = false
	_schedule_fidget()


func _process(delta: float) -> void:
	_time += delta
	if _time >= _next_fidget_at and not is_hopping():
		_start_fidget()
	drawing.jitter_phase += delta * jitter_rate
	var wander := _time * drift_rate
	drawing.position = Vector2(InkBrush.noise(wander, _drift_seed), InkBrush.noise(wander + _DRIFT_Y_OFFSET, _drift_seed)) * drift
	drawing.crouch = (0.5 - 0.5 * cos(_time * TAU / bob_period)) * bob_depth
	drawing.lean = sin(_time * TAU / sway_period) * sway + _fidget_lean
	var swell := sin(_time * TAU / breath_period) * breath_swell
	drawing.scale = Vector2(1.0 - swell * 0.5, 1.0 + swell)
	var talk := sin(_time * TAU * nod_rate) if _talking else 0.0
	drawing.head_tilt = talk * nod_angle + InkBrush.noise(wander + _HEAD_WAVER_OFFSET, _drift_seed) * head_waver + _fidget_head
	drawing.arm_lift = absf(talk) * talk_gesture + _fidget_arms
	drawing.tail_swing = sin(_time * TAU / tail_period) * tail_sway + _fidget_tail


## Scribbles him into being at a fresh spot in [param in_wing]. Emits [signal appeared].
func appear(in_wing: Wing = Wing.RIGHT) -> void:
	wing = in_wing
	rounded = false
	_home_area = _wing_rect(wing)
	_roamed_at = -INF
	position = _pick_spot(_home_area)
	visible = true
	drawing.dissolve = 0.0
	scale = Vector2.ONE * scribble_scale
	var tween := create_tween()
	tween.tween_property(drawing, ^"reveal", 1.0, scribble_duration).from(0.0)
	tween.parallel().tween_property(self, ^"scale", Vector2.ONE * pop_scale, scribble_duration) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, ^"scale", Vector2.ONE, pop_settle).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	_arrived_at = _time
	appeared.emit()


## Hops to a fresh spot where he keeps for now: his wing, or round the spot he roamed to. Emits
## [signal landed].
func hop() -> void:
	await hop_to(_pick_spot(_home_area))


## Hops to a fresh spot, unless he is mid hop, arrived where he is too recently, or has rounded on the camera.
func hop_if_settled() -> void:
	if rounded or is_hopping() or _time - _arrived_at < min_stay:
		return
	await hop()


## A new line begins. With the page his, he may step forward from his wing to the middle, or wander on
## from where he is; otherwise he hops on the spot as he does for any page.
func hop_for_line() -> void:
	if _may_roam():
		var home := _is_home()
		if _rng.randf() < (forward_chance if home else roam_chance):
			await _roam_to(middle if home or _rng.randf() < middle_chance else open_floor)
			return
	await hop_if_settled()


## Hops back to his wing, a stride at a time, unless he is there already: a stage is coming.
func go_home() -> void:
	_home_area = _wing_rect(wing)
	if rounded or not visible or _home_area.grow(min_hop).has_point(position):
		return
	await travel_to(_pick_spot(_home_area))


## Hops to [param target] a stride at a time, so a long trip is a run of hops rather than one leap.
func travel_to(target: Vector2) -> void:
	var start := position
	var hops := maxi(1, ceili(start.distance_to(target) / stride))
	var height := lerpf(hop_height, stride_height, clampf(start.distance_to(target) / hops / stride, 0.0, 1.0))
	for i in hops:
		var last := i == hops - 1
		await hop_to(start.lerp(target, float(i + 1) / hops), -1.0 if last else stride_settle, height)


## Shot: he is squashed and knocked back and forth, then glares and rounds on the camera, growing as he
## comes at it. He stays like that until he next appears.
func round_on_camera() -> void:
	rounded = true
	if _hop != null and _hop.is_valid():
		_hop.kill()
	var home := position
	scale = shot_squash
	create_tween().tween_property(self, ^"scale", Vector2.ONE, shot_jolt_time).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	var knock := create_tween()
	for i in shot_jolts:
		knock.tween_property(self, ^"position:x", home.x + shot_jolt * (1.0 if i % 2 == 0 else -1.0),
				shot_jolt_time / (shot_jolts + 1)).set_trans(Tween.TRANS_SINE)
	knock.tween_property(self, ^"position:x", home.x, shot_jolt_time / (shot_jolts + 1))
	await knock.finished
	set_face(ImpDrawing.Face.GLARE)
	var come := create_tween()
	come.tween_property(self, ^"scale", Vector2.ONE * round_scale, round_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await come.finished


## Whether he is in the air or landing.
func is_hopping() -> bool:
	return _hop != null and _hop.is_running()


## Hops to [param target], squashing and stretching softly on the way, rising [param height] pixels over
## the higher end ([member hop_height] when below zero) and easing back into shape for [param settle]
## seconds after landing ([member hop_settle] when below zero). Emits [signal landed].
func hop_to(target: Vector2, settle := -1.0, height := -1.0) -> void:
	if _hop != null and _hop.is_valid():
		_hop.kill()
	var start := position
	var peak := minf(start.y, target.y) - (hop_height if height < 0.0 else height)
	var control := Vector2((start.x + target.x) * 0.5, 2.0 * peak - 0.5 * (start.y + target.y))
	_hop = create_tween()
	_hop.tween_property(self, ^"scale", squash, hop_windup).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_hop.tween_method(_arc.bind(start, control, target), 0.0, 1.0, hop_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_hop.parallel().tween_property(self, ^"scale", stretch, hop_duration * 0.35).set_trans(Tween.TRANS_SINE)
	_hop.parallel().tween_property(self, ^"scale", Vector2.ONE, hop_duration * 0.4).set_delay(hop_duration * 0.5).set_trans(Tween.TRANS_SINE)
	_hop.tween_property(self, ^"scale", squash, land_squash_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_hop.tween_property(self, ^"scale", Vector2.ONE, hop_settle if settle < 0.0 else settle).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await _hop.finished
	_arrived_at = _time
	landed.emit()


## Starts or stops his nodding along with what he says, and his mouth moving with it.
func set_talking(talking: bool) -> void:
	_talking = talking
	mouth.talking = talking


## Has his mouth follow [param speech] while he talks: called with seconds to look ahead, it returns the
## character being said then, or an empty string when nothing is. [Main] hands him the dialogue box's
## [method DialogueBox.spoken_character].
func set_speech(speech: Callable) -> void:
	mouth.speech = speech


## Sets his expression.
func set_face(face: ImpDrawing.Face) -> void:
	drawing.face = face


## Dissolves him away.
func vanish() -> void:
	await drawing.dissolve_away(vanish_duration).finished
	visible = false


func _schedule_fidget() -> void:
	_next_fidget_at = _time + _rng.randf_range(fidget_gap.x, fidget_gap.y)


## One fidget, eased out and back: a shrug, a tail flick, a lean toward the stage or a cocked head.
func _start_fidget() -> void:
	_schedule_fidget()
	var fidgets := [[^"_fidget_arms", shrug_lift], [^"_fidget_tail", flick_swing],
			[^"_fidget_lean", lean_in * _toward_stage()], [^"_fidget_head", head_cock * (1.0 if _rng.randf() < 0.5 else -1.0)]]
	var pick: Array = fidgets[_rng.randi_range(0, fidgets.size() - 1)]
	if _fidget != null and _fidget.is_valid():
		_fidget.kill()
		for each: Array in fidgets:
			set(each[0], 0.0)
	_fidget = create_tween()
	_fidget.tween_property(self, pick[0], pick[1], fidget_duration * 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_fidget.tween_property(self, pick[0], 0.0, fidget_duration * 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## 1 when the stage is to his right, -1 when it is to his left.
func _toward_stage() -> float:
	return 1.0 if wing == Wing.LEFT else -1.0


func _arc(t: float, start: Vector2, control: Vector2, target: Vector2) -> void:
	position = start.lerp(control, t).lerp(control.lerp(target, t), t)


func _wing_rect(which: Wing) -> Rect2:
	return left_wing if which == Wing.LEFT else right_wing


## Whether he may wander off now: the page is his, he is up and unshot, not mid hop, and has stayed put
## long enough.
func _may_roam() -> bool:
	return free_to_roam and visible and not rounded and not is_hopping() \
			and _time - _arrived_at >= min_stay and _time - _roamed_at >= roam_stay


## Whether he is keeping to his wing.
func _is_home() -> bool:
	return _home_area == _wing_rect(wing)


## Wanders to a fresh spot in [param area], and keeps round it until he next wanders or goes home.
func _roam_to(area: Rect2) -> void:
	var spot := _pick_spot(area)
	_home_area = Rect2(spot - roam_room * 0.5, roam_room).intersection(open_floor)
	await travel_to(spot)
	_roamed_at = _time


func _pick_spot(wing_rect: Rect2) -> Vector2:
	var spot := position
	for attempt in 8:
		spot = Vector2(_rng.randf_range(wing_rect.position.x, wing_rect.end.x), _rng.randf_range(wing_rect.position.y, wing_rect.end.y))
		if spot.distance_to(position) >= min_hop:
			break
	return spot
