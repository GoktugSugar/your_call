class_name TrailerQuestion
extends RefCounted
## Readies a question from the run for a shot: what the imp says in it is swapped for what the shot
## asks, so the question player plays the real stage, choice row and reveal around the trailers' lines.
## Development only, like the rest of the trailers.
##
## A shot's [code]ask[/code] lists what is asked, and its [code]react[/code] what is said to each option by
## its id; an entry is one of the trailers' lines by name, or a number, the question's own line in that
## place (counting from 1), such as a confessor's own words. Whatever a shot leaves out is not said: no
## ask, no reaction, none of the question's sets of lines but those named in [code]keep_lines[/code].
## No option fires an ending. [code]row[/code] lists the options the choice row shows, by place
## (counting from 0), for a row too long for the screen: the rest are left out of it. [code]stage[/code]
## sets properties on the stage as it is made, such as how fast a trolley runs, and [code]audience[/code]
## seats a studio round's audience in blocks of its own once the stage is built, each block x, y, width
## and height.


## Swaps the lines of [param question] for those [param settings] asks for, from [param trailer]'s,
## and has its stage take the settings' [code]stage[/code] properties. Returns the question, or null.
static func prepare(question: QuestionData, settings: Dictionary, trailer: Trailer) -> QuestionData:
	if question == null:
		return null
	question.ask = _lines_for(settings.get("ask", []), question.ask, trailer)
	question.asks = {}
	var kept := {}
	for set_name: Variant in settings.get("keep_lines", []):
		if question.line_sets.has(StringName(str(set_name))):
			kept[StringName(str(set_name))] = question.line_sets[StringName(str(set_name))]
	question.line_sets = kept
	question.ending = &""
	question.endings = {}
	var react: Dictionary = settings.get("react", {})
	var row: Variant = trailer.by_format(settings.get("row"))
	for i in question.options.size():
		var option := question.options[i]
		option.reaction = _lines_for(react.get(String(option.id), []), option.reaction, trailer)
		option.reactions = {}
		option.ending = &""
		option.endings = {}
		if row is Array and not (row as Array).has(float(i)) and not (row as Array).has(i):
			option.hidden = true
	var stage_settings: Variant = trailer.by_format(settings.get("stage", {}))
	if stage_settings is Dictionary and not (stage_settings as Dictionary).is_empty():
		trailer.question_player.stage_root.child_entered_tree.connect(_tune.bind(stage_settings), CONNECT_ONE_SHOT)
	var audience: Variant = trailer.by_format(settings.get("audience"))
	if audience is Array:
		trailer.question_player.phase_changed.connect(_seat_audience.bind(audience, trailer), CONNECT_ONE_SHOT)
	return question


## The lines [param entries] name: the trailers' by name, or the question's [param own] by place.
static func _lines_for(entries: Variant, own: Array[LineData], trailer: Trailer) -> Array[LineData]:
	var lines: Array[LineData] = []
	for entry: Variant in entries if entries is Array else [entries]:
		if entry is float or entry is int:
			var place := int(entry) - 1
			if place >= 0 and place < own.size():
				lines.append(own[place])
			else:
				push_error("Trailer: the question has no line %d" % int(entry))
		else:
			lines.append_array(trailer.lines_named([entry]))
	return lines


## Sets each of [param settings] on [param node] by name, as the stage is made.
static func _tune(node: Node, settings: Dictionary) -> void:
	for key: String in settings:
		node.set(StringName(key), settings[key])


## Seats the studio round's audience in [param blocks], now that its stage is built: the question has
## just started asking, before the stage draws on.
static func _seat_audience(_phase: QuestionPlayer.Phase, blocks: Array, trailer: Trailer) -> void:
	var stage := trailer.question_player.stage as StudioStage
	if stage == null:
		return
	var rects: Array[Rect2] = []
	for raw: Variant in blocks:
		rects.append(Rect2(float(raw[0]), float(raw[1]), float(raw[2]), float(raw[3])))
	stage.audience.blocks = rects
