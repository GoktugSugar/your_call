@tool
class_name Confetti
extends InkDrawing
## A burst of confetti for a happy moment on The Show: little squares of coloured paper thrown up from a
## spot, tumbling and drifting down as they fade. It frees itself once the last has faded. Its origin is
## the spot they burst from.

## Palette roles the pieces are cut from, in turn.
@export var roles: Array[StringName] = [&"gold", &"sky", &"purple", &"green", &"orange", &"amber"]
## How many pieces.
@export_range(1, 200) var count := 46
## Size of a piece.
@export_range(1.0, 30.0, 0.5) var piece_size := 9.0
## How fast a piece tumbles at most, in radians a second.
@export_range(0.0, 40.0, 0.5) var tumble := 9.0
## How fast the pieces are thrown, slowest and fastest, in pixels a second.
@export var throw_speed := Vector2(260.0, 620.0)
## How wide they spread, either side of straight up, in degrees.
@export_range(0.0, 90.0, 0.5) var spread := 55.0
## How hard they fall, in pixels a second each second.
@export_range(0.0, 3000.0, 10.0) var gravity := 900.0
## How much the air slows them, each second.
@export_range(0.0, 10.0, 0.05) var drag := 1.4
## Seconds a piece lives before it has faded away.
@export_range(0.1, 10.0, 0.05) var life := 2.2
## Seed for how they scatter. Zero scatters them fresh each burst.
@export var scatter_seed := 0

var _places := PackedVector2Array()
var _speeds := PackedVector2Array()
var _spins := PackedFloat32Array()
var _angles := PackedFloat32Array()
var _age := 0.0


func _ready() -> void:
	super._ready()
	set_process(false)


## Throws the pieces up.
func burst() -> void:
	var rng := RandomNumberGenerator.new()
	if scatter_seed != 0:
		rng.seed = scatter_seed
	else:
		rng.randomize()
	_places.clear()
	_speeds.clear()
	_spins.clear()
	_angles.clear()
	for i in count:
		var angle := deg_to_rad(-90.0 + rng.randf_range(-spread, spread))
		_places.append(Vector2.ZERO)
		_speeds.append(Vector2.from_angle(angle) * rng.randf_range(throw_speed.x, throw_speed.y))
		_spins.append(rng.randf_range(-tumble, tumble))
		_angles.append(rng.randf() * TAU)
	_age = 0.0
	set_process(true)


func _process(delta: float) -> void:
	_age += delta
	for i in _places.size():
		_speeds[i] = _speeds[i] * maxf(1.0 - drag * delta, 0.0) + Vector2(0.0, gravity * delta)
		_places[i] += _speeds[i] * delta
		_angles[i] += _spins[i] * delta
	modulate.a = clampf(1.0 - _age / life, 0.0, 1.0)
	queue_redraw()
	if _age >= life:
		queue_free()


func _build_lines(_style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var lines: Array[InkLine] = []
	if roles.is_empty():
		return lines
	for i in _places.size():
		var color := palette.color(roles[i % roles.size()])
		var corners := PackedVector2Array()
		for corner in 4:
			corners.append(_places[i] + Vector2.from_angle(_angles[i] + corner * PI * 0.5) * piece_size * sqrt(0.5))
		var piece := InkLine.along(corners, color, 0.4, true)
		piece.fill = color
		lines.append(piece)
	return lines
