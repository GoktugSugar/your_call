class_name ContentLoader
extends RefCounted
## Reads the game's content from JSON into chapters, beats and lines, and reports anything malformed.
## The format is described in [code]content/README.md[/code]. Problems never stop a load: the loader
## keeps what it can, and lists each problem with where it is, so tests can fail on them.

const VERBS: PackedStringArray = ["binary", "multiple_choice", "coordination_gamble", "allocation", "self_sacrifice"]
const WEIGHTS: PackedStringArray = ["light", "medium", "heavy"]
const SPEAKERS: PackedStringArray = ["imp", "button", "plea", "headline", "confessor"]
const FACES: PackedStringArray = ["grin", "smug", "glare", "surprised"]

const _CHAPTER_KEYS: PackedStringArray = ["id", "title", "beats"]
const _QUESTION_KEYS: PackedStringArray = ["kind", "id", "number", "title", "verb", "weight", "stage", "ask", "lines",
		"options", "reveal"]
const _NARRATION_KEYS: PackedStringArray = ["kind", "id", "lines"]
const _CINEMATIC_KEYS: PackedStringArray = ["kind", "id", "scene"]
const _OPTION_KEYS: PackedStringArray = ["id", "label", "outcome", "crowd", "profile", "reaction", "ending"]
const _LINE_KEYS: PackedStringArray = ["text", "speaker", "face", "direction"]
## The key that marks a line inside stage data, such as a plea over a figure.
const _STAGE_LINE_KEY := "says"
## Keys in stage data whose words the player reads on the stage, such as a readout or a caption.
const _STAGE_TEXT_KEYS: PackedStringArray = ["text", "caption", "label"]
const _REVEAL_KEYS: PackedStringArray = ["heading", "labels", "mark"]
## Parts of a line id that a set of lines may not be named, since lines with those ids exist already.
const _RESERVED_SET_NAMES: PackedStringArray = ["ask", "stage"]

## Problems found so far, one line each, saying where.
var problems := PackedStringArray()

var _axes := PackedStringArray()


## [param axis_ids] are the profile axes nudges may name. Empty skips that check.
func _init(axis_ids := PackedStringArray()) -> void:
	_axes = axis_ids


## Reads the chapter at [param path]. Returns null only when the file cannot be read as JSON.
func load_chapter(path: String) -> ChapterData:
	var data: Variant = read_json(path)
	if data == null:
		return null
	if not data is Dictionary:
		problems.append("%s: not a JSON object" % path)
		return null
	var chapter := ChapterData.new()
	chapter.id = StringName(_text(data, "id", path, true))
	chapter.title = _text(data, "title", path)
	_check_keys(data, _CHAPTER_KEYS, path)
	var seen := {}
	for raw: Variant in _list(data, "beats", path):
		var beat := _beat(raw, chapter.id, path)
		if beat == null:
			continue
		if seen.has(beat.id):
			problems.append("%s: beat id '%s' is used twice" % [path, beat.id])
		seen[beat.id] = true
		chapter.beats.append(beat)
	return chapter


