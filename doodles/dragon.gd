@tool
class_name Dragon
extends InkDrawing
## A doodle: the dragon the whole campaign was built around. A big dragon standing side on on all four
## feet and facing left, unlike the little pet one: two bat wings raised high off its back, the far one
## peeking out ahead of the near one; a long neck rising up and forward with spines down its back and
## plates across its throat; a horned head with a closed mouth, a nostril and one dot eye; and a tail
## that sweeps down to the ground behind it and curls up at its end, with spines along it. Its line is
## red with a light red wash, a stronger one on its far wing and legs, which stand back in its shade,
## and each near foot has three ink claws. The whole of it is set so it stands centred over its origin,
## the ground under its middle.

## How big the dragon is drawn, as a multiple of its natural size.
@export_range(0.2, 3.0, 0.01) var dragon_scale := 1.0:
	set(value):
		dragon_scale = value
		queue_redraw()
## Palette role of its line.
@export var role := &"red":
	set(value):
		role = value
		queue_redraw()
## Palette role of its claws.
@export var claw_role := &"ink":
	set(value):
		claw_role = value
		queue_redraw()
## How strongly its wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.35:
	set(value):
		wash_strength = value
		queue_redraw()
## How strongly the wash on its far wing and far legs takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var far_wash := 0.5:
	set(value):
		far_wash = value
		queue_redraw()
## Radius of the dot eye.
@export_range(0.5, 10.0, 0.1) var eye_radius := 4.0:
	set(value):
		eye_radius = value
		queue_redraw()

## The near wing at natural size, raised off the back, in smooth runs that meet at the tips of its
## fingers: up the leading edge from its root to the wrist and out to the first tip, along a scallop of
## membrane to each tip after it, back along the last scallop to the back, and along the back, which the
## body hides.
const _WING := [
	[Vector2(-14.0, -128.0), Vector2(-10.0, -166.0), Vector2(4.0, -200.0), Vector2(18.0, -218.0), Vector2(36.0, -228.0)],
	[Vector2(36.0, -228.0), Vector2(54.0, -214.0), Vector2(100.0, -210.0)],
	[Vector2(100.0, -210.0), Vector2(99.0, -188.0), Vector2(128.0, -164.0)],
	[Vector2(128.0, -164.0), Vector2(76.0, -152.0), Vector2(44.0, -128.0)],
	[Vector2(44.0, -128.0), Vector2(14.0, -134.0), Vector2(-14.0, -128.0)],
]
## The near wing's finger bones, from its wrist out to the tips between its scallops.
const _FINGERS := [[Vector2(4.0, -200.0), Vector2(100.0, -210.0)], [Vector2(4.0, -200.0), Vector2(128.0, -164.0)]]
## The far wing is the same wing turned forward about its root, in degrees, and drawn a little smaller,
## so its tips fan out past the near wing's leading edge and over its first scallop.
const _FAR_WING_TURN := -12.0
const _FAR_WING_SIZE := 0.9
## The middle of the tail, from its root inside the rump down to the ground and up into its curl.
const _TAIL := [Vector2(66.0, -88.0), Vector2(94.0, -74.0), Vector2(112.0, -54.0), Vector2(121.0, -30.0),
		Vector2(131.0, -13.0), Vector2(145.0, -8.0), Vector2(156.0, -18.0), Vector2(156.0, -35.0),
		Vector2(145.0, -41.0), Vector2(138.0, -31.0)]
## Width of the tail at its root. It narrows to a point at the end of its curl.
const _TAIL_WIDTH := 36.0
## The middle of the neck, from its root inside the shoulders up and forward to the head.
const _NECK := [Vector2(-40.0, -112.0), Vector2(-56.0, -134.0), Vector2(-70.0, -156.0), Vector2(-82.0, -172.0),
		Vector2(-92.0, -184.0)]
