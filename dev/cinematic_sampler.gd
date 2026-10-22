extends Node
## Development only: plays the opening crash, then the waking that opens every later chapter, then
## rolls the credits, for captures. With [code]--waking[/code] it plays the waking alone, at once.
## [codeblock]
## Godot --path . res://dev/capture_runner.tscn -- --scene=res://dev/cinematic_sampler.tscn \
##     --waking --out=C:/somewhere/shot --times=0.5,2,4
## [/codeblock]

## The opening cinematic to play first.
@export var crash: CrashCinematic
## The waking to play after it.
@export var waking: WakingCinematic
## The credits to roll at the end.
@export var credits: Credits
## Seconds between one piece ending and the next starting.
@export_range(0.0, 10.0, 0.05) var pause_between := 1.0


func _ready() -> void:
	var waking_only := DevArgs.parse().has("waking")
	crash.hit.connect(func() -> void: _log("hit"))
	waking.eyes_closed.connect(func() -> void: _log("eyes closed"))
	if not waking_only:
		_log("crash started")
		await crash.play()
		_log("crash finished")
		await get_tree().create_timer(pause_between).timeout
	_log("waking started")
	await waking.play()
	_log("waking finished")
	if waking_only:
		return
	await get_tree().create_timer(pause_between).timeout
	await credits.roll()
	_log("credits finished")


func _log(what: String) -> void:
	print("cinematic_sampler: %s at %.2f s" % [what, Time.get_ticks_msec() / 1000.0])
