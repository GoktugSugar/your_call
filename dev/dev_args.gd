class_name DevArgs
extends RefCounted
## Development only: reads [code]--key=value[/code] switches given after [code]--[/code] on the command line.


## Applies [code]--window=WxH[/code] if given: a plain window of exactly that size, for checking how
## the game looks at a given resolution whatever the project's window mode.
static func apply_window(window: Window, args: Dictionary) -> void:
	if not args.has("window"):
		return
	var size := String(args["window"]).split("x")
	window.mode = Window.MODE_WINDOWED
	window.size = Vector2i(int(size[0]), int(size[1]))


## The switches as a dictionary. A switch with no value maps to [code]"true"[/code].
static func parse() -> Dictionary:
	var result := {}
	for arg in OS.get_cmdline_user_args():
		if not arg.begins_with("--"):
			continue
		var pair := arg.trim_prefix("--").split("=", true, 1)
		result[pair[0]] = pair[1] if pair.size() > 1 else "true"
	return result
