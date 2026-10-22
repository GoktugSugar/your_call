class_name GunStage
extends Stage
## The gun chapter, first person: one to five targets stand before the player, an ink sight follows the
## pointer, and amber brackets lock on to whatever it is over; a click fires at it. The choice row offers
## the same shots in words, and lowering the gun. There is no gun on screen: a shot is the page flashing,
## the view jolting and the sight kicking, and the one hit folds; lowering the gun drops the sight away.
## Stage data:
## [codeblock]
## {"type": "gun", "imp": true, "survivors": "leave",
##  "targets": [{"id": "man", "kind": "stranger", "x": 640}, {"id": "bear", "kind": "bear", "x": 1180}]}
## [/codeblock]
## Each target names a soul [code]kind[/code] (or a [code]doodle[/code] for a thing that is not a soul),
## stands at [code]x[/code] on the ground, and can plead ([code]says[/code]), be drawn in a palette
## [code]role[/code], and carry a share of the crowd and a [code]label[/code] for a reveal by target.
## An option's outcome [code]{"shoot": id}[/code] fires at that target, [code]"any"[/code] at whichever
## the player aims at (picked in the row, at one at random, blind), [code]"imp"[/code] at the imp, and
## [code]"self"[/code] at the player, the whole view framed; [code]{"hold": true}[/code] lowers the gun.
## A hidden option is how the imp is shot: only on the stage, never in the row.
## Variants, each in the stage data:
## [code]"imp": true[/code] lets the imp be aimed at. [code]"survivors": "leave"[/code] sends the
## standing targets not shot walking off. [code]"empty": true[/code]: the gun is not loaded, and fires a
## dry click. [code]"dies_anyway": true[/code]: lowered, the target dies by itself after a while.
## [code]"fires_back": 50[/code]: lowered, the target, armed, fires back that share of the time.
## [code]"alone": {"seconds": 8}[/code]: nothing is asked and there is no choice row; the gun lowers by
## itself when time runs out. [code]"charge": {"seconds": 6}[/code]: the doodle target charges at the
## player while they choose, arriving when time runs out (which holds), and turns out to be the walking
## button, shot or not.
## Outcomes: the id of the target shot, or [code]imp[/code] or [code]self[/code]; [code]click[/code] for
## an empty gun; [code]held[/code] for lowering it, or [code]fired[/code] and [code]lowered[/code] for an
## armed target's answer. A charging thing reports [code]shot[/code], [code]shot_again[/code] (when the
## button woke in 2.11, so this is not the first time it is hurt) or [code]waved[/code].

## Emitted the moment the gun goes off, for a gunshot to come.
signal fired
## Emitted with the option picked on a stage that takes the choice by itself.
signal chosen_alone(index: int)

## The aim at the imp himself.
const AIM_IMP := "imp"
## The aim at the player, the whole view.
const AIM_SELF := "self"
## Picks whichever target is aimed at.
const AIM_ANY := "any"

## Where the targets are added.
@export var targets_root: Node2D
## The sight that follows the pointer.
@export var sight: Crosshair
## The amber brackets that lock on.
@export var lock: LockBrackets
## Flashes the page when the gun goes off.
@export var flash: ColorRect
## The flash at an armed target's muzzle.
@export var muzzle: MuzzleFlash
## The words floating over a target that pleads.
@export var plea_scene: PackedScene
## The walking button, which a charging thing turns out to be.
@export var walker_scene: PackedScene

@export_group("Layout")
## Where the targets stand, down the page.
@export_range(0.0, 1080.0, 1.0) var ground_y := 700.0
## How much bigger the souls stand here than on the tracks: the gun brings them close.
@export_range(0.2, 4.0, 0.01) var soul_scale := 1.7
## Extra room round a target's drawing that still counts as aiming at it.
@export_range(0.0, 80.0, 0.5) var aim_padding := 8.0
## What the brackets frame when the gun is turned on the player: the view.
@export var self_frame := Rect2(70.0, 50.0, 1780.0, 980.0)
## Gap between the top of a target that is not a stick figure and the words over it.
@export_range(0.0, 200.0, 1.0) var plea_gap := 20.0

