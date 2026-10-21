class_name Imp
extends Node2D
## The imp, who runs the game and narrates every word of it. He scribbles into being with a pop and
## never quite keeps still: his line jitters, he twitches, his tail sways, and every few seconds he
## fidgets. He nods and gestures while he talks, and hops to a fresh spot for each new dialogue box.
## He keeps to the side wings and never stands on the stage. His origin is the ground between his feet.

## Emitted when he has finished scribbling into being.
signal appeared
## Emitted when a hop lands.
signal landed

enum Wing { LEFT, RIGHT }

## His drawing, which the idle life and the talking animate.
@export var drawing: ImpDrawing

@export_group("Wings")
## Where his feet may land left of the stage, in canvas pixels.
@export var left_wing := Rect2(110.0, 380.0, 120.0, 260.0)
## Where his feet may land right of the stage, in canvas pixels.
@export var right_wing := Rect2(1690.0, 380.0, 120.0, 260.0)
## The shortest hop worth making, in pixels.
@export_range(0.0, 400.0, 1.0) var min_hop := 70.0
## Seconds he stays put after arriving before he will hop again.
@export_range(0.0, 10.0, 0.05) var min_stay := 0.8
## Seed for where he hops. Zero picks a new one every run.
@export var hop_seed := 0

@export_group("Idle")
## Frames a second of his idle motion, stepped like hand-drawn animation.
@export_range(1.0, 60.0, 1.0) var idle_fps := 12.0
## How far he bobs at the knees, in pixels.
@export_range(0.0, 10.0, 0.1) var bob_depth := 2.0
## Seconds per bob.
@export_range(0.1, 10.0, 0.05) var bob_period := 1.6
## How far he sways side to side, in degrees.
@export_range(0.0, 15.0, 0.1) var sway := 2.5
## Seconds per sway.
@export_range(0.1, 10.0, 0.05) var sway_period := 4.2
## How much he swells with each breath, as a fraction of his height.
@export_range(0.0, 0.1, 0.001) var breath_swell := 0.02
## Seconds per breath.
@export_range(0.1, 10.0, 0.05) var breath_period := 2.8
## How far his tail sways, in degrees.
@export_range(0.0, 45.0, 0.5) var tail_sway := 6.0
## Seconds per tail sway.
@export_range(0.1, 10.0, 0.05) var tail_period := 1.9

@export_group("Jitter")
## How far he twitches off his spot each idle frame, in pixels.
@export_range(0.0, 6.0, 0.05) var twitch := 0.7
## How far his head twitches each idle frame, in degrees.
@export_range(0.0, 10.0, 0.1) var head_twitch := 1.2

@export_group("Fidgets")
## Shortest and longest pause between fidgets, in seconds.
@export var fidget_gap := Vector2(1.8, 4.5)
## Seconds a fidget takes, out and back.
@export_range(0.05, 2.0, 0.01) var fidget_duration := 0.32
## How far a shrug lifts his arms, in degrees.
@export_range(0.0, 60.0, 0.5) var shrug_lift := 28.0
## How far a tail flick swings, in degrees.
@export_range(0.0, 45.0, 0.5) var flick_swing := 26.0
## How deep a bounce dips, in pixels.
@export_range(0.0, 10.0, 0.1) var bounce_dip := 6.0
## How far a head cock tips, in degrees.
@export_range(0.0, 30.0, 0.5) var head_cock := 12.0

@export_group("Talking")
## How far his head nods while he talks, in degrees.
@export_range(0.0, 20.0, 0.1) var nod_angle := 5.0
## Nods a second while he talks.
@export_range(0.1, 6.0, 0.05) var nod_rate := 2.2
## How far his arms wave while he talks, in degrees.
@export_range(0.0, 45.0, 0.5) var talk_gesture := 10.0

@export_group("Hopping")
## Seconds from takeoff to landing.
@export_range(0.05, 2.0, 0.01) var hop_duration := 0.42
## How high the hop rises above the higher of its two ends, in pixels.
@export_range(0.0, 300.0, 1.0) var hop_height := 70.0
## Seconds he crouches before he jumps.
@export_range(0.0, 0.5, 0.01) var hop_windup := 0.08
## His squash when he crouches and lands: wider and shorter.
@export var squash := Vector2(1.16, 0.84)
## His stretch as he takes off: narrower and taller.
@export var stretch := Vector2(0.9, 1.1)
## Seconds the landing squash takes to hit.
@export_range(0.0, 0.5, 0.01) var land_squash_time := 0.06
## Seconds he takes to spring back into shape after landing.
@export_range(0.0, 2.0, 0.01) var hop_settle := 0.35

@export_group("Appearing")
## Seconds he takes to scribble into being.
@export_range(0.05, 3.0, 0.01) var scribble_duration := 0.55
## Scale he starts from as he scribbles in.
@export_range(0.1, 2.0, 0.01) var scribble_scale := 0.9
## Scale he pops to just as he finishes.
@export_range(0.5, 2.0, 0.01) var pop_scale := 1.12
## Seconds the pop takes to settle.
@export_range(0.0, 2.0, 0.01) var pop_settle := 0.25
## Seconds he takes to dissolve when he leaves.
@export_range(0.05, 3.0, 0.01) var vanish_duration := 0.5

## Which wing he is in.
var wing: Wing = Wing.RIGHT

var _talking := false
var _time := 0.0
var _arrived_at := 0.0
var _since_step := 0.0
var _rng := RandomNumberGenerator.new()
var _hop: Tween
var _next_fidget_at := 0.0
var _fidget: Tween
## What the fidget under way adds to his pose. Tweened by name.
var _fidget_arms := 0.0
var _fidget_tail := 0.0
var _fidget_crouch := 0.0
var _fidget_head := 0.0


