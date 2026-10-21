class_name TrolleyStage
extends Stage
## The trolley problem, staged: a trolley waiting on the approach, tracks that split by a lever,
## and souls standing on each track. If nobody pulls, the trolley takes track 0, the straight one.
## Stage data: [code]{"type": "trolley", "tracks": [{"figures": ["stranger", ...]}, ...]}[/code].
## An option's outcome [code]{"track": n}[/code] sends the trolley down track n. The lever stands
## for the first option that leaves track 0.

## The track the trolley waits on, which ends at the split.
@export var approach: Track
## The tracks beyond the split, in data order. Track 0 runs straight on.
@export var routes: Array[Track] = []
@export var trolley: TrolleyCart
@export var lever: Lever
## Where the figures are added.
@export var figure_layer: Node2D
## The figure each soul on the tracks is drawn with.
@export var figure_scene: PackedScene

@export_group("Figures")
## Canvas x of the middle of each track's group of figures.
@export var figures_center_x := 1320.0
## Distance between neighbouring figures on a track.
@export_range(20.0, 300.0, 1.0) var figure_spacing := 68.0

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

const _TRACK_KEY := "track"
## The only kind of soul the trolley stage draws so far.
const _STRANGER := "stranger"

## The figures on each route, nearest the split first.
var _figures: Array[Array] = []
var _lever_option := -1
## The roll under way: its route, the figures on it, how far along the route each is hit, and the next to hit.
var _route: Track
var _victims: Array = []
var _hit_at := PackedFloat32Array()
var _next_hit := 0


func setup(for_question: QuestionData) -> void:
	super.setup(for_question)
	var tracks: Array = for_question.stage.get("tracks", [])
	for i in routes.size():
		routes[i].visible = i < tracks.size()
	_figures.clear()
	for i in mini(tracks.size(), routes.size()):
		var track_data: Dictionary = tracks[i]
		_figures.append(_place_figures(routes[i], track_data.get("figures", [])))
	for i in for_question.options.size():
		if int(for_question.options[i].outcome.get(_TRACK_KEY, 0)) != 0:
			_lever_option = i
			break
	lever.visible = _lever_option >= 0
	lever.hover_changed.connect(_on_lever_hover_changed)
	lever.pulled.connect(_on_lever_pulled)
	_place_trolley(trolley_start, routes[0])


func set_choosing(active: bool) -> void:
	lever.live = active and _lever_option >= 0


func highlight_option(index: int) -> void:
	lever.highlighted = index >= 0 and index == _lever_option


func play_consequence(index: int) -> void:
	set_choosing(false)
	lever.highlighted = false
	var route := clampi(int(question.options[index].outcome.get(_TRACK_KEY, 0)), 0, _figures.size() - 1)
	if route != 0:
		await lever.throw()
		await get_tree().create_timer(lever_pause, false).timeout
	await _roll(route)


func _roll(route_index: int) -> void:
	_route = routes[route_index]
	_victims = _figures[route_index]
	_hit_at.clear()
	for figure: StickFigure in _victims:
		_hit_at.append(_route.distance_at_x(_route.to_local(figure.global_position).x))
	_next_hit = 0
	var to_end := approach.length() + _route.length() - trolley_front
	var exit_speed := 2.0 * (to_end - trolley_start) / roll_duration
	var roll := create_tween()
	roll.tween_method(_roll_step, trolley_start, to_end, roll_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	roll.tween_method(_roll_step, to_end, to_end + exit_speed * exit_duration, exit_duration)
	roll.parallel().tween_property(trolley, ^"dissolve", 1.0, exit_duration)
	await roll.finished
	for figure: StickFigure in _victims:
		if figure.dissolve < 1.0:
			await figure.folded


func _roll_step(distance: float) -> void:
	_place_trolley(distance, _route)
	var front_on_route := distance + trolley_front + hit_lead - approach.length()
	while _next_hit < _victims.size() and front_on_route >= _hit_at[_next_hit]:
		(_victims[_next_hit] as StickFigure).fold(1.0)
		_next_hit += 1


func _place_trolley(distance: float, route: Track) -> void:
	var on_approach := distance <= approach.length()
	var track := approach if on_approach else route
	var along := distance if on_approach else distance - approach.length()
	trolley.position = to_local(track.to_global(track.point_at(along)))
	trolley.rotation = track.direction_at(along).angle()


func _place_figures(route: Track, kinds: Array) -> Array[StickFigure]:
	var placed: Array[StickFigure] = []
	var first_x := figures_center_x - figure_spacing * (kinds.size() - 1) * 0.5
	for i in kinds.size():
		if kinds[i] != _STRANGER:
			push_warning("Trolley stage: no figure kind '%s' yet, drawing a stranger." % kinds[i])
		var figure := figure_scene.instantiate() as StickFigure
		var x := route.to_local(Vector2(first_x + figure_spacing * i, 0.0)).x
		figure.position = figure_layer.to_local(route.to_global(route.point_at(route.distance_at_x(x))))
		figure_layer.add_child(figure)
		placed.append(figure)
	return placed


func _on_lever_hover_changed(hovered: bool) -> void:
	option_hovered.emit(_lever_option if hovered else -1)


func _on_lever_pulled() -> void:
	option_committed.emit(_lever_option)
