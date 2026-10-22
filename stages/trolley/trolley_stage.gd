class_name TrolleyStage
extends Stage
## The trolley problem, staged: a trolley waiting on the approach, tracks that split past it, and
## souls on each track. Stage data:
## [code]{"type": "trolley", "rolling": false, "tracks": [{"figures": ["stranger", ...]}, ...]}[/code].
## A figure is the name of a [SoulKind], or [code]{"kind": "stranger", "says": "Please."}[/code] for a
## soul pleading out loud. A track can be [code]"roped"[/code] (its souls tied together),
## [code]"facing": "away"[/code] (its souls turned from the player) or [code]"dark"[/code] (lost in a
## dark that lifts once the trolley has rolled). A rolling trolley creeps toward the split while the
## player decides.
## Two tracks make a fork: if nobody pulls, the trolley takes track 0, straight on, and the lever
## stands for the first option that leaves it. More tracks make a fan the player points into.
## An option's outcome [code]{"track": n}[/code] sends the trolley down track n.

## The track the trolley waits on, which ends at the split.
@export var approach: Track
## The ways the line can split past the approach. The stage shows the one with as many routes as tracks.
@export var layouts: Array[TrackLayout] = []
@export var trolley: TrolleyCart
@export var lever: Lever
## Where the souls, their ropes and their pleas are added.
@export var figure_layer: Node2D
## The words floating over a soul that pleads.
@export var plea_scene: PackedScene
## The pose of a soul pleading out loud.
@export var plead_pose: FigurePose

@export_group("Figures")
## Canvas x of the middle of each track's group of figures.
@export var figures_center_x := 1320.0
## Distance between neighbouring figures on a track.
@export_range(20.0, 300.0, 1.0) var figure_spacing := 68.0
## The kind drawn in place of a kind that does not exist.
@export var fallback_kind := &"stranger"

@export_group("Trolley")
## How far along the approach the trolley waits.
@export_range(0.0, 1000.0, 1.0) var trolley_start := 110.0
## Distance from the trolley's origin to its front.
@export_range(0.0, 300.0, 1.0) var trolley_front := 84.0
## How far ahead of the trolley's front a soul starts to fold, so the fall meets the hit.
@export_range(0.0, 200.0, 1.0) var hit_lead := 28.0
## Seconds from setting off until its front reaches the end of the line. It speeds up all the way.
@export_range(0.2, 10.0, 0.05) var roll_duration := 2.6
## Seconds it keeps rolling past the end of the line while it dissolves away.
@export_range(0.0, 3.0, 0.05) var exit_duration := 0.45
## Seconds between the lever landing and the trolley setting off.
@export_range(0.0, 2.0, 0.01) var lever_pause := 0.2
## Seconds a rolling trolley takes to creep up to the split while the player decides. It slows as it nears.
@export_range(1.0, 300.0, 0.5) var creep_duration := 40.0
## How far short of the split a creeping trolley's front comes to a stop.
@export_range(0.0, 400.0, 1.0) var creep_stop := 30.0

@export_group("Pointing")
## How close the pointer must come to a route of a fan to pick it, in pixels.
@export_range(4.0, 200.0, 1.0) var pick_radius := 40.0
## Palette role of a route that is pointed at or picked.
@export var picked_role := &"amber"
## Width of a route that is pointed at or picked, as a multiple of its resting width.
@export_range(1.0, 3.0, 0.05) var picked_width := 1.4

@export_group("Dark")
## Canvas x where the dark over a track begins. It runs on past the end of the track.
@export var dark_start_x := 1060.0
## How far the dark reaches above and below the track.
@export var dark_reach := Vector2(150.0, 70.0)
## How far past the end of the track the dark runs. Kept short, so the dark stays clear of the imp's wing.
@export_range(0.0, 800.0, 1.0) var dark_overrun := 0.0
## How far short of the end of a dark track the trolley's front stops, unseen in the dark, instead of
## running on out of the far side.
@export_range(0.0, 400.0, 1.0) var dark_stop_short := 90.0
## Seconds between the trolley rolling and the dark lifting.
@export_range(0.0, 5.0, 0.01) var dark_pause := 0.5

const _TRACK_KEY := "track"

var _layout: TrackLayout
var _routes: Array[Track] = []
## The souls on each route, nearest the split first.
var _figures: Array[Array] = []
## The rope tying each roped route's souls, by route index.
var _ropes := {}
## The words over each soul that pleads, by soul.
var _pleas := {}
var _darkness: Darkness
var _dark_route := -1
var _lever_option := -1
var _rolling := false
var _creep: Tween
## How far along the line the trolley is.
var _trolley_at := 0.0
## Whether the player can point at a route, and the route lit amber.
var _pointing := false
var _lit_route := -1
## The roll under way: its route, the souls on it, how far along the route each is hit, and the next to hit.
var _route: Track
var _route_index := 0
var _victims: Array = []
var _hit_at := PackedFloat32Array()
var _next_hit := 0


