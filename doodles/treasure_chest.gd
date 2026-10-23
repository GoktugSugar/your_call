@tool
class_name TreasureChest
extends InkDrawing
## A doodle: the hoard. An open treasure chest seen from the front, its lid thrown back behind it with
## its inside in shadow inside a rim, and a heap of gold coins rising over its rim, the top of the heap
## bumpy with coins and a few more lying face up on it. Across the front of the heap rests a black blade,
## a sword with its hilt up on the left and its point down by the rim on the right. The chest has a band
## round its rim, two straps down its front and a lock plate with a keyhole. Its line is gold, with a gold
## wash in the chest, the lid and the heap, a stronger one in its metal, a pale one on the coins' faces
## and the lock plate, and a shadow inside the lid; the sword is drawn in ink with a dark ink wash. The
## whole of it is set so it stands centred over its origin, the ground under its middle.

## How big the chest is drawn, as a multiple of its natural size.
@export_range(0.2, 3.0, 0.01) var chest_scale := 1.0:
	set(value):
		chest_scale = value
		queue_redraw()
## Palette role of the chest and the coins.
@export var role := &"gold":
	set(value):
		role = value
		queue_redraw()
## Palette role of the sword.
@export var blade_role := &"ink":
	set(value):
		blade_role = value
		queue_redraw()
## How strongly the chest's, the lid's and the heap's wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()
## How strongly the band and the straps take the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var metal_wash := 0.65:
	set(value):
		metal_wash = value
		queue_redraw()
## How strongly the coins' faces and the lock plate take the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var face_wash := 0.2:
	set(value):
		face_wash = value
		queue_redraw()
## How dark the inside of the lid is: how far its wash goes from the lid's wash toward the ink.
@export_range(0.0, 1.0, 0.01) var lid_shadow := 0.3:
	set(value):
		lid_shadow = value
		queue_redraw()
## How far in from the lid's edge its rim runs, at natural size.
@export_range(0.0, 40.0, 0.5) var lid_rim := 10.0:
	set(value):
		lid_rim = value
		queue_redraw()
## How dark the sword's wash is, as a share of the way from the paper to its line's colour.
@export_range(0.0, 1.0, 0.01) var blade_darkness := 0.75:
	set(value):
		blade_darkness = value
		queue_redraw()
## How far the sword tips as it lies across the heap, in degrees, its point down.
@export_range(-45.0, 45.0, 0.5) var blade_tilt := 15.0:
	set(value):
		blade_tilt = value
		queue_redraw()

## The lid at natural size, thrown back behind the chest, in smooth runs that meet in its corners: up its
## left side from its hinge, over its rounded top, down its right side and back along its hinge.
const _LID := [
	[Vector2(-96.0, -96.0), Vector2(-102.0, -170.0)],
	[Vector2(-102.0, -170.0), Vector2(-80.0, -190.0), Vector2(-40.0, -201.0), Vector2(0.0, -204.0),
			Vector2(40.0, -201.0), Vector2(80.0, -190.0), Vector2(102.0, -170.0)],
	[Vector2(102.0, -170.0), Vector2(96.0, -96.0)],
	[Vector2(96.0, -96.0), Vector2(-96.0, -96.0)],
]
## The top of the heap of coins, smooth from its left end at the rim up over its peak and down to its right
## end, before the coins' bumps go on it; and how far down behind the chest the heap reaches.
const _HEAP_TOP := [Vector2(-98.0, -100.0), Vector2(-86.0, -118.0), Vector2(-64.0, -138.0), Vector2(-36.0, -155.0),
		Vector2(-6.0, -165.0), Vector2(26.0, -160.0), Vector2(54.0, -146.0), Vector2(78.0, -127.0),
		Vector2(98.0, -104.0)]
const _HEAP_FOOT := -84.0
## The bumps the coins make along the top of the heap: how wide each one is and how tall.
const _BUMP := Vector2(20.0, 5.0)
## The coins lying face up on the heap: how far each one's middle is across, how far under the top of the
## heap it lies, and how far it is turned, in degrees.
const _COINS := [Vector3(-80.0, 8.0, -8.0), Vector3(-44.0, 24.0, 6.0), Vector3(-4.0, 12.0, -4.0),
		Vector3(34.0, 12.0, 9.0), Vector3(66.0, 6.0, -5.0), Vector3(-24.0, 40.0, 4.0), Vector3(8.0, 52.0, -6.0)]
