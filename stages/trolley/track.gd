@tool
class_name Track
extends InkDrawing
## A length of railway in ink: two rails and the sleepers across them, along a smooth path.
## The trolley and the figures find their places along it by distance from its start.

## The points the track runs through, in this node's space. A smooth curve passes through them.
@export var path_points := PackedVector2Array([Vector2.ZERO, Vector2(400.0, 0.0)]):
	set(value):
		path_points = value
		_centerline = PackedVector2Array()
		queue_redraw()
## Distance between the two rails.
@export_range(2.0, 60.0, 0.5) var gauge := 14.0:
	set(value):
		gauge = value
		queue_redraw()
## Distance between sleepers.
@export_range(4.0, 200.0, 0.5) var sleeper_spacing := 30.0:
	set(value):
		sleeper_spacing = value
		queue_redraw()
## How far each sleeper reaches past the rails.
@export_range(0.0, 40.0, 0.5) var sleeper_overhang := 6.0:
	set(value):
		sleeper_overhang = value
		queue_redraw()
## Width of the sleepers, as a multiple of the line width.
@export_range(0.0, 4.0, 0.05) var sleeper_width := 0.7:
	set(value):
		sleeper_width = value
		queue_redraw()
## Length at the start left without sleepers, where this track leaves another.
@export_range(0.0, 400.0, 1.0) var bare_start := 0.0:
	set(value):
		bare_start = value
		queue_redraw()

## Sampling of the centre line used for distances along the track.
const _CENTERLINE_SPACING := 2.0

var _centerline := PackedVector2Array()
var _distances := PackedFloat32Array()


## The track's length along its centre line.
func length() -> float:
	_ensure_centerline()
	return _distances[_distances.size() - 1] if not _distances.is_empty() else 0.0


## The point on the centre line [param distance] along the track, in this node's space.
func point_at(distance: float) -> Vector2:
	_ensure_centerline()
	if _centerline.size() < 2:
		return path_points[0] if not path_points.is_empty() else Vector2.ZERO
	var d := clampf(distance, 0.0, length())
	var i := clampi(_distances.bsearch(d), 1, _distances.size() - 1)
	var span := maxf(_distances[i] - _distances[i - 1], 0.0001)
	return _centerline[i - 1].lerp(_centerline[i], (d - _distances[i - 1]) / span)


## The direction the track runs at [param distance] along it.
func direction_at(distance: float) -> Vector2:
	var step := _CENTERLINE_SPACING * 2.0
	var ahead := point_at(minf(distance + step, length()))
	var behind := point_at(maxf(distance - step, 0.0))
	return (ahead - behind).normalized()


## How far along the track it first reaches [param x] in this node's space, or the end if it never does.
func distance_at_x(x: float) -> float:
	_ensure_centerline()
	for i in range(1, _centerline.size()):
		var a := _centerline[i - 1]
		var b := _centerline[i]
		if (a.x - x) * (b.x - x) <= 0.0 and not is_equal_approx(a.x, b.x):
			return lerpf(_distances[i - 1], _distances[i], (x - a.x) / (b.x - a.x))
	return length()


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	_ensure_centerline()
	var lines: Array[InkLine] = []
	if _centerline.size() < 2:
		return lines
	var rail_a := PackedVector2Array()
	var rail_b := PackedVector2Array()
	var total := length()
	var spacing := style.sample_spacing
	var d := 0.0
	while d <= total:
		var normal := direction_at(d).orthogonal()
		var center := point_at(d)
		rail_a.append(center + normal * gauge * 0.5)
		rail_b.append(center - normal * gauge * 0.5)
		d += spacing
	lines.append(InkLine.along(rail_a, palette.ink))
	lines.append(InkLine.along(rail_b, palette.ink))
	var reach := gauge * 0.5 + sleeper_overhang
	d = bare_start + sleeper_spacing * 0.5
	while d < total - sleeper_spacing * 0.25:
		var normal := direction_at(d).orthogonal()
		var center := point_at(d)
		var sleeper := InkBrush.resample_polyline(PackedVector2Array([center + normal * reach, center - normal * reach]), spacing)
		lines.append(InkLine.along(sleeper, palette.ink, sleeper_width))
		d += sleeper_spacing
	return lines


func _ensure_centerline() -> void:
	if not _centerline.is_empty():
		return
	_centerline = InkBrush.resample_smooth(path_points, false, _CENTERLINE_SPACING)
	_distances.resize(_centerline.size())
	if _centerline.is_empty():
		return
	_distances[0] = 0.0
	for i in range(1, _centerline.size()):
		_distances[i] = _distances[i - 1] + _centerline[i].distance_to(_centerline[i - 1])
