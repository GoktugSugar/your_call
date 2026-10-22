class_name WalkingButton
extends Node2D
## A push button that comes alive: the plain green button the imp offers in Chapter 2, which keeps
## turning up after. Dormant, it is only a push button. Woken, stick limbs grow out of it and it opens
## its dot eyes with a start; it gets up on its legs, says things in words that float over it, turns,
## holds its arms in a pose such as a shaken fist, and waddles off. While it stands about it bobs on its
## knees, blinks and now and then taps a foot, all stepped with the page's boil the way a stick figure
## breathes; getting up and walking run at full frame rate.
## Its body is a [PushButton], so it looks just like the button the player pressed, in any [ButtonLook].
## Its origin is the ground under the middle of its base.

## Emitted once it has come alive and got up.
signal came_alive
## Emitted each time a foot comes down while it walks.
signal stepped
## Emitted once it has walked out of sight.
signal walked_off

## Its body: the push button itself.
@export var body: PushButton
## Its legs and arms, drawn behind the body.
@export var limbs: ButtonLimbs
## Its eyes, drawn on the cap.
@export var face: ButtonFace
## The words that float over it while it talks.
@export var words_scene: PackedScene
## Whether it is alive. Setting it snaps it there with no fuss: alive, it stands with its limbs out and
## its eyes open; not alive, it is a plain push button again. [method come_alive] brings it to life with the fuss.
@export var alive := false:
	get:
		return _alive
	set(value):
		_alive = value
		_snap()
## Which way it faces: -1 left, 0 out of the page, 1 right. Setting it turns it at once;
## [method face_toward] swivels it round.
@export_range(-1, 1) var facing := 0:
	set(value):
		facing = signi(value)
		_turn = facing
		_apply_rig()

@export_group("Arms")
## How it holds its arms when it has nothing to say with them.
@export var rest_arms: ButtonArmPose
## How its arms come out as it wakes, wincing. Empty grows them at rest.
@export var wince_arms: ButtonArmPose
## How it flings its arms up when it wakes with a start. Empty keeps them where they are.
@export var startled_arms: ButtonArmPose
## How far its arms swing with each step, in degrees.
@export_range(0.0, 90.0, 0.5) var arm_swing := 22.0

@export_group("Standing")
## How far its legs lift its base off the ground when it stands, as a share of their length. Below 1
## the knees stay a little bent.
@export_range(0.1, 1.0, 0.01) var stand_share := 0.85
## Where its screen right foot rests while it sits on its base, from the middle; the left foot mirrors
## it. Below the ground, the legs stick out toward the player.
@export var sitting_foot := Vector2(60.0, 20.0)

@export_group("Waking")
## Seconds its limbs take to grow out.
@export_range(0.01, 3.0, 0.01) var sprout_duration := 0.3
## Seconds it winces with its eyes shut before they pop open.
@export_range(0.0, 3.0, 0.01) var wince_hold := 0.35
## How high it jolts off the ground as its eyes pop open, in pixels.
@export_range(0.0, 200.0, 0.5) var jolt_height := 26.0
## Seconds the jolt takes to rise.
@export_range(0.01, 1.0, 0.01) var jolt_rise_time := 0.07
## Seconds it takes to drop back down.
@export_range(0.01, 1.0, 0.01) var jolt_fall_time := 0.16
## How wide its eyes pop with the start, as a multiple of their size.
@export_range(1.0, 3.0, 0.01) var eye_pop := 1.45
## Seconds its eyes take to settle back to their size.
@export_range(0.01, 2.0, 0.01) var eye_settle_time := 0.4
## Seconds it holds its arms up before it lets them drop.
@export_range(0.0, 3.0, 0.01) var startled_hold := 0.35
## Its squash as it lands: wider and shorter.
@export var squash := Vector2(1.06, 0.93)
## Seconds the squash takes to hit, and to ease back out.
@export var squash_times := Vector2(0.05, 0.16)

@export_group("Getting up")
## Seconds it takes to get up off its base.
@export_range(0.01, 3.0, 0.01) var get_up_duration := 0.5
## Share of that time its feet take to tuck in under it.
@export_range(0.0, 1.0, 0.01) var tuck_share := 0.45
## Share of that time it pulls its feet in before its base starts to rise.
@export_range(0.0, 1.0, 0.01) var rise_delay := 0.2

