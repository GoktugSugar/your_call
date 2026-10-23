class_name SaveData
extends RefCounted
## Reads and writes the files the game keeps between sessions, as JSON. A file is written whole beside
## its place first and only then moved into it, so quitting halfway through a write never leaves half a
## file; if the move itself was cut short, reading falls back on the whole copy beside it.

## Ending of the copy a file is written to before it takes the file's place.
const WRITING := ".writing"


## The data kept at [param path], or null when there is none or it cannot be read as JSON.
static func read(path: String) -> Variant:
	for each: String in [path, path + WRITING]:
		if not FileAccess.file_exists(each):
			continue
		var json := JSON.new()
		if json.parse(FileAccess.get_file_as_string(each)) == OK:
			return json.data
	return null


## Keeps [param data] at [param path]. Returns whether it was kept.
static func write(path: String, data: Dictionary) -> bool:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var writing := path + WRITING
	var file := FileAccess.open(writing, FileAccess.WRITE)
	if file == null:
		push_error("SaveData: could not write %s (%s)" % [writing, error_string(FileAccess.get_open_error())])
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	var error := DirAccess.rename_absolute(writing, path)
	if error != OK:
		push_error("SaveData: could not move %s into place (%s)" % [writing, error_string(error)])
		return false
	return true


## Forgets what is kept at [param path], and any copy left beside it.
static func remove(path: String) -> void:
	for each: String in [path, path + WRITING]:
		if FileAccess.file_exists(each):
			DirAccess.remove_absolute(each)


## Whether [param data] holds text at every one of [param keys].
static func has_text(data: Dictionary, keys: PackedStringArray) -> bool:
	for key in keys:
		if not data.get(key) is String:
			return false
	return true


## Whether [param data] holds a number at every one of [param keys]. JSON reads every number back as a
## float, so whole numbers count either way.
static func has_numbers(data: Dictionary, keys: PackedStringArray) -> bool:
	for key in keys:
		var value: Variant = data.get(key)
		if not (value is int or value is float):
			return false
	return true
