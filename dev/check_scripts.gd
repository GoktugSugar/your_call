extends SceneTree
## Development only: loads every GDScript file in the project outside addons/ and reports any that fail.
## [codeblock]
## Godot_Console --headless --path . -s res://dev/check_scripts.gd
## [/codeblock]
## Exits with code 1 when a script fails to load.

const _SKIP := ["res://addons", "res://.godot"]


func _initialize() -> void:
	var failed := PackedStringArray()
	var scripts := _find_scripts("res://")
	for path in scripts:
		var script := load(path) as Script
		if script == null or not script.can_instantiate():
			failed.append(path)
	if failed.is_empty():
		print("check_scripts: %d scripts load cleanly" % scripts.size())
		quit(0)
	else:
		printerr("check_scripts: %d of %d scripts failed to load:\n  %s" % [failed.size(), scripts.size(), "\n  ".join(failed)])
		quit(1)


func _find_scripts(dir_path: String) -> PackedStringArray:
	var found := PackedStringArray()
	if dir_path.trim_suffix("/") in _SKIP:
		return found
	for file in DirAccess.get_files_at(dir_path):
		if file.get_extension() == "gd":
			found.append(dir_path.path_join(file))
	for sub in DirAccess.get_directories_at(dir_path):
		if not FileAccess.file_exists(dir_path.path_join(sub).path_join(".gdignore")):
			found.append_array(_find_scripts(dir_path.path_join(sub)))
	return found
