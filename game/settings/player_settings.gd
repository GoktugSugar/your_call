class_name PlayerSettings
extends RefCounted
## The player's settings, read wherever they apply. For now they last for the session and are set from
## the dev menu; the settings screen will set them and keep them between sessions.

## Whether each page of dialogue moves on by itself once it has been said, instead of waiting for a
## click. The page a choice follows still stays up while the player chooses.
static var auto_advance := false