@export_group("Shot")
## How bright the page flashes when the gun goes off, from 0 to 1.
@export_range(0.0, 1.0, 0.01) var flash_alpha := 0.55
## Seconds the flash takes to fade.
@export_range(0.01, 1.0, 0.01) var flash_time := 0.18
## How far the sight kicks up with the shot.
@export_range(0.0, 200.0, 0.5) var kick := 36.0
## Seconds the kick takes to settle.
@export_range(0.01, 2.0, 0.01) var kick_time := 0.35
## How far the view jolts with the shot.
@export_range(0.0, 60.0, 0.5) var jolt := 10.0
## Seconds the jolt takes.
@export_range(0.01, 2.0, 0.01) var jolt_time := 0.24
## How far the sight twitches on a dry click.
@export_range(0.0, 60.0, 0.5) var dry_twitch := 8.0
## Seconds the sight takes to move onto a target picked in the row.
@export_range(0.01, 2.0, 0.01) var aim_time := 0.35
## Seconds between the sight arriving on a target and the shot.
@export_range(0.0, 2.0, 0.01) var aim_hold := 0.25
## How far the sight drops as the gun is lowered.
@export_range(0.0, 1200.0, 1.0) var lower_drop := 520.0
## Seconds it takes to lower the gun.
@export_range(0.01, 3.0, 0.01) var lower_time := 0.7
## Seconds the stage holds once the consequence has played.
@export_range(0.0, 5.0, 0.01) var settle := 0.9
## How fast the targets left standing walk off, in pixels a second.
@export_range(10.0, 2000.0, 1.0) var walk_off_speed := 240.0
## How far past the edge of the page they walk.
@export_range(0.0, 400.0, 1.0) var walk_off_margin := 160.0
## Seconds a target that dies anyway takes to go, once the gun is lowered.
@export_range(0.0, 10.0, 0.05) var slow_death := 2.2
## Seed for picking a target blind and for whether an armed one fires back. Zero picks a new one every play.
@export var aim_seed := 0

@export_group("Charging")
## Where the charging thing starts, far off, and where it arrives, close: its base on the page.
@export var charge_from := Vector2(960.0, 480.0)
@export var charge_to := Vector2(960.0, 860.0)
## Its size far off and close, as a multiple of its natural size.
@export var charge_size := Vector2(0.16, 2.6)
## How hard it speeds up as it comes: 1 is steady.
@export_range(1.0, 6.0, 0.05) var charge_ease := 2.4
## Seconds it takes to cover the rest of the way once it is shot or left to come.
@export_range(0.05, 5.0, 0.05) var arrive_time := 0.7
## The walking button's size against the thing's, once it turns out to be the button.
@export_range(0.1, 3.0, 0.01) var button_size := 0.8
## How it holds its arms, hurt, and saying hello.
@export var hurt_arms: ButtonArmPose
@export var hello_arms: ButtonArmPose
## Seconds the thing takes to turn into the button.
@export_range(0.01, 2.0, 0.01) var reveal_time := 0.35

@export_group("Armed")
## How an armed target holds its gun once it lowers it.
@export var lowered_pose: FigurePose
## Seconds an armed target waits before it answers a lowered gun.
@export_range(0.0, 5.0, 0.05) var answer_after := 1.1

## The targets, by id, in order.
var _targets: Array[Node2D] = []
var _ids := PackedStringArray()
## Each target's kind, for the kill tally.
var _kinds := PackedStringArray()
## Each target's drawing, round its own origin.
var _bounds: Array[Rect2] = []
## The words over each target that pleads, by target index.
var _pleas := {}
## The option that fires at each aim, by aim id; the option that fires at whatever is aimed at; the one that holds.
var _option_at := {}
var _any := -1
var _hold := -1
## What the sight is on, by aim id, or empty.
var _aimed := ""
## What the player clicked on the stage to fire at, by aim id, or empty for a shot picked in the row.
var _clicked := ""
## Where the pointer is, in this stage's space, from the last mouse event; off the page until there is one.
var _pointer := Vector2(-100000.0, -100000.0)
## The target the gun fired at, for the reveal.
var _last_shot := ""
## What the row lights, by aim id, or empty.
var _highlighted := ""
var _live := false
var _choosing_alone := false
var _imp_bounds := Rect2()
var _rng := RandomNumberGenerator.new()
## The charging thing, its share of the way in, and the walking button it turns out to be.
var _thing: Node2D
var _charge := 0.0
var _charging := false
var _walker: WalkingButton
var _sight_home := Vector2.ZERO


