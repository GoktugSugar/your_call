class_name TrailerSteps
extends RefCounted
## Plays a shot's steps in turn, from the cut: what happens when, beside the question if the shot has
## one. A step waits for its moment, then does what it says. Development only, like the rest of the
## trailers.
##
## Waiting: [code]on[/code] a phase of the question (asking, choosing, consequence, reacting,
## revealing), [code]at[/code] a time into the shot, then [code]wait[/code] seconds more.
## Doing: [code]mark[/code] the moment in the log under a name; move the [code]camera[/code] (zoom, at,
## seconds); set the imp's [code]face[/code]; [code]warp[/code] or [code]drift[/code] him to a spot;
## [code]highlight[/code] or [code]commit[/code] an option; have the studio [code]applaud[/code] for some
## seconds; open the [code]eyes[/code]; ink on the [code]title[/code] card with its release line under
## it; and last [code]say[/code] one of the trailers' lines or several (held [code]hold[/code] seconds
## once said, and kept up after with [code]keep[/code]), which the next step waits for.

var _trailer: Trailer


func _init(trailer: Trailer) -> void:
	_trailer = trailer


## Plays [param steps] in turn. Returns once the last has played.
func run(steps: Array) -> void:
	for raw: Variant in steps:
		if not raw is Dictionary or not _trailer.is_inside_tree():
			continue
		var step: Dictionary = raw
		if step.has("on"):
			await _trailer.reach(StringName(str(step["on"])))
		if step.has("at"):
			await _trailer.wait(float(step["at"]) - _trailer.clock)
		await _trailer.wait(float(step.get("wait", 0.0)))
		if step.has("mark"):
			_trailer.mark(str(step["mark"]))
		_act(step)
		if step.has("say"):
			var said: Variant = step["say"]
			await _trailer.say(said if said is Array else [said], float(step.get("hold", -1.0)), bool(step.get("keep", false)))


func _act(step: Dictionary) -> void:
	if step.has("camera"):
		var framing: Dictionary = _trailer.by_format(step["camera"])
		_trailer.camera.move_to(float(framing.get("zoom", _trailer.camera.zoom.x)),
				Trailer.vector(framing.get("at"), _trailer.camera.position), float(framing.get("seconds", 0.0)))
	if step.has("face"):
		_trailer.imp.set_face(ImpDrawing.face_named(StringName(str(step["face"]))))
	if step.has("warp"):
		_trailer.imp.warp_to(Trailer.vector(_trailer.by_format(step["warp"]), _trailer.imp.position))
	if step.has("drift"):
		_trailer.imp.drift_to(Trailer.vector(_trailer.by_format(step["drift"]), _trailer.imp.position))
	if step.has("highlight"):
		_trailer.highlight(int(step["highlight"]))
	if step.has("commit"):
		_trailer.commit(int(step["commit"]))
	if step.has("applaud") and _trailer.studio != null:
		_trailer.studio.applaud(float(step["applaud"]))
	if step.has("eyes"):
		_trailer.eyelids.open()
	if step.has("title"):
		_trailer.title_card.set_words(str(step["title"]))
		_trailer.title_card.ink_on()
