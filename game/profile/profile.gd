class_name Profile
extends RefCounted
## The silent portrait: which way the player leans on each axis. It is never shown during play,
## and neither pole of any axis is the good one. The axes are listed in [code]content/profile_axes.json[/code].

## Emitted whenever a choice nudges an axis.
signal nudged(axis: StringName, delta: float)

const AXES_PATH := "res://content/profile_axes.json"

## How far the player leans on each axis so far. Negative leans toward the axis's first pole.
var leanings: Dictionary[StringName, float] = {}
## How much each axis has been nudged so far, either way, so a leaning can be read against how often the
## axis came up.
var reach: Dictionary[StringName, float] = {}


## The ids of every profile axis.
static func axis_ids() -> PackedStringArray:
	var ids := PackedStringArray()
	var loader := ContentLoader.new()
	var data: Variant = loader.read_json(AXES_PATH)
	if data is Dictionary:
		for axis: Variant in data.get("axes", []):
			if axis is Dictionary:
				ids.append(str(axis.get("id", "")))
	for problem in loader.problems:
		push_error(problem)
	return ids


## The names of each axis's two poles, first and second, by axis id.
static func axis_poles() -> Dictionary:
	var poles := {}
	var loader := ContentLoader.new()
	var data: Variant = loader.read_json(AXES_PATH)
	if data is Dictionary:
		for axis: Variant in data.get("axes", []):
			if axis is Dictionary:
				poles[str(axis.get("id", ""))] = PackedStringArray(axis.get("poles", []))
	return poles


## Adds a choice's nudges to the portrait.
func apply(nudges: Dictionary[StringName, float]) -> void:
	for axis in nudges:
		leanings[axis] = leanings.get(axis, 0.0) + nudges[axis]
		reach[axis] = reach.get(axis, 0.0) + absf(nudges[axis])
		nudged.emit(axis, nudges[axis])


## How far the player leans on [param axis] against how much it was nudged either way, from -1 (every
## nudge toward its first pole) to 1 (every one toward its second). [param doubt] is read as that many
## nudges' worth of nudging that went neither way, so an axis that came up once or twice leans less far
## than one that came up all game. 0 when it was never nudged.
func lean(axis: StringName, doubt := 0.0) -> float:
	var nudged_by: float = reach.get(axis, 0.0) + maxf(doubt, 0.0)
	return clampf(leanings.get(axis, 0.0) / nudged_by, -1.0, 1.0) if nudged_by > 0.0 else 0.0


## The portrait as plain data, for the save: the leanings, and how much each axis was nudged.
func to_data() -> Dictionary:
	return {"leanings": _plain(leanings), "reach": _plain(reach)}


## Restores the portrait from [method to_data]. An older save that kept only the leanings, axis by
## axis, takes each leaning as its own reach.
func load_data(data: Dictionary) -> void:
	leanings.clear()
	reach.clear()
	var kept: Dictionary = data.get("leanings", data)
	for axis: Variant in kept:
		leanings[StringName(str(axis))] = float(kept[axis])
	var nudged_by: Dictionary = data.get("reach", {})
	for axis in leanings:
		reach[axis] = float(nudged_by.get(String(axis), absf(leanings[axis])))


## Whether [param data] is a portrait [method load_data] can restore.
static func is_valid_data(data: Variant) -> bool:
	if not data is Dictionary:
		return false
	for part: Variant in [data.get("leanings", data), data.get("reach", {})]:
		if not part is Dictionary:
			return false
		for axis: Variant in part:
			if not (part[axis] is int or part[axis] is float):
				return false
	return true


static func _plain(values: Dictionary[StringName, float]) -> Dictionary:
	var data := {}
	for axis in values:
		data[String(axis)] = values[axis]
	return data