func setup(for_question: QuestionData) -> void:
	super.setup(for_question)
	var data := for_question.stage
	if aim_seed != 0:
		_rng.seed = aim_seed
	else:
		_rng.randomize()
	var said := for_question.stage_lines
	var next_said := 0
	for raw: Variant in data.get("targets", []):
		if not raw is Dictionary:
			continue
		var entry: Dictionary = raw
		var target := _make_target(entry)
		if target == null:
			continue
		target.position = Vector2(float(entry.get("x", 960.0)), float(entry.get("y", ground_y)))
		targets_root.add_child(target)
		_targets.append(target)
		_ids.append(str(entry.get("id", "")))
		_kinds.append(str(entry.get("kind", entry.get("doodle", ""))))
		_bounds.append(_drawn_bounds(target))
		if entry.has("says") and next_said < said.size():
			_pleas[_targets.size() - 1] = _add_plea(target, said[next_said].text)
			next_said += 1
		if entry.has("doodle") and data.has("charge"):
			_thing = target
	for i in for_question.options.size():
		var outcome := for_question.options[i].outcome
		if bool(outcome.get("hold", false)):
			_hold = i
		var shoot := str(outcome.get("shoot", ""))
		if shoot == AIM_ANY:
			_any = i
		elif shoot != "":
			_option_at[shoot] = i
	if bool(data.get("imp", false)) and imp != null:
		_imp_bounds = _drawn_bounds(imp.drawing)
	_choosing_alone = data.has("alone")
	sight.visible = false
	_sight_home = sight.position
	flash.modulate.a = 0.0
	if _thing != null:
		_place_thing(0.0)


func enter() -> void:
	await super.enter()
	for plea: Plea in _pleas.values():
		plea.write_on()


func chooses_alone() -> bool:
	return _choosing_alone


## On a stage that takes the choice by itself, waits for a shot, or for the time to run out, which lowers
## the gun.
func choose() -> int:
	var seconds := float((question.stage.get("alone", {}) as Dictionary).get("seconds", 8.0))
	get_tree().create_timer(seconds, false).timeout.connect(func() -> void:
		if _live:
			chosen_alone.emit.call_deferred(_hold))
	return await chosen_alone


func set_choosing(active: bool) -> void:
	_live = active
	if active:
		sight.visible = not _aims_at_self()
		sight.modulate.a = 1.0
		if _thing != null and not _charging and _charge < 1.0:
			_charging = true
	else:
		_charging = false
		if _aimed != "":
			_aimed = ""
			option_hovered.emit(-1)
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func highlight_option(index: int) -> void:
	_highlighted = ""
	for id: String in _option_at:
		if _option_at[id] == index:
			_highlighted = id


func play_consequence(index: int) -> StringName:
	var outcome := question.options[index].outcome
	set_choosing(false)
	lock.release()
	for plea: Plea in _pleas.values():
		plea.fade_out()
	if bool(outcome.get("hold", false)):
		return await _lower()
	var id := str(outcome.get("shoot", ""))
	if id == AIM_ANY:
		# Clicked on the stage, at the one clicked; picked in the row, blind, at any of them.
		id = _clicked if _ids.has(_clicked) else _ids[_rng.randi_range(0, _ids.size() - 1)]
	await _aim_at(id)
	if bool(question.stage.get("empty", false)):
		await _dry_fire()
		await _settle()
		return &"click"
	await _fire()
	if id == AIM_IMP:
		if imp != null:
			await imp.round_on_camera()
		return &"imp"
	if id == AIM_SELF:
		await _settle()
		return &"self"
	var target := _ids.find(id)
	if target < 0:
		await _settle()
		return StringName(id)
	if _targets[target] == _thing:
		return await _thing_shot()
	await _down(target)
	return StringName(id)


func reveal_split(pick: int) -> RevealSplit:
	var split := super.reveal_split(pick)
	if _any < 0:
		return split
	# A reveal by target: a bar per target in its colour, then the one for holding.
	var entries: Array = question.stage.get("targets", [])
	var by_target := RevealSplit.new()
	by_target.heading = split.heading
	for i in entries.size():
		var entry: Dictionary = entries[i]
		by_target.labels.append(str(entry.get("label", entry.get("id", ""))))
		by_target.shares.append(float(entry.get("crowd", 0.0)))
		by_target.roles.append(StringName(str(entry.get("role", ""))))
	if _hold >= 0:
		by_target.labels.append(question.bar_labels()[_hold])
		by_target.shares.append(question.options[_hold].crowd)
		by_target.roles.append(&"")
	by_target.pick = _ids.find(_last_shot) if pick == _any else entries.size()
	return by_target


