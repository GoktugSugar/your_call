@tool
class_name DriftingMemory
extends InkDrawing
## A doodle: someone you hurt forgets you did it. The head the head doodles share ([ProfileHead]), in
## profile and facing right, in sky with a sky wash, and the memory, a tiny washed cloud, drifting away out
## of the back of the head along a dotted trail that starts inside the skull, where the memory was. The
## head stands right of its origin, so that it and its cloud together are centred on it. Its origin is the
## ground under them.

## How big the head and its memory are drawn, as a multiple of their natural size.
@export_range(0.2, 3.0, 0.01) var head_scale := 1.0:
	set(value):
		head_scale = value
		queue_redraw()
## Palette role of the head, the trail and the cloud.
@export var role := &"sky":
	set(value):
		role = value
		queue_redraw()
## How strongly each wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()
## Radius of the dot eye.
@export_range(0.5, 10.0, 0.1) var eye_radius := 4.0:
	set(value):
		eye_radius = value
		queue_redraw()
## Radius of each dot of the trail.
@export_range(0.5, 10.0, 0.1) var trail_dot := 3.4:
	set(value):
		trail_dot = value
		queue_redraw()
## Distance between the trail's dots, at natural size.
@export_range(4.0, 60.0, 0.5) var trail_gap := 14.0:
	set(value):
		trail_gap = value
		queue_redraw()

## The trail at natural size, from the back of the skull ([constant ProfileHead.BACK]): from inside the
## skull, where the memory was, back out through the back of the head and up to under the cloud. It is
## smoothed, and its dots go along it.
const _TRAIL := [Vector2(46.0, -14.0), Vector2(24.0, -5.0), Vector2(2.0, -4.0), Vector2(-18.0, -9.0),
		Vector2(-36.0, -22.0), Vector2(-50.0, -42.0)]
## The cloud's middle at natural size, from the back of the skull.
const _CLOUD_MIDDLE := Vector2(-84.0, -66.0)
## The cloud at natural size, around its middle: the corners between its bumps, from its bottom left up
## over its top and down to its bottom right. A bump runs from each corner to the next, and the last runs
## back along its belly.
const _CLOUD := [Vector2(-34.0, 10.0), Vector2(-30.0, -4.0), Vector2(-14.0, -14.0), Vector2(8.0, -18.0),
		Vector2(26.0, -8.0), Vector2(34.0, 10.0)]
## How far each of the cloud's bumps bulges out, in the order of its corners; the last is its belly.
const _CLOUD_BULGE := [7.0, 9.0, 11.0, 10.0, 8.0, 3.0]
## Points along each bump of the cloud, before it is resampled.
const _BUMP_POINTS := 10
## How far the head and its cloud are moved, so that together they are centred on the origin.
const _SHIFT := Vector2(62.0, 0.0)


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var wash := palette.paper.lerp(color, wash_strength)
	var lines := ProfileHead.lines(_SHIFT, head_scale, color, wash, eye_radius, palette.ink, spacing)
	var back := ProfileHead.place(ProfileHead.BACK, _SHIFT, head_scale)
	var trail := InkBrush.resample_smooth(ProfileHead.placed(_TRAIL, back, head_scale), false, 1.0)
	for spot in _every(trail, trail_gap * head_scale):
		lines.append(InkLine.dot(spot, trail_dot, color))
	var cloud := InkLine.along(_cloud(back + _CLOUD_MIDDLE * head_scale, spacing), color, 0.9, true)
	cloud.fill = wash
	lines.append(cloud)
	return lines


## The cloud's closed outline around [param middle]: a bump from each corner to the next, all the way round.
func _cloud(middle: Vector2, spacing: float) -> PackedVector2Array:
	var path := PackedVector2Array()
	for i in _CLOUD.size():
		var from: Vector2 = middle + _CLOUD[i] * head_scale
		var to: Vector2 = middle + _CLOUD[(i + 1) % _CLOUD.size()] * head_scale
		var out := (to - from).orthogonal().normalized() * float(_CLOUD_BULGE[i]) * head_scale
		for k in _BUMP_POINTS:
			var t := float(k) / _BUMP_POINTS
			path.append(from.lerp(to, t) + out * sin(PI * t))
	path.append(path[0])
	return InkBrush.resample_polyline(path, spacing)


## Points every [param gap] along [param path], from its start.
static func _every(path: PackedVector2Array, gap: float) -> PackedVector2Array:
	var out := PackedVector2Array([path[0]])
	var travelled := 0.0
	var next := gap
	for i in range(1, path.size()):
		var length := path[i - 1].distance_to(path[i])
		while travelled + length >= next:
			out.append(path[i - 1].lerp(path[i], (next - travelled) / length))
			next += gap
		travelled += length
	return out
