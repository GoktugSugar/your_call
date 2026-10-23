class_name EndingsRecord
extends RefCounted
## The record of which endings the player has reached, kept across runs and sessions when the run's own
## save is cleared, for an endings gallery one day. Each ending is named by its id in the content.

## The version of what the record holds.
const VERSION := 1
## Where the record is kept.
const DEFAULT_PATH := "user://endings.json"

## Where the record is kept. Tests point it elsewhere so they never touch the player's own.
static var path := DEFAULT_PATH


## Adds [param ending] to the endings reached, once.
static func add(ending: StringName) -> void:
	var reached := seen()
	if String(ending) in reached:
		return
	reached.append(String(ending))
	SaveData.write(path, {"version": VERSION, "seen": reached})


## Every ending reached so far, in the order they were first reached.
static func seen() -> PackedStringArray:
	var reached := PackedStringArray()
	var data: Variant = SaveData.read(path)
	if data is Dictionary and data.get("seen") is Array:
		for ending: Variant in data["seen"]:
			if ending is String:
				reached.append(ending)
	return reached