## Width of the neck at its root and where the head takes it.
const _NECK_WIDTHS := Vector2(44.0, 26.0)
## The spines along the back of the neck and the top of the tail: how far along each one stands, as a
## fraction of the neck or tail, and how tall it is.
const _NECK_SPINES := [Vector2(0.3, 12.0), Vector2(0.55, 11.0), Vector2(0.8, 10.0)]
const _TAIL_SPINES := [Vector2(0.14, 13.0), Vector2(0.3, 11.0), Vector2(0.46, 9.0)]
## How far a spine's foot reaches into the neck or tail, so its outline covers it.
const _SPINE_FOOT := 4.0
## How far along the neck each plate crosses its throat, as a fraction of the neck, and how far in each
## one reaches, as a fraction of the neck's width there.
const _PLATES := [0.22, 0.42, 0.62, 0.82]
const _PLATE_REACH := 0.4
## The body, from the front of its chest up over its back, round its rump and back along its belly.
const _BODY := [Vector2(-70.0, -92.0), Vector2(-62.0, -120.0), Vector2(-38.0, -136.0), Vector2(0.0, -140.0),
		Vector2(40.0, -136.0), Vector2(72.0, -122.0), Vector2(90.0, -96.0), Vector2(84.0, -66.0), Vector2(60.0, -48.0),
		Vector2(22.0, -40.0), Vector2(-20.0, -42.0), Vector2(-52.0, -52.0), Vector2(-68.0, -70.0)]
## The head, from the back of the skull over the brow and along the snout to the nose, and back under
## the jaw to the throat.
const _HEAD := [Vector2(-80.0, -186.0), Vector2(-86.0, -204.0), Vector2(-106.0, -212.0), Vector2(-120.0, -208.0),
		Vector2(-138.0, -202.0), Vector2(-154.0, -194.0), Vector2(-159.0, -184.0), Vector2(-152.0, -175.0),
		Vector2(-132.0, -170.0), Vector2(-106.0, -166.0), Vector2(-86.0, -172.0)]
## Each horn: its middle, from its root in the skull sweeping back to its tip, and its width at the root.
const _HORNS := [
	[[Vector2(-96.0, -206.0), Vector2(-84.0, -214.0), Vector2(-70.0, -220.0), Vector2(-56.0, -222.0)], 12.0],
	[[Vector2(-90.0, -199.0), Vector2(-78.0, -204.0), Vector2(-64.0, -206.0), Vector2(-52.0, -204.0)], 10.0],
]
## The closed mouth along the snout, the nostril and its radius, and the eye.
const _MOUTH := [Vector2(-153.0, -180.0), Vector2(-139.0, -179.0), Vector2(-126.0, -180.0)]
const _NOSTRIL := Vector2(-148.0, -190.0)
const _NOSTRIL_RADIUS := 2.4
const _EYE := Vector2(-112.0, -196.0)
## The near hind leg, bent the way a dragon's is: from the top of the thigh at the front, back over the
## hip, down the back of the thigh to the hock, down to the heel, forward along the foot to its toes,
## and back up the front of the shin, past the knee and up the thigh.
const _HIND_LEG := [Vector2(48.0, -104.0), Vector2(80.0, -106.0), Vector2(94.0, -84.0), Vector2(90.0, -58.0),
		Vector2(80.0, -38.0), Vector2(78.0, -18.0), Vector2(84.0, -5.0), Vector2(80.0, 0.0), Vector2(36.0, 0.0),
		Vector2(32.0, -7.0), Vector2(48.0, -13.0), Vector2(58.0, -22.0), Vector2(56.0, -40.0), Vector2(40.0, -58.0),
		Vector2(34.0, -82.0)]
## The near front leg, from the front of the shoulder back across it, down the back of the leg past the
## elbow to the heel, forward along the foot to its toes, and back up the front.
const _FRONT_LEG := [Vector2(-66.0, -96.0), Vector2(-34.0, -102.0), Vector2(-28.0, -76.0), Vector2(-32.0, -52.0),
		Vector2(-38.0, -30.0), Vector2(-36.0, -12.0), Vector2(-30.0, -4.0), Vector2(-34.0, 0.0), Vector2(-80.0, 0.0),
		Vector2(-84.0, -7.0), Vector2(-66.0, -14.0), Vector2(-58.0, -30.0), Vector2(-56.0, -54.0), Vector2(-62.0, -76.0)]
