class_name CinematicShot
extends TrailerShot
## One of the game's cinematics, such as the crash, played over everything.
## Settings: [code]scene[/code], the cinematic's name; [code]tune[/code], its settings to change, such as
## the seed of its flicker so every recording flickers alike.


func play(trailer: Trailer, settings: Dictionary) -> void:
	var scene := str(settings.get("scene", ""))
	var path := RunPlayer.CINEMATIC_SCENE % [scene, scene]
	if not ResourceLoader.exists(path):
		push_error("Trailer: no cinematic at %s" % path)
		return
	var cinematic := (load(path) as PackedScene).instantiate()
	Trailer.tune(cinematic, settings.get("tune", {}))
	trailer.overlay_root.add_child(cinematic)
	await cinematic.play()