## The half width and height of a coin lying face up.
const _COIN_RADII := Vector2(14.0, 6.0)
## The chest's front, the band round its rim, the straps down its front and the lock plate hanging from
## the band, with the radius of their rounded corners in the same order.
const _BOX := Rect2(-104.0, -100.0, 208.0, 100.0)
const _BAND := Rect2(-108.0, -106.0, 216.0, 18.0)
const _STRAPS := [Rect2(-74.0, -92.0, 18.0, 87.0), Rect2(56.0, -92.0, 18.0, 87.0)]
const _LOCK := Rect2(-15.0, -97.0, 30.0, 34.0)
const _CORNERS := Vector4(6.0, 4.0, 3.0, 5.0)
## The keyhole on the lock plate: the middle of its round top and its radius, and its slot below.
const _KEYHOLE := Vector2(0.0, -84.0)
const _KEYHOLE_RADIUS := 3.6
const _KEYHOLE_SLOT := [Vector2(0.0, -82.0), Vector2(0.0, -73.0)]
## The sword is drawn lying along x from the middle of its pommel, then tipped by [member blade_tilt] and
## laid with its pommel here.
const _BLADE_HILT := Vector2(-100.0, -158.0)
## The sword: the pommel's radius, the grip and the crossguard with the radius of their rounded corners,
## the blade from its left shoulder to its point and back, and the groove along the blade.
const _POMMEL_RADIUS := 7.0
const _GRIP := Rect2(5.0, -5.0, 27.0, 10.0)
const _GUARD := Rect2(30.0, -20.0, 9.0, 40.0)
const _HILT_CORNER := 3.0
const _BLADE := [Vector2(37.0, -8.0), Vector2(170.0, -7.0), Vector2(196.0, 0.0), Vector2(170.0, 7.0),
		Vector2(37.0, 8.0)]
const _FULLER := [Vector2(48.0, 0.0), Vector2(160.0, 0.0)]
## Widths of the lid's rim, the coins, the sword's groove and the keyhole's slot, as multiples of the
## drawing's line width.
const _RIM_LINE := 0.7
const _COIN_LINE := 0.6
const _FULLER_LINE := 0.5
const _SLOT_LINE := 0.9


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var wash := palette.paper.lerp(color, wash_strength)
	var metal := palette.paper.lerp(color, metal_wash)
	var pale := palette.paper.lerp(color, face_wash)
	var lines: Array[InkLine] = []
	# Back to front: the lid, the heap and the coins on it, the sword lying on them, then the chest,
	# which hides the foot of the heap. The inside of the lid is a wash with no line of its own: the rim's
	# line, drawn over it, draws its edge.
	var lid := PackedVector2Array()
	for run: Array in _LID:
		var part := InkBrush.resample_smooth(_scaled(run), false, spacing)
		lid.append_array(part if lid.is_empty() else part.slice(1))
	lines.append(_washed(lid, color, wash))
	var inside := _inset(lid, lid_rim * chest_scale, spacing)
	if inside.size() > 3:
		lines.append(_washed(inside, Color.TRANSPARENT, wash.lerp(palette.ink, lid_shadow)))
		lines.append(InkLine.along(inside, color, _RIM_LINE, true))
	var top := InkBrush.resample_smooth(_scaled(_HEAP_TOP), false, spacing)
	var heap := _bumpy(top, _BUMP * chest_scale)
	heap.append(Vector2(top[top.size() - 1].x, _HEAP_FOOT * chest_scale))
	heap.append(Vector2(top[0].x, _HEAP_FOOT * chest_scale))
	lines.append(_washed(heap, color, wash))
	for coin: Vector3 in _COINS:
		var middle := Vector2(coin.x * chest_scale, _height_at(top, coin.x * chest_scale) + coin.y * chest_scale)
		var face := Transform2D(deg_to_rad(coin.z), middle) * InkBrush.ellipse(Vector2.ZERO,
				_COIN_RADII * chest_scale, spacing * 0.5, PI)
		lines.append(_washed(face, color, pale, _COIN_LINE))
	# The sword is sampled in its own space, so its spacing there is the page's shrunk by its scale.
	var ink := palette.color(blade_role)
	var dark := palette.paper.lerp(ink, blade_darkness)
	var lay := Transform2D(deg_to_rad(blade_tilt), _BLADE_HILT * chest_scale).scaled_local(Vector2.ONE * chest_scale)
	var fine := spacing / chest_scale
	var blade := InkBrush.resample_polyline(_closed(PackedVector2Array(_BLADE)), fine)
	lines.append(_washed(lay * blade, ink, dark))
	var fuller := lay * InkBrush.resample_polyline(PackedVector2Array(_FULLER), fine)
	lines.append(InkLine.along(fuller, palette.paper.lerp(ink, blade_darkness * 0.5), _FULLER_LINE))
	lines.append(_washed(lay * InkBrush.ellipse(Vector2.ZERO, Vector2.ONE * _POMMEL_RADIUS, fine), ink, dark))
	lines.append(_washed(lay * InkBrush.rounded_rect(_GRIP, _HILT_CORNER, fine), ink, dark))
	lines.append(_washed(lay * InkBrush.rounded_rect(_GUARD, _HILT_CORNER, fine), ink, dark))
	lines.append(_washed(InkBrush.rounded_rect(_scaled_rect(_BOX), _CORNERS.x * chest_scale, spacing), color, wash))
	for strap: Rect2 in _STRAPS:
		lines.append(_washed(InkBrush.rounded_rect(_scaled_rect(strap), _CORNERS.z * chest_scale, spacing), color, metal))
	lines.append(_washed(InkBrush.rounded_rect(_scaled_rect(_BAND), _CORNERS.y * chest_scale, spacing), color, metal))
	lines.append(_washed(InkBrush.rounded_rect(_scaled_rect(_LOCK), _CORNERS.w * chest_scale, spacing), color, pale))
	lines.append(InkLine.dot(_KEYHOLE * chest_scale, _KEYHOLE_RADIUS * chest_scale, palette.ink))
	var slot := InkBrush.resample_polyline(_scaled(_KEYHOLE_SLOT), spacing * 0.5)
	lines.append(InkLine.along(slot, palette.ink, _SLOT_LINE))
	# Set the whole of it centred over the origin, standing on the ground.
	var box := Rect2(lines[0].path[0], Vector2.ZERO)
	for line in lines:
		for point in line.path:
			box = box.expand(point)
	var place := Transform2D(0.0, Vector2(-box.get_center().x, -box.end.y))
	for line in lines:
		line.path = place * line.path
	return lines


