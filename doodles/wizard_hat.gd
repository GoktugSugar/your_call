@tool
class_name WizardHat
extends InkDrawing
## A doodle: the wizard. A tall pointed wizard's hat seen a little from above, resting on its wide brim:
## the cone rises from a band round its foot and bends over near the top, so its tip droops to the
## right. Its line is purple, with a purple wash in the brim and the cone and a stronger one in the band,
## and a few small stars fleck the cone, outlined in purple with paper inside. Its origin is the ground
## under its middle.

## How big the hat is drawn, as a multiple of its natural size.
@export_range(0.2, 3.0, 0.01) var hat_scale := 1.0:
	set(value):
		hat_scale = value
		queue_redraw()
## Palette role of every line.
@export var role := &"purple":
	set(value):
		role = value
		queue_redraw()
## How strongly the brim's and the cone's wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()
## How strongly the band's wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var band_wash := 0.75:
	set(value):
		band_wash = value
		queue_redraw()
## Height of the band round the foot of the cone, at natural size.
@export_range(0.0, 80.0, 0.5) var band_height := 20.0:
	set(value):
		band_height = value
		queue_redraw()

## The brim at natural size: the middle of its ellipse and its half width and height.
const _BRIM := [Vector2(0.0, -22.0), Vector2(124.0, 22.0)]
## The middle of the cone at natural size, from the middle of its foot up to where it bends over and
## out to its drooping tip.
const _SPINE := [Vector2(0.0, -30.0), Vector2(0.0, -100.0), Vector2(6.0, -150.0), Vector2(18.0, -182.0),
		Vector2(38.0, -204.0), Vector2(62.0, -212.0), Vector2(80.0, -204.0)]
## The half width and half height of the ellipse round the cone's foot, whose front half is the cone's
## lower edge. Higher up, the cone's ellipses narrow with it.
const _FOOT_RADII := Vector2(64.0, 12.0)
## How far the band stands proud of the cone, all round, so its wash covers the cone's own edge there.
const _BAND_PROUD := 3.0
## Each star on the cone: its middle, its outer radius and how far it is turned, in degrees.
const _STARS := [[Vector2(-24.0, -84.0), 15.5, -8.0], [Vector2(24.0, -114.0), 12.5, 12.0],
		[Vector2(-2.0, -150.0), 10.0, -4.0]]
## How many points each star has, and its inner radius as a fraction of its outer one.
const _STAR_POINTS := 5
const _STAR_WAIST := 0.45
## Width of the stars' lines, as a multiple of the drawing's line width.
const _STAR_LINE := 0.6


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var wash := palette.paper.lerp(color, wash_strength)
	var lines: Array[InkLine] = []
	var brim_middle: Vector2 = _BRIM[0]
	var brim_radii: Vector2 = _BRIM[1]
	lines.append(_washed(InkBrush.ellipse(brim_middle * hat_scale, brim_radii * hat_scale, spacing, PI), color, wash))
	# The cone stands on the brim: up its left side, round its tip, down its right side and back along
	# the front of its foot.
	var spine := InkBrush.resample_smooth(_scaled(_SPINE), false, spacing)
	var foot := spine[0]
	var radii := _FOOT_RADII * hat_scale
	var cone := _tapered(spine, radii.x * 2.0)
	cone.append_array(_front(foot, radii, spacing).slice(1, -1))
	lines.append(_washed(cone, color, wash))
	# The band stands a little proud of the cone all round, so it covers the cone's edge where they meet.
	var length := InkBrush.path_length(spine)
	var rise := band_height * hat_scale
	if rise > 0.0 and length > 0.0:
		var narrowing := 1.0 - rise / length
		var proud := Vector2.ONE * _BAND_PROUD * hat_scale
		var band := _front(foot, radii + proud, spacing)
		band.reverse()
		band.append_array(_front(foot + Vector2(0.0, -rise), radii * narrowing + proud, spacing))
		lines.append(_washed(band, color, palette.paper.lerp(color, band_wash)))
	for star: Array in _STARS:
		var middle: Vector2 = star[0]
		var radius: float = star[1]
		var turn: float = star[2]
		var outline := _star(middle * hat_scale, radius * hat_scale, deg_to_rad(turn))
		var line := InkLine.along(InkBrush.resample_polyline(outline, spacing * 0.5), color, _STAR_LINE, true)
		line.fill = palette.paper
		lines.append(line)
	return lines


## The front half of the ellipse round [param middle] with [param radii], from its right end round
## under the middle to its left end.
static func _front(middle: Vector2, radii: Vector2, spacing: float) -> PackedVector2Array:
	var steps := maxi(2, ceili(PI * sqrt((radii.x * radii.x + radii.y * radii.y) * 0.5) / spacing))
	var out := PackedVector2Array()
	for k in steps + 1:
		var angle := PI * k / steps
		out.append(middle + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	return out


## A closed outline round [param spine], [param root_width] wide at its start and narrowing evenly to a
## point at its end: up its left side and back down its right.
static func _tapered(spine: PackedVector2Array, root_width: float) -> PackedVector2Array:
	var count := spine.size()
	var near := PackedVector2Array()
	var far := PackedVector2Array()
	for i in count:
		var along := spine[mini(i + 1, count - 1)] - spine[maxi(i - 1, 0)]
		var across := along.normalized().orthogonal() * root_width * 0.5 * (1.0 - float(i) / (count - 1))
		near.append(spine[i] + across)
		far.append(spine[i] - across)
	far.reverse()
	near.append_array(far.slice(1))
	return near


## A star of [constant _STAR_POINTS] points round [param middle], [param radius] out to its points and
## turned [param turn] radians, as a closed polyline from its top point.
static func _star(middle: Vector2, radius: float, turn: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for k in _STAR_POINTS * 2 + 1:
		var reach := radius if k % 2 == 0 else radius * _STAR_WAIST
		out.append(middle + Vector2.UP.rotated(turn + PI * k / _STAR_POINTS) * reach)
	return out


func _scaled(points: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point: Vector2 in points:
		out.append(point * hat_scale)
	return out


## A closed line along [param path] with [param wash] inside it.
static func _washed(path: PackedVector2Array, color: Color, wash: Color) -> InkLine:
	var line := InkLine.along(path, color, 1.0, true)
	line.fill = wash
	return line
