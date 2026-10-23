class_name RunSave
extends RefCounted
## The one continuous save: where the run is, the beat it last began, and everything the run remembered
## as that beat began. Continue picks the run up there, and the beat plays again from its start. A save
## that is missing, cannot be read, was written by another version of the save, or names a chapter or
## beat the run no longer has counts as no save at all.

## The version of what the save holds. A save of any other version counts as no save.
const VERSION := 1
## Where the save is kept.
const DEFAULT_PATH := "user://run.json"

## Where the save is kept. Tests point it elsewhere so they never touch the player's own.
static var path := DEFAULT_PATH
## The save Continue picked, waiting for the run to take it up ([method take_pending]).
static var pending: RunSave

## The chapter the run was in, by id.
var chapter := &""
## The beat that had just begun, by id. The run picks up at its start.
var beat := &""
## What the run remembered as that beat began.
var run: RunState


## What to keep for a run that has just begun [param beat_id] of [param chapter_id], remembering what
## [param remembered] does now. The data is a copy, so the run can go on changing.
static func snapshot(chapter_id: StringName, beat_id: StringName, remembered: RunState) -> Dictionary:
	return {"version": VERSION, "chapter": String(chapter_id), "beat": String(beat_id), "run": remembered.to_data()}


## Keeps [param data], a [method snapshot], as the save. Returns whether it was kept.
static func write(data: Dictionary) -> bool:
	return SaveData.write(path, data)


## The save, if there is one the run of [param chapters] can pick up; otherwise null.
static func load_valid(chapters: Array[ChapterData]) -> RunSave:
	var data: Variant = SaveData.read(path)
	if not data is Dictionary or not SaveData.has_numbers(data, ["version"]) or int(data["version"]) != VERSION \
			or not SaveData.has_text(data, ["chapter", "beat"]):
		return null
	var found := RunSave.new()
	found.chapter = StringName(data["chapter"])
	found.beat = StringName(data["beat"])
	if not _run_has(chapters, found.chapter, found.beat):
		return null
	found.run = RunState.from_data(data.get("run"))
	return found if found.run != null else null


## Forgets the save: the run is over, or a new one has begun.
static func clear() -> void:
	SaveData.remove(path)


## Takes up the save Continue picked, leaving none waiting. Null when the run is not a continued one.
static func take_pending() -> RunSave:
	var taken := pending
	pending = null
	return taken


static func _run_has(chapters: Array[ChapterData], chapter_id: StringName, beat_id: StringName) -> bool:
	for each in chapters:
		if each.id == chapter_id:
			return each.find_beat(beat_id) != null
	return false