@export_group("Walking")
## How fast it walks, in pixels a second.
@export_range(10.0, 5000.0, 1.0) var walk_speed := 250.0
## How far it travels with each step, in pixels.
@export_range(4.0, 300.0, 0.5) var step_length := 46.0
## How high a foot lifts as it swings through, in pixels.
@export_range(0.0, 100.0, 0.5) var step_height := 14.0
## How far its body rises over each step, in pixels.
@export_range(0.0, 40.0, 0.1) var walk_bob := 5.0
## How far its body rocks over the planted foot with each step, in degrees.
@export_range(0.0, 30.0, 0.1) var waddle := 5.0
## How far it leans the way it walks, in degrees.
@export_range(0.0, 30.0, 0.1) var walk_lean := 4.0
## Seconds it takes to turn round.
@export_range(0.01, 2.0, 0.01) var turn_duration := 0.14
## How far past the edge of the canvas it walks before it counts as gone, in pixels.
@export_range(0.0, 200.0, 0.5) var exit_margin := 12.0

@export_group("Idle")
## How far it bobs on its knees while it stands about, in pixels.
@export_range(0.0, 20.0, 0.1) var idle_bob := 1.6
## Seconds per bob.
@export_range(0.1, 10.0, 0.05) var idle_bob_period := 2.6
## Shortest and longest wait between blinks, in seconds.
@export var blink_gap := Vector2(2.2, 5.0)
## How many boil ticks a blink keeps its eyes shut.
@export_range(1, 10) var blink_ticks := 1
## Whether it taps a foot now and then while it stands about.
@export var foot_taps := true
## Shortest and longest wait between bouts of tapping, in seconds.
@export var tap_gap := Vector2(3.5, 8.0)
## Taps in each bout. A tap lifts the foot for one boil tick and puts it down for the next.
@export_range(1, 12) var taps := 3
## How high a tapping foot lifts, in pixels.
@export_range(0.0, 40.0, 0.5) var tap_height := 6.0
## Seed for when it blinks and taps. Zero picks a new one every run.
@export var idle_seed := 0

@export_group("Words")
## Gap between the top of its cap and the bottom of its words, in pixels.
@export_range(0.0, 200.0, 0.5) var words_gap := 16.0
## Whether its words keep their size on the page however big or small it is drawn.
@export var words_keep_size := false
## Where its words float, in its own space, when they should not ride just over its cap, such as over
## the roof of a booth it stands in. Left infinite, they float just over its cap.
@export var words_spot := Vector2.INF

var _alive := false
var _standing := false
var _walking := false
## The pose its arms are in, and the one handed to the limbs with the swing and the shake on top.
var _arms := ButtonArmPose.new()
var _drawn_arms := ButtonArmPose.new()
## Where its feet are while it walks, screen left then screen right, in its own space.
var _feet := PackedVector2Array([Vector2.ZERO, Vector2.ZERO])
## Which foot swings next: 0 is the screen left one, 1 the screen right.
var _lead := 1
## What the motion under way has done to it. Tweened by name.
var _growth := 0.0
var _rise := 0.0
var _tuck := 0.0
var _hop := 0.0
var _eye_scale := 1.0
var _squeeze := Vector2.ONE
var _turn := 0.0
var _eyes_shut := false
## What the step under way does to its body and arms.
var _step_bob := 0.0
var _step_tilt := 0.0
var _swing := 0.0
## Idle life, read off the page clock at each boil tick.
var _page_time := 0.0
var _shake_sign := 1.0
var _blink_left := 0
var _next_blink := 0.0
var _taps_left := 0
var _next_tap := 0.0
var _rng := RandomNumberGenerator.new()
var _words: Plea
var _words_at := Vector2.INF
var _motion: Tween
var _arms_tween: Tween
var _turn_tween: Tween
var _eyes_tween: Tween
## Each walk's ticket. A newer walk takes over from an older one, which stops at its next step.
var _walk_id := 0


func _ready() -> void:
	if idle_seed != 0:
		_rng.seed = idle_seed
	else:
		_rng.randomize()
	_page_time = Ink.time
	_schedule_blink()
	_schedule_taps()
	Ink.boiled.connect(_on_boiled.unbind(1))
	_snap()


func _process(_delta: float) -> void:
	if _alive:
		_apply_rig()


## Brings it to life with all the fuss: it wakes with a start where it sits ([method wake]), then gets
## up on its legs ([method stand_up]). Emits [signal came_alive].
func come_alive() -> void:
	await wake()
	await stand_up()
	came_alive.emit()