func leave() -> void:
	var fade := create_tween().set_parallel(true)
	fade.tween_property(sight, ^"modulate:a", 0.0, leave_duration)
	lock.release()
	for plea: Plea in _pleas.values():
		plea.fade_out()
	if _walker != null:
		_walker.fade_words()
	await fade.finished
	await super.leave()


func option_point(index: int) -> Vector2:
	if index < 0:
		return Vector2.INF
	for id: String in _option_at:
		if _option_at[id] == index:
			var rect := _aim_rect(id)
			return get_global_transform_with_canvas() * rect.get_center() if rect.has_area() else Vector2.INF
	if index == _any and not _ids.is_empty():
		return get_global_transform_with_canvas() * _aim_rect(_ids[0]).get_center()
	return Vector2.INF


func _process(delta: float) -> void:
	if _charging and _thing != null:
		var seconds := float((question.stage.get("charge", {}) as Dictionary).get("seconds", 6.0))
		_charge = minf(_charge + delta / maxf(seconds, 0.01), 1.0)
		_place_thing(_charge)
		if _charge >= 1.0:
			_charging = false
			_commit(_hold)
	if not _live:
		return
	if _pointer.x > -10000.0:
		sight.position = _pointer
	_update_aim()
	var shown := _aimed if _aimed != "" else _highlighted
	if shown != "":
		lock.lock_onto(_aim_rect(shown))
	else:
		lock.release()


func _unhandled_input(event: InputEvent) -> void:
	if not _live or not event is InputEventMouse:
		return
	_pointer = (make_input_local(event) as InputEventMouse).position
	_update_aim()
	if _aimed == "" or not event.is_action_pressed(&"pick"):
		return
	var index := _option_for(_aimed)
	if index < 0:
		return
	get_viewport().set_input_as_handled()
	_clicked = _aimed
	_commit(index)


## Finds what is under the pointer, and tells the row when that changes.
func _update_aim() -> void:
	var over := _aim_under(_pointer)
	if over == _aimed:
		return
	_aimed = over
	Input.set_default_cursor_shape(Input.CURSOR_CROSS if over != "" else Input.CURSOR_ARROW)
	option_hovered.emit(_option_for(over))


func _commit(index: int) -> void:
	if index < 0:
		return
	if _choosing_alone:
		chosen_alone.emit(index)
	else:
		option_committed.emit(index)


## The option that fires at [param id], or -1.
func _option_for(id: String) -> int:
	if id == "":
		return -1
	if _option_at.has(id):
		return _option_at[id]
	return _any if _ids.has(id) else -1


## What is under [param pointer], by aim id: a target first, then the imp, then the view itself when
## the gun is turned on the player.
func _aim_under(pointer: Vector2) -> String:
	for i in range(_targets.size() - 1, -1, -1):
		if _option_for(_ids[i]) >= 0 and _aim_rect(_ids[i]).has_point(pointer):
			return _ids[i]
	if _option_at.has(AIM_IMP) and _aim_rect(AIM_IMP).has_point(pointer):
		return AIM_IMP
	if _aims_at_self():
		return AIM_SELF
	return ""


func _aims_at_self() -> bool:
	return _option_at.has(AIM_SELF)


## Where [param id] is on the page, in this stage's space, padded a little.
func _aim_rect(id: String) -> Rect2:
	if id == AIM_SELF:
		return self_frame
	if id == AIM_IMP:
		return _transformed(_imp_bounds, imp.drawing) if imp != null and _imp_bounds.has_area() else Rect2()
	var i := _ids.find(id)
	if i < 0:
		return Rect2()
	return _transformed(_bounds[i], _targets[i])


## [param bounds], in [param node]'s space, as a rect in this stage's space, padded for aiming.
func _transformed(bounds: Rect2, node: Node2D) -> Rect2:
	var to_stage := get_global_transform().affine_inverse() * node.get_global_transform()
	var rect := Rect2(to_stage * bounds.position, Vector2.ZERO)
	for corner: Vector2 in [Vector2(bounds.end.x, bounds.position.y), bounds.end, Vector2(bounds.position.x, bounds.end.y)]:
		rect = rect.expand(to_stage * corner)
	return rect.grow(aim_padding)


