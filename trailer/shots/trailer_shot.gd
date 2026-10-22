class_name TrailerShot
extends RefCounted
## One kind of shot in the trailer, played from its settings in the cut ([code]trailer_cut.json[/code]).
## The trailer sets the page up first: the imp, the camera, the eyes. A shot then plays its action with
## the trailer's pieces: the game's own stages, the imp and the dialogue box. The recording runs on
## after the action ends, for as long as the cut takes from it.


## Plays the shot's action with [param trailer]'s pieces, from [param settings]. Returns when the action
## is done.
func play(_trailer: Trailer, _settings: Dictionary) -> void:
	pass
