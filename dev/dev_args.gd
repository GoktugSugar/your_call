class_name DevArgs
extends RefCounted
## Development only: reads [code]--key=value[/code] switches given after [code]--[/code] on the command line.


## The switches as a dictionary. A switch with no value maps to [code]"true"[/code].
static func parse() -> Dictionary:
	var result := {}
	for arg in OS.get_cmdline_user_args():
		if not arg.begins_with("--"):
			continue
		var pair := arg.trim_prefix("--").split("=", true, 1)
		result[pair[0]] = pair[1] if pair.size() > 1 else "true"
	return result