## The box round everything [param node] draws, in its own space: its own lines and its drawings'.
func _drawn_bounds(node: Node2D) -> Rect2:
	var box := Rect2()
	var found := false
	var pending: Array[Node] = [node]
	while not pending.is_empty():
		var each: Node = pending.pop_back()
		pending.append_array(each.get_children())
		if not each is InkDrawing:
			continue
		var drawing := each as InkDrawing
		var to_node := node.get_global_transform().affine_inverse() * drawing.get_global_transform() if drawing != node else Transform2D.IDENTITY
		for line in drawing._build_lines(InkStyle.get_default(), InkPalette.get_default()):
			for point in line.path:
				var at := to_node * point
				if not found:
					box = Rect2(at, Vector2.ZERO)
					found = true
				else:
					box = box.expand(at)
	return box


## A target from its stage data: a soul of its kind, or a doodle.
func _make_target(entry: Dictionary) -> Node2D:
	var target: Node2D = null
	if entry.has("doodle"):
		target = DoodlesStage.make_doodle(str(entry["doodle"]))
	elif SoulKind.exists(StringName(str(entry.get("kind", "")))):
		target = SoulKind.find(StringName(str(entry["kind"]))).make()
		target.scale *= soul_scale
		if entry.has("role"):
			(target as Soul).color_override = StringName(str(entry["role"]))
	if target == null:
		push_warning("Gun stage: no target can be made from %s in %s." % [entry, question.id])
	return target


func _add_plea(target: Node2D, words: String) -> Plea:
	var plea := plea_scene.instantiate() as Plea
	targets_root.add_child(plea)
	plea.set_words(words)
	var over := Vector2.ZERO
	if target.has_method(&"head_top"):
		over = target.call(&"head_top")
	else:
		over = Vector2(0.0, _drawn_bounds(target).position.y - plea_gap)
	plea.place(targets_root.to_local(target.to_global(over)))
	return plea


