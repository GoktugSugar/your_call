extends Node
## Development only: plays the opening crash cinematic, then rolls the credits, for captures.

## The opening cinematic to play first.
@export var crash: CrashCinematic
## The credits to roll after it.
@export var credits: Credits
## Seconds between the end of the cinematic and the credits.
@export_range(0.0, 10.0, 0.05) var pause_between := 1.0


func _ready() -> void:
	crash.hit.connect(func() -> void: print("cinematic_sampler: hit at %.2f s" % (Time.get_ticks_msec() / 1000.0)))
	await crash.play()
	print("cinematic_sampler: cinematic finished at %.2f s" % (Time.get_ticks_msec() / 1000.0))
	await get_tree().create_timer(pause_between).timeout
	await credits.roll()
	print("cinematic_sampler: credits finished at %.2f s" % (Time.get_ticks_msec() / 1000.0))
