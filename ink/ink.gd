extends Node
## The boil clock (autoload [code]Ink[/code]). Every few frames it moves the whole page on to its next
## variant, the way a hand-drawn animation redraws its lines, and every ink drawing redraws with it.
## It keeps ticking while the game is paused, so the page stays alive behind the pause menu.

## Emitted when the page moves on to its next variant.
signal boiled(variant: int)

## The variant every line draws right now.
var variant := 0
## Seconds the page has been alive. Idle motion such as breathing reads it, so it steps with the boil.
var time := 0.0

var _elapsed := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	var style := InkStyle.get_default()
	time += delta
	_elapsed += delta
	var interval := 1.0 / style.boil_fps
	if _elapsed < interval:
		return
	_elapsed = fmod(_elapsed, interval)
	variant = (variant + 1) % style.boil_variants
	boiled.emit(variant)
