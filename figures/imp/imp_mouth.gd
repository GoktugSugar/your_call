class_name ImpMouth
extends Node
## Moves the imp's mouth in time with what he says. While he talks it reads what is being said from
## [member speech] and opens his mouth to suit it: open on vowels, all but shut on m, b and p, a little
## open on f and v, half open on any other consonant, and shut on spaces and punctuation, the pauses.
## Like a hand-drawn mouth it changes shape in steps, a set number of times a second. Each shape stands
## for the sounds said while it is up: lips meeting anywhere in them close it, so a quick m is never
## skipped, and otherwise it opens as wide as they do on average. Each new shape goes most of the way
## toward that, so the mouth eases rather than snaps. When he stops talking, his mouth eases back into
## his face's own shape.

## The drawing whose mouth moves.
@export var drawing: ImpDrawing
## Off, his mouth keeps his face's own shape while he talks, to compare.
@export var moving := true

@export_group("Timing")
## How many times a second his mouth changes shape. Hand-drawn mouths change on twos, 12 times a second.
@export_range(1.0, 30.0, 0.5) var shapes_per_second := 12.0
## How many times it reads what is being said for each shape, spread evenly over the time the shape stays up.
@export_range(1, 12) var reads_per_shape := 4
## How far each new shape goes from the last toward the sounds it stands for: 1 jumps straight there,
## less eases there over a few shapes.
@export_range(0.05, 1.0, 0.01) var easing := 0.8
## Seconds ahead of the voice each shape starts reading. A shape already shows the sounds of the time it
## stays up, so it leads them a little at 0, as animators set a mouth a frame early; more moves it earlier.
@export_range(0.0, 0.3, 0.005) var lead := 0.0

@export_group("How open each sound is")
## On a vowel: a, e, i, o, u or y.
@export_range(0.0, 1.0, 0.01) var on_vowels := 1.0
## On f or v, lip on teeth.
@export_range(0.0, 1.0, 0.01) var on_f_and_v := 0.3
## On m, b or p, lips together.
@export_range(0.0, 1.0, 0.01) var on_m_b_and_p := 0.05
## On any other consonant, and on digits and signs said aloud.
@export_range(0.0, 1.0, 0.01) var on_consonants := 0.55
## On a space or punctuation, the pauses, and whenever nothing is being said.
@export_range(0.0, 1.0, 0.01) var on_pauses := 0.0

## Whether he is talking. His mouth only follows [member speech] while he is.
var talking := false
## What he is saying: called with seconds to look ahead, it returns the character being said then, or
## an empty string when nothing is. [Main] hands him the dialogue box's [method DialogueBox.spoken_character].
var speech := Callable()

const _VOWELS := "aeiouy"
const _LIPS_TOGETHER := "mbp"
const _LIP_ON_TEETH := "fv"
## Characters said aloud though they are not letters, such as the digits of a sum.
const _SAID_ALOUD := "0123456789$%&"
## Close enough to the sound's openness for the mouth to settle on it.
const _SETTLED := 0.005

var _open := 0.0
var _since_shape := 0.0


func _process(delta: float) -> void:
	_since_shape += delta
	var interval := 1.0 / shapes_per_second
	if _since_shape < interval:
		return
	_since_shape = fmod(_since_shape, interval)
	var target := _openness_ahead(interval) if moving and talking and speech.is_valid() else 0.0
	_open = lerpf(_open, target, easing)
	if absf(_open - target) < _SETTLED:
		_open = target
	if drawing.mouth_open != _open:
		drawing.mouth_open = _open


## How open his mouth is on [param character], one character of what he says: 0 is his face's own
## mouth, 1 as wide as it opens. An empty string is nothing being said.
func openness(character: String) -> float:
	if character.length() != 1:
		return on_pauses
	var sound := character.to_lower()
	if _VOWELS.contains(sound):
		return on_vowels
	if _LIPS_TOGETHER.contains(sound):
		return on_m_b_and_p
	if _LIP_ON_TEETH.contains(sound):
		return on_f_and_v
	# A letter has a capital; spaces and punctuation do not.
	if sound != sound.to_upper() or _SAID_ALOUD.contains(sound):
		return on_consonants
	return on_pauses


## How open the next shape is, standing for the [param interval] seconds it stays up: as shut as on m, b
## and p if the lips meet at any of the moments read, and otherwise the average openness of those moments.
func _openness_ahead(interval: float) -> float:
	var total := 0.0
	for i in reads_per_shape:
		var character := str(speech.call(lead + interval * i / reads_per_shape))
		if character.length() == 1 and _LIPS_TOGETHER.contains(character.to_lower()):
			return on_m_b_and_p
		total += openness(character)
	return total / reads_per_shape
