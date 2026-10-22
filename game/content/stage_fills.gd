class_name StageFills
extends RefCounted
## What a stage fills into its question's placeholders, such as [code]{amount}[/code]. A stage that
## fills placeholders names them in [code]const FILLS: PackedStringArray[/code] on its script, and lists
## every filling its lines can take in [code]static func fill_variants(question) -> Dictionary[/code]:
## each line id with placeholders maps to an array of [code]{"variant": String, "fills": Dictionary}[/code].
## The tests check every filling, and the voice tools voice each one as a clip of its own.

## Path pattern of a stage's script, filled with the stage type twice.
const STAGE_SCRIPT := "res://stages/%s/%s_stage.gd"
const _NAMES := "FILLS"
const _VARIANTS := "fill_variants"


## The placeholder names [param question]'s stage fills.
static func names(question: QuestionData) -> PackedStringArray:
	var script := _script(question)
	if script == null:
		return PackedStringArray()
	return PackedStringArray(script.get_script_constant_map().get(_NAMES, PackedStringArray()))


## Every filling of every line of [param question] that has placeholders, by line id.
static func variants(question: QuestionData) -> Dictionary:
	var script := _script(question)
	if script == null:
		return {}
	for method in script.get_script_method_list():
		if method["name"] == _VARIANTS:
			return script.call(_VARIANTS, question)
	return {}


## [param line] filled every way its stage can fill it, or the line itself when it has no placeholders.
static func filled_lines(question: QuestionData, line: LineData) -> Array[LineData]:
	var out: Array[LineData] = []
	if line.placeholders().is_empty():
		out.append(line)
		return out
	for each: Dictionary in variants(question).get(line.id, []):
		out.append(line.filled(each["fills"], str(each["variant"])))
	return out


static func _script(question: QuestionData) -> GDScript:
	var type := str(question.stage.get("type", ""))
	var path := STAGE_SCRIPT % [type, type]
	return load(path) as GDScript if ResourceLoader.exists(path) else null