## [param top], a curve running from left to right, with a row of bumps along it, each [param bump] wide
## and tall, the way the edges of heaped coins make a pile's outline bumpy.
static func _bumpy(top: PackedVector2Array, bump: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	var travelled := 0.0
	for i in top.size():
		if i > 0:
			travelled += top[i].distance_to(top[i - 1])
		var along := top[mini(i + 1, top.size() - 1)] - top[maxi(i - 1, 0)]
		var up := along.normalized().orthogonal()
		if up.y > 0.0:
			up = -up
		out.append(top[i] + up * bump.y * absf(sin(PI * travelled / bump.x)))
	return out


## How high the curve [param top], running from left to right, is at [param x] across.
static func _height_at(top: PackedVector2Array, x: float) -> float:
	for i in range(1, top.size()):
		if top[i].x >= x:
			return lerpf(top[i - 1].y, top[i].y, inverse_lerp(top[i - 1].x, top[i].x, x))
	return top[top.size() - 1].y


## The closed [param outline] pulled in [param inset] all round, keeping its corners sharp, as points
## about [param spacing] apart ending back on the first. Empty when the outline is too small to pull in
## that far.
static func _inset(outline: PackedVector2Array, inset: float, spacing: float) -> PackedVector2Array:
	var polygon := outline
	if polygon.size() > 1 and polygon[0].is_equal_approx(polygon[polygon.size() - 1]):
		polygon = polygon.slice(0, -1)
	var shrunk := Geometry2D.offset_polygon(polygon, -inset, Geometry2D.JOIN_MITER)
	if shrunk.is_empty():
		return PackedVector2Array()
	var loop: PackedVector2Array = shrunk[0]
	return InkBrush.resample_polyline(_closed(loop), spacing)


func _scaled(points: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point: Vector2 in points:
		out.append(point * chest_scale)
	return out


func _scaled_rect(rect: Rect2) -> Rect2:
	return Rect2(rect.position * chest_scale, rect.size * chest_scale)


## A closed line along [param path] with [param wash] inside it, [param width] times the drawing's
## line width. A transparent [param color] leaves the wash with no line of its own.
static func _washed(path: PackedVector2Array, color: Color, wash: Color, width := 1.0) -> InkLine:
	var line := InkLine.along(path, color, width, true)
	line.fill = wash
	return line


## [param corners] with the first repeated at the end, to draw them as a closed polyline.
static func _closed(corners: PackedVector2Array) -> PackedVector2Array:
	var out := corners.duplicate()
	out.append(corners[0])
	return out
