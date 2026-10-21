class_name Profile
extends RefCounted
## The silent portrait: which way the player leans on each axis. It is never shown during play,
## and neither pole of any axis is the good one. The axes are listed in [code]content/profile_axes.json[/code].

## Emitted whenever a choice nudges an axis.
signal nudged(axis: StringName, delta: float)

const AXES_PATH := "res://content/profile_axes.json"

## How far the player leans on each axis so far. Negative leans toward the axis's first pole.
var leanings: Dictionary[StringName, float] = {}


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


## Adds a choice's nudges to the portrait.
func apply(nudges: Dictionary[StringName, float]) -> void:
	for axis in nudges:
		leanings[axis] = leanings.get(axis, 0.0) + nudges[axis]
		nudged.emit(axis, nudges[axis])


## The portrait as plain data, for the save.
func to_data() -> Dictionary:
	var data := {}
	for axis in leanings:
		data[String(axis)] = leanings[axis]
	return data


## Restores the portrait from [method to_data].
func load_data(data: Dictionary) -> void:
	leanings.clear()
	for axis: Variant in data:
		leanings[StringName(str(axis))] = float(data[axis])