## How far each far leg stands from its near one, a step apart and a little up the page.
const _FAR_HIND := Vector2(-24.0, -3.0)
const _FAR_FRONT := Vector2(22.0, -3.0)
## The claws on each near foot, each from its root in the toes out to its point: the hind foot's, then
## the front foot's.
const _CLAWS := [[[Vector2(36.0, -2.0), Vector2(26.0, -1.0)], [Vector2(36.0, -7.0), Vector2(27.0, -8.0)],
				[Vector2(42.0, -11.0), Vector2(34.0, -15.0)]],
		[[Vector2(-78.0, -2.0), Vector2(-88.0, -1.0)], [Vector2(-79.0, -7.0), Vector2(-88.0, -8.0)],
				[Vector2(-74.0, -12.0), Vector2(-82.0, -15.0)]]]
## Widths of the finger bones, the throat plates, the mouth and the claws, as multiples of the drawing's
## line width.
const _FINGER_LINE := 0.7
const _PLATE_LINE := 0.6
const _MOUTH_LINE := 0.7
const _CLAW_LINE := 0.7


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var wash := palette.paper.lerp(color, wash_strength)
	var shade := palette.paper.lerp(color, far_wash)
	var lines: Array[InkLine] = []
	# Back to front: the far wing, the near wing, the far legs, the tail and its spines, the horns, the
	# neck with its spines and plates, the head, then the body over the roots of all of them, and the
	# near legs in front.
	var wing := _runs(_WING, spacing)
	var wing_root := wing[0]
	var far := Transform2D(deg_to_rad(_FAR_WING_TURN), wing_root).scaled_local(Vector2.ONE * _FAR_WING_SIZE) \
			* Transform2D(0.0, -wing_root)
	lines.append(_washed(far * wing, color, shade))
	lines.append(_washed(wing, color, wash))
	for finger: Array in _FINGERS:
		lines.append(InkLine.along(InkBrush.resample_polyline(_placed(finger), spacing), color, _FINGER_LINE))
	for far_leg: Array in [[_HIND_LEG, _FAR_HIND], [_FRONT_LEG, _FAR_FRONT]]:
		var offset: Vector2 = far_leg[1]
		var step := Transform2D(0.0, offset * dragon_scale)
		lines.append(_washed(step * InkBrush.resample_smooth(_placed(far_leg[0]), true, spacing), color, shade))
	var tail := InkBrush.resample_smooth(_placed(_TAIL), false, spacing)
	lines.append_array(_spines(tail, _TAIL_SPINES, Vector2(_TAIL_WIDTH, 0.0) * dragon_scale, color, wash, spacing))
	lines.append(_washed(_tapered(tail, Vector2(_TAIL_WIDTH, 0.0) * dragon_scale), color, wash))
	for horn: Array in _HORNS:
		var spine := InkBrush.resample_smooth(_placed(horn[0]), false, spacing * 0.5)
		var horn_width: float = horn[1]
		lines.append(_washed(_tapered(spine, Vector2(horn_width, 0.0) * dragon_scale), color, wash))
	var neck := InkBrush.resample_smooth(_placed(_NECK), false, spacing)
	var neck_widths := _NECK_WIDTHS * dragon_scale
	lines.append_array(_spines(neck, _NECK_SPINES, neck_widths, color, wash, spacing))
	lines.append(_washed(_tapered(neck, neck_widths), color, wash))
	for share: float in _PLATES:
		var at := _at(neck, share)
		var half := _half_width(neck_widths, share)
		var throat := _down_side(neck, at) * half
		var plate := PackedVector2Array([neck[at] + throat, neck[at] + throat * (1.0 - 2.0 * _PLATE_REACH)])
		lines.append(InkLine.along(InkBrush.resample_polyline(plate, spacing * 0.5), color, _PLATE_LINE))
	lines.append(_washed(InkBrush.resample_smooth(_placed(_HEAD), true, spacing), color, wash))
	lines.append(InkLine.along(InkBrush.resample_smooth(_placed(_MOUTH), false, spacing), color, _MOUTH_LINE))
	lines.append(InkLine.dot(_NOSTRIL * dragon_scale, _NOSTRIL_RADIUS, palette.ink))
	lines.append(InkLine.dot(_EYE * dragon_scale, eye_radius, palette.ink))
	lines.append(_washed(InkBrush.resample_smooth(_placed(_BODY), true, spacing), color, wash))
	lines.append(_washed(InkBrush.resample_smooth(_placed(_HIND_LEG), true, spacing), color, wash))
	lines.append(_washed(InkBrush.resample_smooth(_placed(_FRONT_LEG), true, spacing), color, wash))
	var claw_color := palette.color(claw_role)
	for foot: Array in _CLAWS:
		for claw: Array in foot:
			lines.append(InkLine.along(InkBrush.resample_polyline(_placed(claw), spacing * 0.5), claw_color, _CLAW_LINE))
	# Set the whole of it centred over the origin, standing on the ground.
	var box := Rect2(lines[0].path[0], Vector2.ZERO)
	for line in lines:
		for point in line.path:
			box = box.expand(point)
	var place := Transform2D(0.0, Vector2(-box.get_center().x, -box.end.y))
	for line in lines:
		line.path = place * line.path
	return lines