## Moves the sight onto [param id] if it is not on it already, and locks on.
func _aim_at(id: String) -> void:
	var rect := _aim_rect(id)
	if not rect.has_area():
		return
	sight.visible = id != AIM_SELF
	sight.modulate.a = 1.0
	lock.lock_onto(rect)
	if id != AIM_SELF and sight.position.distance_to(rect.get_center()) > rect.size.length() * 0.25:
		var move := create_tween()
		move.tween_property(sight, ^"position", rect.get_center(), aim_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await move.finished
	if id != AIM_SELF and id != AIM_IMP:
		_last_shot = id
	await get_tree().create_timer(aim_hold, false).timeout


## The gun goes off: the page flashes, the view jolts and the sight kicks.
func _fire() -> void:
	fired.emit()
	flash.modulate.a = flash_alpha
	var tween := create_tween().set_parallel(true)
	tween.tween_property(flash, ^"modulate:a", 0.0, flash_time)
	var home := position
	var shake := create_tween()
	for i in 3:
		shake.tween_property(self, ^"position", home + Vector2(_rng.randf_range(-jolt, jolt), _rng.randf_range(-jolt, jolt)), jolt_time / 4.0)
	shake.tween_property(self, ^"position", home, jolt_time / 4.0)
	var aim := sight.position
	var recoil := create_tween()
	recoil.tween_property(sight, ^"position", aim + Vector2.UP * kick, kick_time * 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	recoil.tween_property(sight, ^"position", aim, kick_time * 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await shake.finished


## The gun is empty: the trigger clicks, the sight twitches, and nothing else happens.
func _dry_fire() -> void:
	var aim := sight.position
	var twitch := create_tween()
	twitch.tween_property(sight, ^"position", aim + Vector2.DOWN * dry_twitch, 0.05)
	twitch.tween_property(sight, ^"position", aim, 0.12)
	await twitch.finished


## The target at [param index] is hit: it folds, the run counts it, and the others left standing walk
## off when the stage says they do.
func _down(index: int) -> void:
	var soul := _targets[index] as Soul
	if soul != null:
		run.kills.add(StringName(_kinds[index]))
		soul.fold(1.0 if _targets[index].position.x >= 960.0 else -1.0)
	if str(question.stage.get("survivors", "")) == "leave":
		for i in _targets.size():
			if i != index:
				_walk_off(_targets[i])
	await _settle()


func _walk_off(target: Node2D) -> void:
	var figure := target as StickFigure
	if figure == null:
		return
	var way := -1.0 if figure.position.x < 960.0 else 1.0
	var edge := -walk_off_margin if way < 0.0 else get_viewport_rect().size.x + walk_off_margin
	figure.walk_to(edge, walk_off_speed)


## The gun is lowered: the sight drops away, and then whatever lowering it leads to.
func _lower() -> StringName:
	var drop := create_tween().set_parallel(true)
	drop.tween_property(sight, ^"position", sight.position + Vector2.DOWN * lower_drop, lower_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	drop.tween_property(sight, ^"modulate:a", 0.0, lower_time)
	await drop.finished
	var data := question.stage
	if _thing != null:
		return await _thing_arrives()
	if data.has("fires_back") and not _targets.is_empty():
		return await _answer(float(data["fires_back"]))
	if bool(data.get("dies_anyway", false)) and not _targets.is_empty() and _targets[0] is Soul:
		await get_tree().create_timer(slow_death, false).timeout
		await (_targets[0] as Soul).fold(1.0)
	await _settle()
	return &"held"


## An armed target answers a lowered gun: it fires anyway [param share] percent of the time, its muzzle
## flashing and the shot going straight through the player, or lowers its own.
func _answer(share: float) -> StringName:
	await get_tree().create_timer(answer_after, false).timeout
	var figure := _targets[0] as StickFigure
	if _rng.randf() * 100.0 < share:
		if figure != null and figure.has_method(&"muzzle_point"):
			muzzle.global_position = figure.to_global(figure.call(&"muzzle_point"))
			muzzle.burst()
		await _fire()
		await _settle()
		return &"fired"
	if figure != null and lowered_pose != null:
		await figure.blend_to(lowered_pose, lower_time).finished
	await _settle()
	return &"lowered"


## The charging thing, [param share] of the way in: further down the page and bigger as it comes,
## faster and faster.
func _place_thing(share: float) -> void:
	var t := pow(share, charge_ease)
	_thing.position = charge_from.lerp(charge_to, t)
	var size := lerpf(charge_size.x, charge_size.y, t)
	if &"mark_scale" in _thing:
		_thing.set(&"mark_scale", size)
		_bounds[_targets.find(_thing)] = _drawn_bounds(_thing)
	else:
		_thing.scale = Vector2.ONE * size


## Shot, the charging thing keeps coming all the same, and turns out to be the walking button, unhurt
## and offended.
func _thing_shot() -> StringName:
	var again := run.remembers(RunState.BUTTON_WOKE)
	run.remember(RunState.BUTTON_SHOT)
	await _finish_charge()
	await _turn_into_button(&"hurt_again" if again else &"hurt", hurt_arms)
	return &"shot_again" if again else &"shot"


## Left to come, the charging thing arrives and turns out to be the walking button, saying hello.
func _thing_arrives() -> StringName:
	await _finish_charge()
	run.remember(RunState.BUTTON_SPARED)
	await _turn_into_button(&"hello", hello_arms)
	return &"waved"


## The charging thing covers the rest of the way in [member arrive_time], whatever happened to it.
func _finish_charge() -> void:
	_charging = false
	if _charge >= 1.0:
		return
	var rest := create_tween()
	rest.tween_method(_set_charge, _charge, 1.0, arrive_time)
	await rest.finished


func _set_charge(share: float) -> void:
	_charge = share
	_place_thing(share)


## The charging thing dissolves into the walking button where it is, which says the question's line set
## [param said] and holds its arms in [param arms].
func _turn_into_button(said: StringName, arms: ButtonArmPose) -> void:
	_charging = false
	if walker_scene == null:
		await _settle()
		return
	_walker = walker_scene.instantiate() as WalkingButton
	_walker.position = _thing.position
	var size: float = _thing.get(&"mark_scale") if &"mark_scale" in _thing else _thing.scale.x
	_walker.scale = Vector2.ONE * size * button_size
	targets_root.add_child(_walker)
	_walker.alive = true
	_walker.modulate.a = 0.0
	var swap := create_tween().set_parallel(true)
	swap.tween_property(_thing, ^"dissolve", 1.0, reveal_time)
	swap.tween_property(_walker, ^"modulate:a", 1.0, reveal_time)
	await swap.finished
	if arms != null:
		_walker.hold_arms(arms)
	var lines := question.lines_in(said)
	if not lines.is_empty():
		await _walker.say(lines[0].text, VoiceLibrary.clip_for(lines[0]))
		await _walker.finish_saying()
	await _settle()


func _settle() -> void:
	if settle > 0.0:
		await get_tree().create_timer(settle, false).timeout