func _ready() -> void:
	if hop_seed != 0:
		_rng.seed = hop_seed
	else:
		_rng.randomize()
	visible = false
	_schedule_fidget()


func _process(delta: float) -> void:
	_time += delta
	_since_step += delta
	if _since_step < 1.0 / idle_fps:
		return
	_since_step = 0.0
	if _time >= _next_fidget_at and not is_hopping():
		_start_fidget()
	drawing.jitter_frame += 1
	drawing.position = Vector2(_rng.randf_range(-twitch, twitch), _rng.randf_range(-twitch, twitch))
	drawing.crouch = (0.5 - 0.5 * cos(_time * TAU / bob_period)) * bob_depth + _fidget_crouch
	drawing.lean = sin(_time * TAU / sway_period) * sway
	var swell := sin(_time * TAU / breath_period) * breath_swell
	drawing.scale = Vector2(1.0 - swell * 0.5, 1.0 + swell)
	var talk := sin(_time * TAU * nod_rate) if _talking else 0.0
	drawing.head_tilt = talk * nod_angle + _rng.randf_range(-head_twitch, head_twitch) + _fidget_head
	drawing.arm_lift = absf(talk) * talk_gesture + _fidget_arms
	drawing.tail_swing = sin(_time * TAU / tail_period) * tail_sway + _fidget_tail


## Scribbles him into being at a fresh spot in [param in_wing]. Emits [signal appeared].
func appear(in_wing: Wing = Wing.RIGHT) -> void:
	wing = in_wing
	position = _pick_spot(_wing_rect(wing))
	visible = true
	drawing.dissolve = 0.0
	scale = Vector2.ONE * scribble_scale
	var tween := create_tween()
	tween.tween_property(drawing, ^"reveal", 1.0, scribble_duration).from(0.0)
	tween.parallel().tween_property(self, ^"scale", Vector2.ONE * pop_scale, scribble_duration) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, ^"scale", Vector2.ONE, pop_settle).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished
	_arrived_at = _time
	appeared.emit()


## Hops to a fresh spot in his wing. Emits [signal landed].
func hop() -> void:
	await hop_to(_pick_spot(_wing_rect(wing)))


## Hops to a fresh spot, unless he is mid hop or arrived where he is too recently.
func hop_if_settled() -> void:
	if is_hopping() or _time - _arrived_at < min_stay:
		return
	await hop()


## Whether he is in the air or landing.
func is_hopping() -> bool:
	return _hop != null and _hop.is_running()


## Hops to [param target], squashing and stretching on the way. Emits [signal landed].
func hop_to(target: Vector2) -> void:
	if _hop != null and _hop.is_valid():
		_hop.kill()
	var start := position
	var peak := minf(start.y, target.y) - hop_height
	var control := Vector2((start.x + target.x) * 0.5, 2.0 * peak - 0.5 * (start.y + target.y))
	_hop = create_tween()
	_hop.tween_property(self, ^"scale", squash, hop_windup).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_hop.tween_method(_arc.bind(start, control, target), 0.0, 1.0, hop_duration)
	_hop.parallel().tween_property(self, ^"scale", stretch, hop_duration * 0.3)
	_hop.parallel().tween_property(self, ^"scale", Vector2.ONE, hop_duration * 0.4).set_delay(hop_duration * 0.5)
	_hop.tween_property(self, ^"scale", squash, land_squash_time)
	_hop.tween_property(self, ^"scale", Vector2.ONE, hop_settle).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	await _hop.finished
	_arrived_at = _time
	landed.emit()


## Starts or stops his nodding along with what he says.
func set_talking(talking: bool) -> void:
	_talking = talking


## Sets his expression.
func set_face(face: ImpDrawing.Face) -> void:
	drawing.face = face


## Dissolves him away.
func vanish() -> void:
	await drawing.dissolve_away(vanish_duration).finished
	visible = false


func _schedule_fidget() -> void:
	_next_fidget_at = _time + _rng.randf_range(fidget_gap.x, fidget_gap.y)


## One quick fidget, out and back: a shrug, a tail flick, a bounce or a cocked head.
func _start_fidget() -> void:
	_schedule_fidget()
	var fidgets := [[^"_fidget_arms", shrug_lift], [^"_fidget_tail", flick_swing],
			[^"_fidget_crouch", bounce_dip], [^"_fidget_head", head_cock * (1.0 if _rng.randf() < 0.5 else -1.0)]]
	var pick: Array = fidgets[_rng.randi_range(0, fidgets.size() - 1)]
	if _fidget != null and _fidget.is_valid():
		_fidget.kill()
		for each: Array in fidgets:
			set(each[0], 0.0)
	_fidget = create_tween()
	_fidget.tween_property(self, pick[0], pick[1], fidget_duration * 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_fidget.tween_property(self, pick[0], 0.0, fidget_duration * 0.65).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _arc(t: float, start: Vector2, control: Vector2, target: Vector2) -> void:
	position = start.lerp(control, t).lerp(control.lerp(target, t), t)


func _wing_rect(which: Wing) -> Rect2:
	return left_wing if which == Wing.LEFT else right_wing


func _pick_spot(wing: Rect2) -> Vector2:
	var spot := position
	for attempt in 8:
		spot = Vector2(_rng.randf_range(wing.position.x, wing.end.x), _rng.randf_range(wing.position.y, wing.end.y))
		if spot.distance_to(position) >= min_hop:
			break
	return spot