func setup(for_question: QuestionData) -> void:
	super.setup(for_question)
	var tracks: Array = for_question.stage.get("tracks", [])
	_layout = _pick_layout(tracks.size())
	_routes = _layout.routes
	for i in _routes.size():
		_routes[i].visible = i < tracks.size()
	_figures.clear()
	for i in mini(tracks.size(), _routes.size()):
		var track_data: Dictionary = tracks[i]
		var souls := _place_souls(_routes[i], track_data)
		_figures.append(souls)
		if bool(track_data.get("roped", false)) and souls.size() > 1:
			_ropes[i] = _tie(souls)
		if bool(track_data.get("dark", false)):
			_darkness = _darken(_routes[i])
			_dark_route = i
	_rolling = bool(for_question.stage.get("rolling", false))
	_lever_option = -1
	if _layout.has_lever:
		for i in for_question.options.size():
			if _option_route(i) != 0:
				_lever_option = i
				break
	lever.visible = _lever_option >= 0
	lever.hover_changed.connect(_on_lever_hover_changed)
	lever.pulled.connect(_on_lever_pulled)
	_place_trolley(trolley_start, _routes[0])


func enter() -> void:
	await super.enter()
	for plea: Plea in _pleas.values():
		plea.write_on()
	if _rolling:
		_creep = create_tween()
		_creep.tween_method(_place_on_approach, _trolley_at, approach.length() - trolley_front - creep_stop, creep_duration) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func set_choosing(active: bool) -> void:
	lever.live = active and _lever_option >= 0
	_pointing = active and not _layout.has_lever
	if not _pointing:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func highlight_option(index: int) -> void:
	if _layout.has_lever:
		lever.highlighted = index >= 0 and index == _lever_option
	else:
		_light_route(_option_route(index) if index >= 0 else -1)


func play_consequence(index: int) -> void:
	set_choosing(false)
	lever.highlighted = false
	var route := _option_route(index)
	if not _layout.has_lever:
		_light_route(route)
	elif route != 0:
		await lever.throw()
		await get_tree().create_timer(lever_pause, false).timeout
	await _roll(route)
	if _darkness != null:
		await get_tree().create_timer(dark_pause, false).timeout
		await _darkness.lift()


func leave() -> void:
	if _creep != null:
		_creep.kill()
	for plea: Plea in _pleas.values():
		plea.fade_out()
	await super.leave()


func _unhandled_input(event: InputEvent) -> void:
	if not _pointing or not event is InputEventMouse:
		return
	var route := _route_under(event as InputEventMouse)
	if event is InputEventMouseMotion:
		if route != _lit_route:
			_light_route(route)
			Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if route >= 0 else Input.CURSOR_ARROW)
			option_hovered.emit(_route_option(route))
	elif route >= 0 and event.is_action_pressed(&"pick"):
		get_viewport().set_input_as_handled()
		option_committed.emit(_route_option(route))


