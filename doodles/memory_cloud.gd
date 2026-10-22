@tool
class_name MemoryCloud
extends InkDrawing
## A doodle: your single worst memory, lifted out. A bumpy purple thought cloud with a purple wash, a
## tangled ink scribble knotted up inside it, and two small purple bubbles trailing down from it
## towards the ground. Its origin is the ground under it.

## How big the cloud and its bubbles are drawn, as a multiple of their natural size.
@export_range(0.2, 3.0, 0.01) var cloud_scale := 1.0:
	set(value):
		cloud_scale = value
		queue_redraw()
## How far each bump of the cloud bulges out, as a fraction of its width.
@export_range(0.0, 1.0, 0.01) var bump_bulge := 0.36:
	set(value):
		bump_bulge = value
		queue_redraw()
## Palette role of the cloud and its bubbles.
@export var role := &"purple":
	set(value):
		role = value
		queue_redraw()
## Palette role of the scribble inside the cloud.
@export var scribble_role := &"ink":
	set(value):
		scribble_role = value
		queue_redraw()
## How strongly the cloud's and the bubbles' wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()
## Width of the scribble's line, as a multiple of the drawing's line width.
@export_range(0.2, 3.0, 0.05) var scribble_width := 0.7:
	set(value):
		scribble_width = value
		queue_redraw()

## The middle of the cloud at natural size, which its bumps bulge away from.
const _MIDDLE := Vector2(0.0, -150.0)
## The dips between the cloud's bumps at natural size, going round clockwise from its left. A bump
## bulges out between each pair, and between the last and the first.
const _DIPS := [Vector2(-98.0, -150.0), Vector2(-80.0, -178.0), Vector2(-34.0, -194.0), Vector2(22.0, -195.0),
		Vector2(72.0, -180.0), Vector2(98.0, -154.0), Vector2(86.0, -128.0), Vector2(46.0, -108.0),
		Vector2(-16.0, -104.0), Vector2(-72.0, -118.0)]
## The bubbles trailing down from the cloud, biggest first: each one's middle and radius at natural size.
const _BUBBLES := [[Vector2(-52.0, -66.0), 16.0], [Vector2(-76.0, -30.0), 10.0]]
## The scribble is one line looping round and round a middle that wanders about inside the cloud, its
## loops swelling and shrinking as it goes, so it knots up on itself. All at natural size: where its
## wandering middle is centred, how far that wanders across and up, and the radii of a loop across and up.
const _TANGLE_MIDDLE := Vector2(0.0, -150.0)
const _TANGLE_WANDER := Vector2(48.0, 14.0)
const _TANGLE_LOOP := Vector2(24.0, 22.0)
## How many loops the scribble makes.
const _TANGLE_TURNS := 9.5
## How many times, over the whole scribble, its middle wanders across and back, and up and back, and
## how many times its loops swell and shrink.
const _TANGLE_RATES := Vector3(1.0, 2.0, 3.0)
## How much the loops swell and shrink, as a fraction of their size.
const _TANGLE_SWELL := 0.35


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var wash := palette.paper.lerp(color, wash_strength)
	var lines: Array[InkLine] = []
	for bubble: Array in _BUBBLES:
		var middle: Vector2 = bubble[0]
		var radius: float = bubble[1]
		var circle := InkBrush.ellipse(middle * cloud_scale, Vector2.ONE * radius * cloud_scale, spacing, -PI * 0.75)
		lines.append(_washed(circle, color, wash))
	lines.append(_washed(_cloud(spacing), color, wash))
	lines.append(InkLine.along(_tangle(spacing), palette.color(scribble_role), scribble_width))
	return lines


## The cloud's outline: a round bump bulging out between each pair of dips, all the way round.
func _cloud(spacing: float) -> PackedVector2Array:
	var middle := _MIDDLE * cloud_scale
	var path := PackedVector2Array()
	for i in _DIPS.size():
		var from: Vector2 = _DIPS[i] * cloud_scale
		var to: Vector2 = _DIPS[(i + 1) % _DIPS.size()] * cloud_scale
		var out := (to - from).orthogonal().normalized()
		if out.dot((from + to) * 0.5 - middle) < 0.0:
			out = -out
		# A cubic curve whose handles stand out by this much peaks at the bump's bulge.
		var handle := out * from.distance_to(to) * bump_bulge * 4.0 / 3.0
		var steps := maxi(2, ceili(from.distance_to(to) * (1.0 + bump_bulge) / spacing))
		for k in steps:
			path.append(from.bezier_interpolate(from + handle, to + handle, to, float(k) / steps))
	return path


## The scribble: one line looping round a middle that wanders across and up and down inside the cloud.
func _tangle(spacing: float) -> PackedVector2Array:
	var loop := _TANGLE_LOOP * cloud_scale
	var wander := _TANGLE_WANDER * cloud_scale
	var reach := maxf(loop.x, loop.y) * (1.0 + _TANGLE_SWELL)
	var steps := maxi(2, ceili(_TANGLE_TURNS * TAU * reach / spacing))
	var path := PackedVector2Array()
	for k in steps + 1:
		var t := float(k) / steps
		var middle := _TANGLE_MIDDLE * cloud_scale + Vector2(wander.x * sin(TAU * _TANGLE_RATES.x * t),
				wander.y * sin(TAU * _TANGLE_RATES.y * t))
		var swell := 1.0 + _TANGLE_SWELL * sin(TAU * _TANGLE_RATES.z * t)
		var angle := TAU * _TANGLE_TURNS * t
		path.append(middle + Vector2(cos(angle) * loop.x, sin(angle) * loop.y) * swell)
	return path


## A closed line along [param path] with [param wash] inside.
static func _washed(path: PackedVector2Array, color: Color, wash: Color) -> InkLine:
	var line := InkLine.along(path, color, 1.0, true)
	line.fill = wash
	return line