## Spines standing up off the side of the [param spine] that faces up, each where and as tall as
## [param spines] says, on a band [param widths] wide at its root and its end.
func _spines(spine: PackedVector2Array, spines: Array, widths: Vector2, color: Color, wash: Color,
		spacing: float) -> Array[InkLine]:
	var out: Array[InkLine] = []
	for spike: Vector2 in spines:
		var at := _at(spine, spike.x)
		var up := -_down_side(spine, at)
		var along := (spine[mini(at + 1, spine.size() - 1)] - spine[maxi(at - 1, 0)]).normalized()
		var edge := spine[at] + up * (_half_width(widths, spike.x) - _SPINE_FOOT * dragon_scale)
		var tall := spike.y * dragon_scale
		var corners := PackedVector2Array([edge - along * tall * 0.5, edge + up * (tall + _SPINE_FOOT * dragon_scale),
				edge + along * tall * 0.5, edge - along * tall * 0.5])
		out.append(_washed(InkBrush.resample_polyline(corners, spacing * 0.5), color, wash, 0.8))
	return out


## The index of the point [param share] of the way along [param spine].
static func _at(spine: PackedVector2Array, share: float) -> int:
	return clampi(roundi(share * (spine.size() - 1)), 0, spine.size() - 1)


## Half the width of a band [param widths] wide at its root and its end, [param share] of the way along.
static func _half_width(widths: Vector2, share: float) -> float:
	return lerpf(widths.x, widths.y, share) * 0.5


## Which way is across [param spine] at the point [param at], on the side that faces down the page.
static func _down_side(spine: PackedVector2Array, at: int) -> Vector2:
	var along := spine[mini(at + 1, spine.size() - 1)] - spine[maxi(at - 1, 0)]
	var across := along.normalized().orthogonal()
	return across if across.y >= 0.0 else -across


## A closed outline round [param spine], [code]widths.x[/code] wide at its start and narrowing evenly to
## [code]widths.y[/code] at its end: out along one side and back along the other.
static func _tapered(spine: PackedVector2Array, widths: Vector2) -> PackedVector2Array:
	var count := spine.size()
	var near := PackedVector2Array()
	var far := PackedVector2Array()
	for i in count:
		var along := spine[mini(i + 1, count - 1)] - spine[maxi(i - 1, 0)]
		var across := along.normalized().orthogonal() * _half_width(widths, float(i) / (count - 1))
		near.append(spine[i] + across)
		far.append(spine[i] - across)
	far.reverse()
	near.append_array(far)
	return near


## The closed outline through [param runs] at natural size: smooth runs that meet in sharp corners,
## each starting where the one before it ends.
func _runs(runs: Array, spacing: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for run: Array in runs:
		var part := InkBrush.resample_smooth(_placed(run), false, spacing)
		out.append_array(part if out.is_empty() else part.slice(1))
	return out


## [param points] at natural size, drawn [member dragon_scale] times as big.
func _placed(points: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point: Vector2 in points:
		out.append(point * dragon_scale)
	return out


## A closed line along [param path] with [param wash] inside it, [param width] times the drawing's
## line width.
static func _washed(path: PackedVector2Array, color: Color, wash: Color, width := 1.0) -> InkLine:
	var line := InkLine.along(path, color, width, true)
	line.fill = wash
	return line
