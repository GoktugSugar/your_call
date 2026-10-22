class_name Plea
extends Node2D
## Words floating over a soul on the tracks, inked on a character at a time once the stage is drawn.
## They bob with the page's boil and fade when the soul dies or the stage goes.
## Its origin is the bottom middle of the words, which sits just over the soul's head.

## The label the words are set in. It grows upward from the origin as the words wrap.
@export var label: RichTextLabel
## Seconds each character takes to ink on.
@export_range(0.0, 0.5, 0.005) var seconds_per_character := 0.03
## How many characters the soft leading edge spans while the words ink on.
@export_range(0.0, 10.0, 0.1) var ink_edge := 3.0
## Seconds the words take to fade away.
@export_range(0.0, 3.0, 0.01) var fade_duration := 0.4
## How far the words bob up and down, in pixels.
@export_range(0.0, 10.0, 0.1) var bob := 2.0
## Seconds per bob.
@export_range(0.5, 10.0, 0.1) var bob_period := 2.6

var _effect := InkOnEffect.new()
var _rest := Vector2.ZERO


func _ready() -> void:
	label.install_effect(_effect)
	_effect.edge = ink_edge
	_rest = position
	Ink.boiled.connect(_on_boiled.unbind(1))


## Sets the words, in markup, without inking them on yet.
func set_words(markup: String) -> void:
	label.text = "[inkon]%s[/inkon]" % Markup.to_bbcode(markup, InkPalette.get_default())
	_effect.progress = 0.0


## Puts the words' bottom middle at [param at], in the parent's space.
func place(at: Vector2) -> void:
	_rest = at
	position = at


## Inks the words on.
func write_on() -> void:
	var count := label.get_total_character_count()
	var tween := create_tween()
	tween.tween_property(_effect, ^"progress", count + ink_edge, maxf(count * seconds_per_character, 0.01))
	await tween.finished


## Fades the words away.
func fade_out() -> void:
	var tween := create_tween()
	tween.tween_property(self, ^"modulate:a", 0.0, fade_duration)
	await tween.finished


func _on_boiled() -> void:
	position = _rest + Vector2(0.0, sin(Ink.time * TAU / bob_period) * bob)
