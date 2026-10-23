@tool
class_name Audience
extends InkDrawing
## The studio audience, seen from behind along the foot of the page: rows of heads and shoulders in
## muted ink, filled with paper so a nearer row hides the one behind, in a block either side of where
## the dialogue box floats. They sway a little with the boil, bob all together when they clap, and a
## share of them can stand up out of their seats. Its origin is the top left of the page.

## The blocks of seats, each filled with rows of heads from its top.
@export var blocks: Array[Rect2] = [Rect2(0.0, 950.0, 420.0, 130.0), Rect2(1500.0, 950.0, 420.0, 130.0)]:
	set(value):
		blocks = value
		_seat()
## How many rows each block holds.
@export_range(1, 6) var rows := 2:
	set(value):
		rows = value
		_seat()
## Radius of a head.
@export_range(4.0, 60.0, 0.5) var head_radius := 17.0:
	set(value):
		head_radius = value
		queue_redraw()
## Distance between neighbouring heads in a row.
@export_range(10.0, 200.0, 1.0) var spacing := 48.0:
	set(value):
		spacing = value
		_seat()
## Distance between one row and the next, down the page.
@export_range(10.0, 200.0, 1.0) var row_gap := 46.0:
	set(value):
		row_gap = value
		_seat()
## Half the width of a pair of shoulders, and how far they drop below the head.
@export var shoulders := Vector2(27.0, 30.0):
	set(value):
		shoulders = value
		queue_redraw()
## How far a head sways with the boil, in pixels.
@export_range(0.0, 10.0, 0.1) var sway := 1.6:
	set(value):
		sway = value
		queue_redraw()
## How high a head bobs as its owner claps.
@export_range(0.0, 40.0, 0.5) var clap_bob := 6.0
## How many bobs a second while they clap.
@export_range(0.1, 12.0, 0.1) var clap_rate := 4.5
## How far a head rises when its owner stands up.
@export_range(0.0, 200.0, 1.0) var stand_rise := 34.0
## Seconds the standing takes, from the first to the last on their feet.
@export_range(0.0, 5.0, 0.05) var stand_time := 1.1
## Palette role of the line.
@export var role := &"secondary":
	set(value):
		role = value
		queue_redraw()
## Palette roles of their clothes, washed into their shoulders, taken in turn along the rows. Empty
## dresses them all in paper.
@export var clothes: Array[StringName] = []:
	set(value):
		clothes = value
		queue_redraw()
## How strongly their clothes take their colour over the paper.
@export_range(0.0, 1.0, 0.01) var clothes_wash := 0.45:
	set(value):
		clothes_wash = value
		queue_redraw()
## Seed for who sways which way and who stands first.
@export var crowd_seed := 7

## Where each head sits at rest.
var _seats := PackedVector2Array()
## How far each head has risen out of its seat.
var _risen := PackedFloat32Array()
## Each head's own phase, so they never bob as one.
var _phase := PackedFloat32Array()
var _clapping := 0.0
var _clock := 0.0
## Whether heads are rising or sitting.
var _moving := false


func _ready() -> void:
	super._ready()
	_seat()
	set_process(false)


func _process(delta: float) -> void:
	_clock += delta
	_clapping = maxf(_clapping - delta, 0.0)
	queue_redraw()
	if _clapping <= 0.0 and not _moving:
		set_process(false)


## Claps for [param seconds]: every head bobs on its own beat.
func clap(seconds: float) -> void:
	_clapping = maxf(_clapping, seconds)
	set_process(true)


## Stands up [param share] percent of the audience, one after another, and sits the rest down.
## Returns once they are up.
func stand(share: float) -> void:
	var order := _standing_order()
	var standing := roundi(order.size() * clampf(share / 100.0, 0.0, 1.0))
	var tween := create_tween().set_parallel(true)
	for i in order.size():
		var head := order[i]
		var target := stand_rise if i < standing else 0.0
		var delay := stand_time * i / maxf(order.size(), 1.0) if i < standing else 0.0
		tween.tween_method(_rise.bind(head), _risen[head], target, 0.3).set_delay(delay) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_moving = true
	set_process(true)
	await tween.finished
	_moving = false


## Sits everyone back down.
func sit() -> void:
	await stand(0.0)


## How many people the audience seats.
func seat_count() -> int:
	return _seats.size()


func _rise(amount: float, head: int) -> void:
	_risen[head] = amount


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing_step := style.sample_spacing
	var color := palette.color(role)
	var lines: Array[InkLine] = []
	var variant := InkPainter.current_variant()
	for i in _seats.size():
		var bob := sin(_clock * TAU * clap_rate + _phase[i]) * clap_bob if _clapping > 0.0 else 0.0
		var drift := sin(variant * 2.1 + _phase[i]) * sway
		# A head only moves about as it sways and bobs, so it moves by offset and its ink is laid down
		# again unchanged; rising out of its seat stretches it, so that is in its shape.
		var moved := Vector2(drift, -absf(bob))
		var head := _seats[i] + Vector2(0.0, -_risen[i])
		var body := PackedVector2Array([head + Vector2(-shoulders.x, shoulders.y + _risen[i] + head_radius),
				head + Vector2(-shoulders.x * 0.85, head_radius * 0.9), head + Vector2(0.0, head_radius * 0.55),
				head + Vector2(shoulders.x * 0.85, head_radius * 0.9),
				head + Vector2(shoulders.x, shoulders.y + _risen[i] + head_radius)])
		var torso := InkLine.along(InkBrush.resample_smooth(body, false, spacing_step), color, 0.8)
		torso.offset = moved
		torso.fill = palette.paper
		if not clothes.is_empty():
			torso.fill = palette.paper.lerp(palette.color(clothes[(i * 7) % clothes.size()]), clothes_wash)
		lines.append(torso)
		var skull := InkLine.along(InkBrush.ellipse(head, Vector2.ONE * head_radius, spacing_step), color, 0.8, true)
		skull.offset = moved
		skull.fill = palette.paper
		lines.append(skull)
	return lines


## Seats the audience: rows of heads across each block, back rows first so nearer ones are drawn over them.
func _seat() -> void:
	_seats.clear()
	for row in rows:
		for block in blocks:
			var offset := spacing * 0.5 if row % 2 == 1 else 0.0
			var x := block.position.x + head_radius + offset
			while x <= block.end.x - head_radius:
				_seats.append(Vector2(x, block.position.y + head_radius + row * row_gap))
				x += spacing
	_risen.resize(_seats.size())
	_risen.fill(0.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = crowd_seed
	_phase.resize(_seats.size())
	for i in _seats.size():
		_phase[i] = rng.randf() * TAU
	queue_redraw()


## The order heads stand up in: a fixed shuffle, so the same share always stands the same heads.
func _standing_order() -> PackedInt32Array:
	var order := PackedInt32Array()
	for i in _seats.size():
		order.append(i)
	var rng := RandomNumberGenerator.new()
	rng.seed = crowd_seed
	for i in range(order.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap := order[i]
		order[i] = order[j]
		order[j] = swap
	return order