## Reads a JSON file, recording a problem if it cannot be read.
func read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		problems.append("%s: file not found" % path)
		return null
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		problems.append("%s:%d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return null
	return json.data


func _beat(raw: Variant, chapter_id: StringName, path: String) -> BeatData:
	if not raw is Dictionary:
		problems.append("%s: a beat is not an object" % path)
		return null
	var data: Dictionary = raw
	var id := _text(data, "id", path, true)
	var where := "%s: %s" % [path, id]
	match data.get("kind", ""):
		"question":
			_check_keys(data, _QUESTION_KEYS, where)
			return _question(data, chapter_id, StringName(id), where)
		"narration":
			_check_keys(data, _NARRATION_KEYS, where)
			var narration := NarrationData.new()
			narration.id = StringName(id)
			narration.chapter = chapter_id
			narration.lines = _lines(data, "lines", "%s.%s.lines" % [chapter_id, id], where)
			return narration
		"cinematic":
			_check_keys(data, _CINEMATIC_KEYS, where)
			var cinematic := CinematicData.new()
			cinematic.id = StringName(id)
			cinematic.chapter = chapter_id
			cinematic.scene = StringName(_text(data, "scene", where, true))
			return cinematic
		var kind:
			problems.append("%s: unknown beat kind '%s'" % [where, kind])
			return null


func _question(data: Dictionary, chapter_id: StringName, id: StringName, where: String) -> QuestionData:
	var question := QuestionData.new()
	question.id = id
	question.chapter = chapter_id
	question.number = _text(data, "number", where)
	question.title = _text(data, "title", where)
	question.verb = StringName(_one_of(data, "verb", VERBS, where))
	question.weight = StringName(_one_of(data, "weight", WEIGHTS, where))
	var stage: Variant = data.get("stage", {})
	if stage is Dictionary and str(stage.get("type", "")) != "":
		question.stage = stage
		_collect_stage_lines(stage, question.stage_lines, "%s.%s.stage" % [chapter_id, id])
		_collect_stage_texts(stage, question.stage_texts)
	else:
		problems.append("%s: stage needs an object with a type" % where)
	question.ask = _lines(data, "ask", "%s.%s.ask" % [chapter_id, id], where)
	var option_ids := {}
	for raw: Variant in _list(data, "options", where):
		var option := _option(raw, "%s.%s" % [chapter_id, id], where)
		if option == null:
			continue
		if option_ids.has(option.id):
			problems.append("%s: option id '%s' is used twice" % [where, option.id])
		option_ids[option.id] = true
		question.options.append(option)
	if question.options.size() < 2:
		problems.append("%s: a question needs at least two options" % where)
	var sets: Variant = data.get("lines", {})
	if sets is Dictionary:
		for set_name: Variant in sets:
			if str(set_name) in _RESERVED_SET_NAMES or option_ids.has(StringName(str(set_name))):
				problems.append("%s: a set of lines may not be called '%s'" % [where, set_name])
			question.line_sets[StringName(str(set_name))] = _lines(sets, str(set_name),
					"%s.%s.%s" % [chapter_id, id, set_name], where)
	else:
		problems.append("%s: lines needs an object of named lists" % where)
	var reveal: Variant = data.get("reveal", {})
	if reveal is Dictionary:
		_check_keys(reveal, _REVEAL_KEYS, where + " reveal")
		question.reveal_heading = str(reveal.get("heading", question.reveal_heading))
		question.reveal_mark = _text(reveal, "mark", where + " reveal")
		var labels := _list(reveal, "labels", where + " reveal")
		for label: Variant in labels:
			question.reveal_labels.append(str(label))
		if not labels.is_empty() and labels.size() != question.options.size():
			problems.append("%s: the reveal needs a label for each option" % where)
	return question


func _option(raw: Variant, line_prefix: String, where: String) -> OptionData:
	if not raw is Dictionary:
		problems.append("%s: an option is not an object" % where)
		return null
	var data: Dictionary = raw
	var option := OptionData.new()
	option.id = StringName(_text(data, "id", where, true))
	var here := "%s option %s" % [where, option.id]
	_check_keys(data, _OPTION_KEYS, here)
	option.label = _text(data, "label", here, true)
	var crowd: Variant = data.get("crowd")
	if crowd is float or crowd is int:
		option.crowd = float(crowd)
	else:
		problems.append("%s: crowd needs a number" % here)
	var outcome: Variant = data.get("outcome", {})
	if outcome is Dictionary:
		option.outcome = outcome
	else:
		problems.append("%s: outcome needs an object" % here)
	var profile: Variant = data.get("profile", {})
	if profile is Dictionary:
		for axis: Variant in profile:
			var nudge: Variant = profile[axis]
			if not (nudge is float or nudge is int):
				problems.append("%s: profile nudge for '%s' needs a number" % [here, axis])
			elif not _axes.is_empty() and not str(axis) in _axes:
				problems.append("%s: unknown profile axis '%s'" % [here, axis])
			else:
				option.profile[StringName(axis)] = float(nudge)
	else:
		problems.append("%s: profile needs an object" % here)
	var reaction: Variant = data.get("reaction", [])
	if reaction is Dictionary:
		# Keyed by the outcome the stage reports: each outcome has its own lines.
		for result: Variant in reaction:
			option.reactions[StringName(str(result))] = _lines(reaction, str(result),
					"%s.%s.%s" % [line_prefix, option.id, result], here)
		if (reaction as Dictionary).is_empty():
			problems.append("%s: reaction needs at least one outcome" % here)
	else:
		option.reaction = _lines(data, "reaction", "%s.%s" % [line_prefix, option.id], here)
	var ending: Variant = data.get("ending", "")
	if ending is String:
		option.ending = StringName(ending)
	elif ending is Dictionary:
		for result: Variant in ending:
			option.endings[StringName(str(result))] = StringName(str(ending[result]))
	else:
		problems.append("%s: ending needs a name, or an object of names by outcome" % here)
	return option


func _lines(data: Dictionary, key: String, id_prefix: String, where: String) -> Array[LineData]:
	var lines: Array[LineData] = []
	var raw_lines := _list(data, key, where)
	for i in raw_lines.size():
		var line := _line(raw_lines[i], "%s.%d" % [id_prefix, i + 1])
		if line != null:
			lines.append(line)
	if lines.is_empty():
		problems.append("%s: %s needs at least one line" % [where, key])
	return lines


## One line, from text said by [param default_speaker] or from an object that can name its own speaker.
func _line(raw: Variant, line_id: String, default_speaker := &"imp") -> LineData:
	if raw is String:
		return LineData.make(line_id, raw, default_speaker)
	if not raw is Dictionary:
		problems.append("%s: a line must be text or an object" % line_id)
		return null
	_check_keys(raw, _LINE_KEYS, line_id)
	var speaker := str(raw.get("speaker", default_speaker))
	var face := str(raw.get("face", ""))
	if not speaker in SPEAKERS:
		problems.append("%s: unknown speaker '%s'" % [line_id, speaker])
	if face != "" and not face in FACES:
		problems.append("%s: unknown face '%s'" % [line_id, face])
	var made := LineData.make(line_id, _text(raw, "text", line_id, true), StringName(speaker), StringName(face))
	made.direction = str(raw.get("direction", ""))
	return made


## Finds every [code]says[/code] in the stage data, depth first, and makes each a line: a plea for
## plain text, or whoever a line object names. A [code]says[/code] can also hold a list of them.
func _collect_stage_lines(value: Variant, into: Array[LineData], id_prefix: String) -> void:
	if value is Dictionary:
		if value.has(_STAGE_LINE_KEY):
			_add_stage_lines(value[_STAGE_LINE_KEY], into, id_prefix)
		for key: Variant in value:
			if key != _STAGE_LINE_KEY:
				_collect_stage_lines(value[key], into, id_prefix)
	elif value is Array:
		for item: Variant in value:
			_collect_stage_lines(item, into, id_prefix)


func _add_stage_lines(said: Variant, into: Array[LineData], id_prefix: String) -> void:
	if said is Array:
		for each: Variant in said:
			_add_stage_lines(each, into, id_prefix)
		return
	var line := _line(said, "%s.%d" % [id_prefix, into.size() + 1], &"plea")
	if line != null:
		into.append(line)


## Finds every readout, caption and label in the stage data, outside the lines it holds.
func _collect_stage_texts(value: Variant, into: PackedStringArray) -> void:
	if value is Dictionary:
		for key: Variant in value:
			if key == _STAGE_LINE_KEY:
				continue
			if str(key) in _STAGE_TEXT_KEYS and value[key] is String:
				into.append(value[key])
			else:
				_collect_stage_texts(value[key], into)
	elif value is Array:
		for item: Variant in value:
			_collect_stage_texts(item, into)


func _list(data: Dictionary, key: String, where: String) -> Array:
	var value: Variant = data.get(key, [])
	if value is Array:
		return value
	problems.append("%s: %s needs a list" % [where, key])
	return []


func _text(data: Dictionary, key: String, where: String, required := false) -> String:
	var value: Variant = data.get(key, "")
	if not value is String:
		problems.append("%s: %s needs text" % [where, key])
		return ""
	if required and (value as String).is_empty():
		problems.append("%s: %s is missing" % [where, key])
	return value


func _one_of(data: Dictionary, key: String, allowed: PackedStringArray, where: String) -> String:
	var value := _text(data, key, where, true)
	if not value.is_empty() and not value in allowed:
		problems.append("%s: %s '%s' is not one of %s" % [where, key, value, ", ".join(allowed)])
	return value


func _check_keys(data: Dictionary, allowed: PackedStringArray, where: String) -> void:
	for key: Variant in data:
		if not str(key) in allowed:
			problems.append("%s: unknown key '%s'" % [where, key])
