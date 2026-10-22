@tool
class_name SwimmingCar
extends InkDrawing
## A doodle: a car that would honestly rather be swimming. A small blue car in side profile, facing
## left, with a blue wash, two paper windows and two ink wheels, bobbing nose up in the water: one wave
## runs behind it, one across it at the waterline, where its wheels go under, and a shorter one beneath,
## and a little splash of drops flies up in front of its nose. Its origin is the ground under its middle.

## How big the car is drawn, as a multiple of its natural size. The water stays the same.
@export_range(0.2, 3.0, 0.01) var car_scale := 1.22:
	set(value):
		car_scale = value
		queue_redraw()
## Palette role of the car and the water.
@export var role := &"blue":
	set(value):
		role = value
		queue_redraw()
## How strongly the car's and the drops' wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()
## How far the car tips its nose up as it bobs, in degrees.
@export_range(-30.0, 30.0, 0.5) var bob_tilt := 4.0:
	set(value):
		bob_tilt = value
		queue_redraw()
## How high the bottoms of its wheels float, from the ground.
@export_range(0.0, 120.0, 0.5) var float_height := 12.0:
	set(value):
		float_height = value
		queue_redraw()

## The car's outline at natural size, standing on its own wheels' feet: from under its nose, up over
## the bonnet, the windscreen, the roof and the rear window, down the boot and back along its sill.
const _BODY := [Vector2(-104.0, -30.0), Vector2(-110.0, -48.0), Vector2(-100.0, -66.0), Vector2(-76.0, -72.0),
		Vector2(-48.0, -76.0), Vector2(-34.0, -104.0), Vector2(-18.0, -122.0), Vector2(16.0, -126.0),
		Vector2(46.0, -120.0), Vector2(64.0, -98.0), Vector2(78.0, -80.0), Vector2(100.0, -74.0),
		Vector2(110.0, -58.0), Vector2(108.0, -36.0), Vector2(80.0, -28.0), Vector2(-80.0, -28.0)]
## The two windows' corners, front then back.
const _WINDOWS := [[Vector2(-30.0, -82.0), Vector2(-16.0, -110.0), Vector2(10.0, -114.0), Vector2(10.0, -82.0)],
		[Vector2(22.0, -82.0), Vector2(22.0, -114.0), Vector2(42.0, -110.0), Vector2(58.0, -84.0)]]
## The seam at the back of the door, and the door's handle.
const _DOOR := [[Vector2(16.0, -82.0), Vector2(16.0, -36.0)], [Vector2(24.0, -70.0), Vector2(34.0, -70.0)]]
## The middles of the two wheels, their radius and the radius of each hub.
const _WHEELS := [Vector2(-62.0, -22.0), Vector2(62.0, -22.0)]
const _WHEEL_RADIUS := 22.0
const _HUB_RADIUS := 7.0
## How far a wheel's rim runs on under the waterline, so the wave's line covers its ends.
const _DIP := 2.0
## The wave behind the car, peeking out either side of it.
const _BACK_WAVE := [Vector2(-172.0, -46.0), Vector2(-152.0, -54.0), Vector2(-132.0, -46.0), Vector2(-112.0, -54.0),
		Vector2(0.0, -52.0), Vector2(112.0, -54.0), Vector2(132.0, -46.0), Vector2(152.0, -54.0), Vector2(172.0, -46.0)]
## The wave across the car at the waterline, left to right.
const _WATERLINE := [Vector2(-176.0, -26.0), Vector2(-154.0, -36.0), Vector2(-132.0, -26.0), Vector2(-110.0, -36.0),
		Vector2(-88.0, -26.0), Vector2(-66.0, -36.0), Vector2(-44.0, -26.0), Vector2(-22.0, -36.0), Vector2(0.0, -26.0),
		Vector2(22.0, -36.0), Vector2(44.0, -26.0), Vector2(66.0, -36.0), Vector2(88.0, -26.0), Vector2(110.0, -36.0),
		Vector2(132.0, -26.0), Vector2(154.0, -36.0), Vector2(176.0, -26.0)]
## The shorter wave under it.
const _LOW_WAVE := [Vector2(-110.0, -2.0), Vector2(-88.0, -10.0), Vector2(-66.0, -2.0), Vector2(-44.0, -10.0),
		Vector2(-22.0, -2.0), Vector2(0.0, -10.0), Vector2(22.0, -2.0), Vector2(44.0, -10.0), Vector2(66.0, -2.0),
		Vector2(88.0, -10.0), Vector2(110.0, -2.0)]
