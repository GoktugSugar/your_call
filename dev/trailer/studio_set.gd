class_name StudioSet
extends Node2D
## The Show's studio with nobody on stage, for the imp to host the trailers from: the valance across the
## top, the floor and its footlights, and the audience at the foot of the page, the parts
## [StudioStage] builds every round from, coloured the same. The audience claps on cue. Development
## only, like the rest of the trailers.

## Where the floor runs across the page.
@export_range(0.0, 1080.0, 1.0) var floor_y := 700.0
@export var curtain_role := &"purple"
@export_range(0.0, 1.0, 0.01) var curtain_wash := 0.5
@export var trim_role := &"gold"
@export var audience_clothes: Array[StringName] = [&"sky", &"green", &"orange", &"purple"]
@export var footlights: Array[StringName] = [&"gold", &"sky", &"purple", &"green", &"orange"]
## Where the audience sits, in blocks; none keeps the audience's own, either side of the dialogue box.
@export var audience_blocks: Array[Rect2] = []
## Seconds the set takes to draw on.
@export_range(0.0, 5.0, 0.01) var draw_time := 0.9
## The applause the audience claps to.
@export var applause_sound: SoundCue = preload("res://game/audio/cues/applause.tres")
## Seconds the applause takes to fade once the clapping stops.
@export_range(0.0, 3.0, 0.05) var applause_fade := 0.6

var _audience: Audience
var _parts: Array[InkDrawing] = []


func _ready() -> void:
	var valance := StudioValance.new()
	valance.z_index = -1
	valance.wash_role = curtain_role
	valance.wash_strength = curtain_wash
	valance.trim_role = trim_role
	var studio_floor := StudioFloor.new()
	studio_floor.position = Vector2(0.0, floor_y)
	studio_floor.z_index = 2
	studio_floor.footlights = footlights
	_audience = Audience.new()
	_audience.z_index = 3
	_audience.clothes = audience_clothes
	if not audience_blocks.is_empty():
		_audience.blocks = audience_blocks
	_parts = [valance, studio_floor, _audience]
	for part in _parts:
		add_child(part)


## Draws the set on over [param seconds], or at once with none.
func draw_on(seconds := -1.0) -> void:
	var duration := draw_time if seconds < 0.0 else seconds
	for part in _parts:
		if duration <= 0.0:
			part.reveal = 1.0
		else:
			part.draw_on(duration)


## The audience claps for [param seconds], to applause.
func applaud(seconds: float) -> void:
	_audience.clap(seconds)
	Sfx.release(Sfx.play(applause_sound), applause_fade, seconds)