func _roll(route_index: int) -> void:
	if _creep != null:
		_creep.kill()
	_route_index = route_index
	_route = _routes[route_index]
	_victims = _figures[route_index]
	_hit_at.clear()
	for soul: Soul in _victims:
		_hit_at.append(_route.distance_at_x(_route.to_local(soul.global_position).x))
	_next_hit = 0
	var start := _trolley_at
	var into_dark := route_index == _dark_route
	var to_end := approach.length() + _route.length() - trolley_front - (dark_stop_short if into_dark else 0.0)
	var exit_speed := 0.0 if into_dark else 2.0 * (to_end - start) / roll_duration
	var roll := create_tween()
	roll.tween_method(_roll_step, start, to_end, roll_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	roll.tween_method(_roll_step, to_end, to_end + exit_speed * exit_duration, exit_duration)
	roll.parallel().tween_property(trolley, ^"dissolve", 1.0, exit_duration)
	await roll.finished
	for soul: Soul in _victims:
		if soul.dissolve < 1.0:
			await soul.folded


func _roll_step(distance: float) -> void:
	_place_trolley(distance, _route)
	var front_on_route := distance + trolley_front + hit_lead - approach.length()
	while _next_hit < _victims.size() and front_on_route >= _hit_at[_next_hit]:
		var soul := _victims[_next_hit] as Soul
		soul.fold(1.0)
		if _pleas.has(soul):
			(_pleas[soul] as Plea).fade_out()
		if _ropes.has(_route_index):
			(_ropes[_route_index] as Rope).dissolve_away(soul.fold_fade)
			_ropes.erase(_route_index)
		_next_hit += 1


func _place_on_approach(distance: float) -> void:
	_place_trolley(distance, _routes[0])


func _place_trolley(distance: float, route: Track) -> void:
	_trolley_at = distance
	var on_approach := distance <= approach.length()
	var track := approach if on_approach else route
	var along := distance if on_approach else distance - approach.length()
	trolley.position = to_local(track.to_global(track.point_at(along)))
	trolley.rotation = track.direction_at(along).angle()


## Shows the layout with [param count] routes, or the nearest one with room for them, and hides the rest.
func _pick_layout(count: int) -> TrackLayout:
	var picked: TrackLayout = null
	for layout in layouts:
		var fits := layout.routes.size() >= count
		var picked_fits := picked != null and picked.routes.size() >= count
		if picked == null or (fits and (not picked_fits or layout.routes.size() < picked.routes.size())) \
				or (not fits and not picked_fits and layout.routes.size() > picked.routes.size()):
			picked = layout
	for layout in layouts:
		layout.visible = layout == picked
	return picked


func _place_souls(route: Track, track_data: Dictionary) -> Array[Soul]:
	var placed: Array[Soul] = []
	var entries: Array = track_data.get("figures", [])
	var turned_away := str(track_data.get("facing", "")) == "away"
	var first_x := figures_center_x - figure_spacing * (entries.size() - 1) * 0.5
	for i in entries.size():
		var entry: Variant = entries[i]
		var says := str((entry as Dictionary).get("says", "")) if entry is Dictionary else ""
		var kind := StringName(str((entry as Dictionary).get("kind", fallback_kind) if entry is Dictionary else entry))
		var soul := _make_soul(kind)
		var x := route.to_local(Vector2(first_x + figure_spacing * i, 0.0)).x
		soul.position = figure_layer.to_local(route.to_global(route.point_at(route.distance_at_x(x))))
		var figure := soul as StickFigure
		if figure != null and turned_away:
			figure.eyes = StickFigure.Eyes.HIDDEN
		if figure != null and says != "" and plead_pose != null:
			figure.pose = plead_pose
		figure_layer.add_child(soul)
		if says != "":
			_pleas[soul] = _add_plea(soul, says)
		placed.append(soul)
	return placed


func _make_soul(kind_id: StringName) -> Soul:
	var kind := SoulKind.find(kind_id)
	if kind == null:
		push_warning("Trolley stage: no soul kind '%s', drawing a %s." % [kind_id, fallback_kind])
		kind = SoulKind.find(fallback_kind)
	return kind.make()


## Floats [param says] over [param soul]'s head, waiting to be inked on.
func _add_plea(soul: Soul, says: String) -> Plea:
	var plea := plea_scene.instantiate() as Plea
	figure_layer.add_child(plea)
	plea.set_words(says)
	var figure := soul as StickFigure
	var over := figure.head_top() if figure != null else Vector2.ZERO
	plea.place(figure_layer.to_local(soul.to_global(over)))
	return plea


## Ties [param souls] together with a rope.
func _tie(souls: Array[Soul]) -> Rope:
	var rope := Rope.new()
	figure_layer.add_child(rope)
	rope.souls = souls
	return rope


## Lays the dark over [param route] from [member dark_start_x] on past its end.
func _darken(route: Track) -> Darkness:
	var dark := Darkness.new()
	var start := to_local(route.to_global(route.point_at(route.distance_at_x(route.to_local(Vector2(dark_start_x, 0.0)).x))))
	var end := to_local(route.to_global(route.point_at(route.length())))
	dark.position = start
	dark.area = Rect2(0.0, -dark_reach.x, end.x - start.x + dark_overrun, dark_reach.x + dark_reach.y)
	add_child(dark)
	return dark


## The route the option at [param index] sends the trolley down.
func _option_route(index: int) -> int:
	if index < 0 or index >= question.options.size():
		return 0
	return clampi(int(question.options[index].outcome.get(_TRACK_KEY, 0)), 0, _figures.size() - 1)


## The first option that sends the trolley down [param route], or -1.
func _route_option(route: int) -> int:
	if route < 0:
		return -1
	for i in question.options.size():
		if _option_route(i) == route:
			return i
	return -1


## The route of a fan nearest the pointer, if it is close enough to pick, or -1.
func _route_under(event: InputEventMouse) -> int:
	var nearest := -1
	var nearest_distance := pick_radius
	for i in _figures.size():
		var local := (_routes[i].make_input_local(event) as InputEventMouse).position
		var distance := _routes[i].distance_to_point(local)
		if distance < nearest_distance:
			nearest = i
			nearest_distance = distance
	return nearest


## Lights [param route] amber, and puts any other back to ink. -1 lights none.
func _light_route(route: int) -> void:
	_lit_route = route
	for i in _routes.size():
		_routes[i].color_override = picked_role if i == route else &""
		_routes[i].width_scale = picked_width if i == route else 1.0


func _on_lever_hover_changed(hovered: bool) -> void:
	option_hovered.emit(_lever_option if hovered else -1)


func _on_lever_pulled() -> void:
	option_committed.emit(_lever_option)
