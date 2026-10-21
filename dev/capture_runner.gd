extends Node
## Development only: runs a scene, saves screenshots of it at set times, then quits.
## [codeblock]
## Godot --path . --resolution 1920x1080 res://dev/capture_runner.tscn -- \
##     --scene=res://game/main.tscn --out=C:/somewhere/shot --times=0.5,2,4
## [/codeblock]
## Screenshots are saved as [code]<out>_<time>.png[/code]. Every other argument after [code]--[/code]
## is left for the scene itself, so a scene's own dev switches still work.

## Scene to run when none is given on the command line.
@export_file("*.tscn") var default_scene := "res://game/main.tscn"
## Seconds into the run to take a screenshot, when none are given on the command line.
@export var default_times: PackedFloat32Array = [1.0]


func _ready() -> void:
	var args := DevArgs.parse()
	DevArgs.apply_window(get_window(), args)
	var scene_path: String = args.get("scene", default_scene)
	var out: String = args.get("out", OS.get_user_data_dir().path_join("capture"))
	var times := default_times
	if args.has("times"):
		times = PackedFloat32Array(Array(String(args["times"]).split(",")).map(func(t: String) -> float: return t.to_float()))
	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_error("capture: cannot load %s" % scene_path)
		get_tree().quit(1)
		return
	add_child(packed.instantiate())
	var elapsed := 0.0
	for time in times:
		if time > elapsed:
			await get_tree().create_timer(time - elapsed, true, false, true).timeout
			elapsed = time
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		var path := "%s_%s.png" % [out, String.num(time, 2).replace(".", "_")]
		image.save_png(path)
		print("capture: saved ", path)
	get_tree().quit()