## Where the splash flies up from, at the waterline in front of its nose.
const _SPLASH_FROM := Vector2(-140.0, -38.0)
## Each drop of the splash: the way it flies, in degrees clockwise from straight up, how far its middle
## lands from where the splash starts, and its radius.
const _DROPS := [[-14.0, 42.0, 7.0], [-44.0, 44.0, 6.5], [-74.0, 36.0, 5.0]]
## How far behind a drop's middle its tail ends, as a multiple of its radius.
const _DROP_TAIL := 2.4
## Where a drop's outline passes round its round end, in degrees from the way it flies.
const _DROP_ROUND := [-90.0, -45.0, 0.0, 45.0, 90.0]


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var wash := palette.paper.lerp(color, wash_strength)
	var lines: Array[InkLine] = []
	var waterline := InkBrush.resample_smooth(PackedVector2Array(_WATERLINE), false, spacing)
	lines.append(_wave(_BACK_WAVE, color, spacing))
	var body := InkLine.along(InkBrush.resample_smooth(_car(_BODY), true, spacing), color, 1.0, true)
	body.fill = wash
	lines.append(body)
	for window: Array in _WINDOWS:
		var pane := InkLine.along(InkBrush.resample_polyline(_closed(_car(window)), spacing), color, 0.8, true)
		pane.fill = palette.paper
		lines.append(pane)
	for mark: Array in _DOOR:
		lines.append(InkLine.along(InkBrush.resample_polyline(_car(mark), spacing), color, 0.7))
	for middle: Vector2 in _WHEELS:
		var at := _car([middle])[0]
		var rim := InkBrush.ellipse(at, Vector2.ONE * _WHEEL_RADIUS * car_scale, spacing, -PI * 0.5)
		var dry := _above(rim, waterline)
		# The wheel's paper, cut off at the water, has no line of its own: its rim and the waterline draw its edge.
		var paper := InkLine.along(_down_to(dry, waterline), Color.TRANSPARENT, 1.0, true)
		paper.fill = palette.paper
		lines.append(paper)
		lines.append(InkLine.along(dry, palette.ink, 1.0, dry.size() == rim.size()))
		var hub := InkBrush.ellipse(at, Vector2.ONE * _HUB_RADIUS * car_scale, spacing * 0.5, -PI * 0.5)
		var dry_hub := _above(hub, waterline)
		if dry_hub.size() > 1:
			lines.append(InkLine.along(dry_hub, palette.ink, 0.7, dry_hub.size() == hub.size()))
	lines.append(InkLine.along(waterline, color, 0.9))
	lines.append(_wave(_LOW_WAVE, color, spacing))
	for drop: Array in _DROPS:
		var way := Vector2.UP.rotated(deg_to_rad(drop[0]))
		var middle: Vector2 = _SPLASH_FROM + way * float(drop[1])
		var radius: float = drop[2]
		var outline := PackedVector2Array([middle - way * radius * _DROP_TAIL])
		for turn: float in _DROP_ROUND:
			outline.append(middle + way.rotated(deg_to_rad(turn)) * radius)
		var splash := InkLine.along(InkBrush.resample_smooth(outline, true, spacing * 0.5), color, 0.7, true)
		splash.fill = wash
		lines.append(splash)
	return lines


## A wave line through [param points].
static func _wave(points: Array, color: Color, spacing: float) -> InkLine:
	return InkLine.along(InkBrush.resample_smooth(PackedVector2Array(points), false, spacing), color, 0.8)


## The part of the closed [param loop], which starts at its top and runs clockwise, that is out of the
## water above [param waterline]: one run from where it comes out of the water on the left, over the top,
## to where it goes back in. A loop that is out of the water all round comes back whole.
static func _above(loop: PackedVector2Array, waterline: PackedVector2Array) -> PackedVector2Array:
	var count := loop.size()
	var ahead := 0
	while ahead < count - 1 and _is_dry(loop[ahead + 1], waterline):
		ahead += 1
	var behind := 0
	while behind < count - 1 - ahead and _is_dry(loop[count - 1 - behind], waterline):
		behind += 1
	return loop.slice(count - behind) + loop.slice(0, ahead + 1)


## [param run], out of the water from left to right, closed back along [param waterline] under it.
static func _down_to(run: PackedVector2Array, waterline: PackedVector2Array) -> PackedVector2Array:
	var out := run.duplicate()
	for i in range(waterline.size() - 1, -1, -1):
		if waterline[i].x > run[0].x and waterline[i].x < run[run.size() - 1].x:
			out.append(waterline[i])
	return out


## Whether [param point] is out of the water, or so little under it that the wave's line covers it.
static func _is_dry(point: Vector2, waterline: PackedVector2Array) -> bool:
	for i in range(1, waterline.size()):
		if waterline[i].x >= point.x:
			var a := waterline[i - 1]
			var b := waterline[i]
			return point.y < lerpf(a.y, b.y, inverse_lerp(a.x, b.x, point.x)) + _DIP
	return true


## [param points] of the car at natural size, drawn [member car_scale] times as big, tipped by
## [member bob_tilt] about the middle under it and floated up by [member float_height].
func _car(points: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point: Vector2 in points:
		out.append((point * car_scale).rotated(deg_to_rad(bob_tilt)) + Vector2(0.0, -float_height))
	return out


## [param corners] with the first repeated at the end, to draw them as a closed polyline.
static func _closed(corners: PackedVector2Array) -> PackedVector2Array:
	var out := corners.duplicate()
	out.append(corners[0])
	return out