## Wakes it with a start where it sits: its limbs grow out of it while it winces, then its eyes pop open,
## it jolts off the ground and flings its arms up, and lets them drop. It stays sitting on its base.
func wake() -> void:
	if _alive:
		return
	_stop_all()
	_alive = true
	_standing = false
	_growth = 0.0
	_tuck = 0.0
	_rise = 0.0
	_eyes_shut = true
	var wince := wince_arms if wince_arms != null else _resting_arms()
	_arms.blend(wince, wince, 0.0)
	_motion = create_tween()
	_motion.tween_property(self, ^"_growth", 1.0, sprout_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_motion.tween_interval(wince_hold)
	await _motion.finished
	_eyes_shut = false
	_eye_scale = eye_pop
	_eyes_tween = create_tween()
	_eyes_tween.tween_property(self, ^"_eye_scale", 1.0, eye_settle_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if startled_arms != null:
		hold_arms(startled_arms)
	_motion = create_tween()
	_motion.tween_property(self, ^"_hop", jolt_height, jolt_rise_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_motion.tween_property(self, ^"_hop", 0.0, jolt_fall_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_motion.tween_property(self, ^"_squeeze", squash, squash_times.x).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_motion.tween_property(self, ^"_squeeze", Vector2.ONE, squash_times.y).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_motion.tween_interval(startled_hold)
	await _motion.finished
	await hold_arms(_resting_arms())


## Gets up off its base: it tucks its feet in under itself and its legs lift the base off the ground.
func stand_up() -> void:
	if not _alive or _standing:
		return
	_kill_motion()
	_motion = create_tween().set_parallel(true)
	_motion.tween_property(self, ^"_tuck", 1.0, get_up_duration * tuck_share) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_motion.tween_property(self, ^"_rise", _stand_height(), get_up_duration * (1.0 - rise_delay)) \
			.set_delay(get_up_duration * rise_delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await _motion.finished
	_standing = true
	_apply_rig()


## Says [param text], in markup with colour tags allowed, aloud in [param voice] when it has one: the
## words ink on over it, in time with the voice, and float along with it wherever it goes, until
## [method fade_words]. Anything it was still saying fades away. Returns once it has been said.
func say(text: String, voice: VoiceClip = null) -> void:
	if _words != null:
		_let_go(_words)
	_words = words_scene.instantiate() as Plea
	add_child(_words)
	if words_keep_size:
		_words.scale = Vector2.ONE / maxf(absf(scale.x), 0.01)
	_words.set_words(text)
	_words_at = Vector2.INF
	_place_words()
	await _words.write_on(voice)


## Waits until it has said what it is saying, voice and all. Returns at once when it is quiet.
func finish_saying() -> void:
	if _words != null and _words.is_saying():
		await _words.said


## Lets the words it is saying fade away.
func fade_words() -> void:
	if _words == null:
		return
	var words := _words
	_words = null
	await _let_go(words)


## Moves its arms into [param pose], the way the pose says to arrive. A shaking pose shakes on until the
## next one. No pose leaves the arms as they are.
func hold_arms(pose: ButtonArmPose) -> void:
	if pose == null:
		return
	if _arms_tween != null and _arms_tween.is_valid():
		_arms_tween.kill()
	var from := _arms.duplicate() as ButtonArmPose
	_arms_tween = create_tween()
	_arms_tween.tween_method(_blend_arms.bind(from, pose), 0.0, 1.0, maxf(pose.arrive_duration, 0.001)) \
			.set_trans(pose.arrive_transition).set_ease(pose.arrive_ease)
	await _arms_tween.finished


## Turns to face [param direction]: -1 left, 1 right, 0 out of the page. Its eyes slide across its cap.
func face_toward(direction: int) -> void:
	var target := signi(direction)
	if target == facing and is_equal_approx(_turn, target):
		return
	if _turn_tween != null and _turn_tween.is_valid():
		_turn_tween.kill()
	_turn_tween = create_tween()
	_turn_tween.tween_property(self, ^"_turn", float(target), turn_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await _turn_tween.finished
	facing = target


## Walks to [param x] on the ground, in its parent's space. It gets up first if it is sitting, turns the
## way it is going, and waddles there in even steps that fit the distance. It has to be alive.
func walk_to(x: float) -> void:
	if not _alive or is_zero_approx(x - position.x):
		return
	var ticket: int = await _set_off(int(signf(x - position.x)))
	if ticket != _walk_id:
		return
	var distance := absf(x - position.x) / absf(scale.x)
	var count := maxi(1, roundi(distance / step_length))
	var length := distance / count
	# A half step to set off, whole steps, and a half step to pull up with the feet together.
	await _step(length * 0.5, length * 0.5, 0.0, 1.0)
	for _step_number in count - 1:
		if ticket != _walk_id:
			return
		await _step(length, length * 0.5, 1.0, 1.0)
	if ticket != _walk_id:
		return
	await _step(length * 0.5, 0.0, 1.0, 0.0)
	position.x = x
	_walking = false


## Walks off the edge of the canvas toward [param direction] (-1 left, 1 right) and stops once all of
## it, words and all, is out of sight. It has to be alive. Emits [signal walked_off].
func walk_off(direction: int) -> void:
	if not _alive:
		return
	var way := signi(direction)
	if way == 0:
		way = facing if facing != 0 else 1
	var ticket: int = await _set_off(way)
	if ticket != _walk_id:
		return
	await _step(step_length * 0.5, step_length * 0.5, 0.0, 1.0)
	while not _out_of_sight(way):
		if ticket != _walk_id:
			return
		await _step(step_length, step_length * 0.5, 1.0, 1.0)
	_walking = false
	walked_off.emit()


## Gets it up and facing [param way], ready to walk, and hands back this walk's ticket.
func _set_off(way: int) -> int:
	_walk_id += 1
	var ticket := _walk_id
	_kill_motion()
	_walking = false
	await stand_up()
	await face_toward(way)
	_feet = _resting_feet(false)
	_lead = _front_foot()
	_walking = true
	return ticket


## One step: the body travels [param travel] pixels the way it faces while the trailing foot swings
## through and lands [param landing] pixels ahead of where it rests. On the way it goes from
## [param lean_from] to [param lean_to] of its full lean, so a walk sets off and pulls up smoothly.
func _step(travel: float, landing: float, lean_from: float, lean_to: float) -> void:
	var swing := _lead
	var lands := Vector2(_home(swing) + facing * (landing + travel), 0.0)
	_motion = create_tween()
	_motion.tween_method(_step_frame.bind(position.x, travel, swing, _feet[swing], lands, _feet[1 - swing], lean_from, lean_to),
			0.0, 1.0, maxf(travel / walk_speed, 0.001))
	await _motion.finished
	_lead = 1 - swing
	stepped.emit()


## Where everything is [param t] of the way through a step. Feet are in its own space as it stood when
## the step began, so the planted foot holds still on the ground while the body goes on over it.
func _step_frame(t: float, start: float, travel: float, swing: int, lifts: Vector2, lands: Vector2,
		planted: Vector2, lean_from: float, lean_to: float) -> void:
	var moved := Vector2(facing * travel * t, 0.0)
	position.x = start + moved.x * absf(scale.x)
	var foot := lifts.lerp(lands, smoothstep(0.0, 1.0, t)) - moved
	foot.y = -step_height * sin(PI * t)
	_feet[swing] = foot
	_feet[1 - swing] = planted - moved
	var arc := sin(PI * t)
	_step_bob = walk_bob * arc
	_step_tilt = facing * walk_lean * lerpf(lean_from, lean_to, t) + waddle * arc * signf(_home(1 - swing))
	_swing = arc if swing == 1 else -arc
	_apply_rig()


## Poses the body, the limbs and the face from the motion so far.
func _apply_rig() -> void:
	if not is_node_ready():
		return
	var idle := _idle()
	var bob := _step_bob if _walking else (idle_bob * sin(_page_time * TAU / idle_bob_period) if idle else 0.0)
	body.position = Vector2(0.0, -(_rise + _hop + bob))
	body.rotation = deg_to_rad(_step_tilt) if _walking else 0.0
	body.scale = _squeeze
	var feet := _feet if _walking else _resting_feet(idle)
	var to_limbs := (body.transform * limbs.transform).affine_inverse()
	limbs.left_foot = to_limbs * feet[0]
	limbs.right_foot = to_limbs * feet[1]
	limbs.growth = _growth
	limbs.facing = _turn
	limbs.base_size = body.base_size
	_drawn_arms.blend(_arms, _arms, 0.0)
	_drawn_arms.front_shoulder += arm_swing * _swing
	_drawn_arms.back_shoulder -= arm_swing * _swing
	_drawn_arms.front_elbow += _arms.shake * _shake_sign
	limbs.arms = _drawn_arms
	face.cap_middle = face.transform.affine_inverse() * body.cap_middle()
	face.cap_radius = body.cap_radius
	face.look = _turn
	face.eye_scale = _eye_scale
	face.eyes = _eyes()
	_place_words()


## Snaps it into being a plain button, or alive and standing, with no motion.
func _snap() -> void:
	if not is_node_ready():
		return
	_stop_all()
	_standing = _alive
	_growth = 1.0 if _alive else 0.0
	_tuck = 1.0 if _alive else 0.0
	_rise = _stand_height() if _alive else 0.0
	_hop = 0.0
	_eye_scale = 1.0
	_eyes_shut = false
	_squeeze = Vector2.ONE
	_turn = facing
	_arms.blend(_resting_arms(), _resting_arms(), 0.0)
	_apply_rig()


## Idle life moves on with the page's boil, the way a stick figure breathes.
func _on_boiled() -> void:
	_page_time = Ink.time
	_shake_sign = -_shake_sign
	if not _alive:
		return
	_tick_blink()
	_tick_taps()
	_apply_rig()


func _tick_blink() -> void:
	if _blink_left > 0:
		_blink_left -= 1
	elif _page_time >= _next_blink:
		_blink_left = blink_ticks
		_schedule_blink()


func _tick_taps() -> void:
	if _taps_left > 0:
		_taps_left -= 1
	elif foot_taps and _idle() and _page_time >= _next_tap:
		_taps_left = taps * 2
		_schedule_taps()


func _schedule_blink() -> void:
	_next_blink = _page_time + _rng.randf_range(blink_gap.x, blink_gap.y)


func _schedule_taps() -> void:
	_next_tap = _page_time + _rng.randf_range(tap_gap.x, tap_gap.y)


## Whether it is standing about, alive, with nowhere to go.
func _idle() -> bool:
	return _alive and _standing and not _walking


func _eyes() -> ButtonFace.Eyes:
	if not _alive:
		return ButtonFace.Eyes.HIDDEN
	if _eyes_shut or _blink_left > 0:
		return ButtonFace.Eyes.CLOSED
	return ButtonFace.Eyes.OPEN


## Where its feet are while it is not walking: as far tucked in under it as it has got up, and the
## front one lifted while it taps.
func _resting_feet(idle: bool) -> PackedVector2Array:
	var feet := PackedVector2Array()
	var tuck := clampf(_tuck, 0.0, 1.0)
	for foot in 2:
		var sitting := Vector2(sitting_foot.x * (1.0 if foot == 1 else -1.0), sitting_foot.y)
		feet.append(sitting.lerp(Vector2(_home(foot), 0.0), tuck))
	if idle and _taps_left > 0 and _taps_left % 2 == 0:
		var front := _front_foot()
		feet[front] = feet[front] + Vector2.UP * tap_height
	return feet


## Where the foot [param foot] rests on the ground, across from the middle: right under its hip.
func _home(foot: int) -> float:
	return limbs.hip_spread * (1.0 if foot == 1 else -1.0)


## The foot on the side it faces: the screen right one while it faces out of the page.
func _front_foot() -> int:
	return 0 if _turn < 0.0 else 1


func _stand_height() -> float:
	return limbs.leg_length * stand_share


func _resting_arms() -> ButtonArmPose:
	return rest_arms if rest_arms != null else ButtonArmPose.new()


func _blend_arms(weight: float, from: ButtonArmPose, to: ButtonArmPose) -> void:
	_arms.blend(from, to, weight)
	_apply_rig()


## Keeps its words just over its cap: higher once it stands, but not bobbing with every step.
func _place_words() -> void:
	if _words == null:
		return
	var at := words_spot
	if not at.is_finite():
		at = Vector2(0.0, -_rise + body.cap_middle().y - body.cap_radius - words_gap)
	if at.is_equal_approx(_words_at):
		return
	_words_at = at
	_words.place(at)


## Fades [param words] away and lets them go.
func _let_go(words: Plea) -> void:
	await words.fade_out()
	words.queue_free()


## Whether all of it, words and all, is past the edge of the canvas toward [param way].
func _out_of_sight(way: int) -> bool:
	var canvas := get_viewport_rect()
	var to_canvas := get_global_transform_with_canvas()
	var half := limbs.reach() * absf(to_canvas.get_scale().x)
	if _words != null:
		var words_scale := absf(_words.get_global_transform_with_canvas().get_scale().x)
		half = maxf(half, _words.label.get_content_width() * 0.5 * words_scale)
	half += exit_margin
	var middle := to_canvas.origin.x
	return middle + half < canvas.position.x if way < 0 else middle - half > canvas.end.x


func _kill_motion() -> void:
	if _motion != null and _motion.is_valid():
		_motion.kill()
	_motion = null


## Stops everything under way and lets go of any walk.
func _stop_all() -> void:
	_kill_motion()
	for tween: Tween in [_arms_tween, _turn_tween, _eyes_tween]:
		if tween != null and tween.is_valid():
			tween.kill()
	_walk_id += 1
	_walking = false
	_step_bob = 0.0
	_step_tilt = 0.0
	_swing = 0.0
