@tool
class_name SoundCue
extends Resource
## One sound effect: the takes it picks from, how loud it plays under the voices, how far its pitch
## wanders, and how soon it may play again. [Sfx] plays it on the SFX bus. Every take of a sound is saved
## at the same peak, so how loud it plays in the game is this cue's alone.

## The takes, one picked each time it plays, never the same one twice running while there is another.
@export var takes: Array[AudioStream] = []
## How loud it plays, in decibels, before the SFX bus and the player's settings.
@export_range(-60.0, 12.0, 0.5) var volume_db := -12.0
## How far its pitch wanders either way each time it plays, as a share of its pitch, so a sound heard
## often never repeats exactly.
@export_range(0.0, 0.5, 0.005) var pitch_spread := 0.03
## Seconds after it plays before it will play again; asked sooner, it keeps quiet.
@export_range(0.0, 5.0, 0.005) var cool_down := 0.0
## Whether it plays on while the game is held still, as the menus' sounds do. Otherwise it pauses with
## the game.
@export var through_pause := false
