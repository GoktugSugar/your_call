class_name InkBrush
extends RefCounted
## Turns paths into hand-drawn ink. A line is resampled, nudged off its path like an unsteady hand,
## tapered at its loose ends, and drawn as a triangle strip whose UVs let the ink shader soften its edges.
## The boil comes from the variant: each variant moves the line a little, and the page cycles through them.

const MATERIAL_PATH := "res://ink/ink_line_material.tres"

const _NOISE_SIZE := 1024
const _NOISE_MASK := _NOISE_SIZE - 1
## Fixed, so the page looks the same on every run.
const _NOISE_SEED := 1904221
## UV that the ink shader reads as solid ink with no grain: the middle of a line, before its start.
const _SOLID_UV := Vector2(-1.0, 0.5)
## UV for the rim of a dot: the very edge of a line, before its start.
const _RIM_UV := Vector2(-1.0, 0.0)
## Seed channels, so a line's wobble, boil, width and ends do not move together.
const _CHANNEL_WOBBLE := 0
const _CHANNEL_WIDTH := 1
const _CHANNEL_ENDS := 2
const _CHANNEL_BOIL := 3

static var _noise: PackedFloat32Array = _make_noise()
static var _material: ShaderMaterial


## The material every ink line is drawn with.
static func shared_material() -> ShaderMaterial:
	if _material == null:
		_material = load(MATERIAL_PATH) as ShaderMaterial
	return _material


## Smooth value noise in [-1, 1] along one dimension. The same [param seed] always gives the same curve.
static func noise(x: float, seed: int) -> float:
	var i := floori(x)
	var f := x - i
	var a := _noise[(i + seed) & _NOISE_MASK]
	var b := _noise[(i + 1 + seed) & _NOISE_MASK]
	return lerpf(a, b, f * f * (3.0 - 2.0 * f))


## Points along a polyline about [param spacing] apart, keeping every corner.
static func resample_polyline(points: PackedVector2Array, spacing: float) -> PackedVector2Array:
	if points.size() < 2:
		return points.duplicate()
	var out := PackedVector2Array([points[0]])
	for i in range(1, points.size()):
		var a := points[i - 1]
		var b := points[i]
		var steps := maxi(1, ceili(a.distance_to(b) / spacing))
		for k in range(1, steps + 1):
			out.append(a.lerp(b, float(k) / steps))
	return out


## Points about [param spacing] apart along a smooth curve through [param points].
## A closed curve ends back on its first point.
static func resample_smooth(points: PackedVector2Array, closed: bool, spacing: float) -> PackedVector2Array:
	var n := points.size()
	if n < 3:
		var straight := points.duplicate()
		if closed and n > 0:
			straight.append(points[0])
		return resample_polyline(straight, spacing)
	var out := PackedVector2Array([points[0]])
	var segments := n if closed else n - 1
	for i in segments:
		var p0 := points[(i - 1 + n) % n] if closed else points[maxi(i - 1, 0)]
		var p1 := points[i]
		var p2 := points[(i + 1) % n]
		var p3 := points[(i + 2) % n] if closed else points[mini(i + 2, n - 1)]
		var steps := maxi(1, ceili(p1.distance_to(p2) / spacing))
		for k in range(1, steps + 1):
			out.append(p1.cubic_interpolate(p2, p0, p3, float(k) / steps))
	return out


## A closed ellipse, as points about [param spacing] apart starting at [param start_angle] (radians). The first point is not repeated.
static func ellipse(center: Vector2, radii: Vector2, spacing: float, start_angle := 0.0) -> PackedVector2Array:
	var perimeter := TAU * sqrt((radii.x * radii.x + radii.y * radii.y) * 0.5)
	var count := maxi(8, ceili(perimeter / spacing))
	var out := PackedVector2Array()
	out.resize(count)
	for i in count:
		var angle := start_angle + TAU * i / count
		out[i] = center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y)
	return out


## A closed rectangle with rounded corners, as points about [param spacing] apart, starting
## at the top left where the top edge begins. The first point is not repeated.
static func rounded_rect(rect: Rect2, radius: float, spacing: float) -> PackedVector2Array:
	var r := clampf(radius, 0.0, minf(rect.size.x, rect.size.y) * 0.5)
	var corners := [
		[Vector2(rect.end.x - r, rect.position.y + r), -PI * 0.5],
		[Vector2(rect.end.x - r, rect.end.y - r), 0.0],
		[Vector2(rect.position.x + r, rect.end.y - r), PI * 0.5],
		[Vector2(rect.position.x + r, rect.position.y + r), PI],
	]
	var out := PackedVector2Array()
	var arc_steps := maxi(2, ceili(r * PI * 0.5 / spacing))
	var start := Vector2(rect.position.x + r, rect.position.y)
	for corner: Array in corners:
		var center: Vector2 = corner[0]
		var from_angle: float = corner[1]
		var edge_end := center + Vector2(cos(from_angle), sin(from_angle)) * r
		out.append_array(resample_polyline(PackedVector2Array([start, edge_end]), spacing).slice(0, -1))
		for k in arc_steps:
			var angle := from_angle + PI * 0.5 * k / arc_steps
			out.append(center + Vector2(cos(angle), sin(angle)) * r)
		start = center + Vector2(cos(from_angle + PI * 0.5), sin(from_angle + PI * 0.5)) * r
	return out


## Draws a hand-drawn line along [param path], which should already be densely sampled.
## A closed path is drawn as a loop that runs a little past its own start, as a hand would.
## [param reveal] draws only the first part of the line, for drawing it on.
static func stroke(item: RID, path: PackedVector2Array, closed: bool, width: float, color: Color,
		seed: int, variant: int, style: InkStyle, reveal := 1.0) -> void:
	var points := path
	if closed:
		points = _loop_with_overlap(path, style.loop_overlap)
	_stroke_open(item, points, width, color, seed, variant, style, reveal)


## Fills the inside of a closed outline with flat colour. A wash sits under its line, so its edge needs no softening.
static func fill(item: RID, outline: PackedVector2Array, color: Color) -> void:
	var polygon := outline
	if polygon.size() > 2 and polygon[0].is_equal_approx(polygon[polygon.size() - 1]):
		polygon = polygon.slice(0, polygon.size() - 1)
	var indices := Geometry2D.triangulate_polygon(polygon)
	if indices.is_empty():
		return
	var uvs := PackedVector2Array()
	uvs.resize(polygon.size())
	uvs.fill(_SOLID_UV)
	var colors := PackedColorArray()
	colors.resize(polygon.size())
	colors.fill(color)
	RenderingServer.canvas_item_add_triangle_array(item, indices, polygon, colors, uvs)


## A small round dot of ink, like an eye. It boils with the page.
static func dot(item: RID, center: Vector2, radius: float, color: Color, seed: int, variant: int, style: InkStyle) -> void:
	var boil_seed := _channel(seed, _CHANNEL_BOIL + variant)
	var jitter := Vector2(noise(0.5, boil_seed), noise(7.5, boil_seed)) * style.boil_amplitude * 0.5
	var c := center + jitter
	var segments := maxi(8, ceili(TAU * radius / 1.5))
	var points := PackedVector2Array([c])
	var uvs := PackedVector2Array([_SOLID_UV])
	for i in segments:
		var angle := TAU * i / segments
		points.append(c + Vector2(cos(angle), sin(angle)) * radius)
		uvs.append(_RIM_UV)
	var indices := PackedInt32Array()
	for i in segments:
		indices.append_array([0, 1 + i, 1 + (i + 1) % segments])
	var colors := PackedColorArray()
	colors.resize(points.size())
	colors.fill(color)
	RenderingServer.canvas_item_add_triangle_array(item, indices, points, colors, uvs)


## The total length of a path.
static func path_length(points: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(1, points.size()):
		total += points[i].distance_to(points[i - 1])
	return total


static func _stroke_open(item: RID, path: PackedVector2Array, width: float, color: Color,
		seed: int, variant: int, style: InkStyle, reveal: float) -> void:
	var n := path.size()
	if n < 2 or reveal <= 0.0:
		return
	var points := path.duplicate()
	var ends_seed := _channel(seed, _CHANNEL_ENDS + variant)
	var start_overshoot := style.overshoot * (0.75 + 0.25 * noise(0.5, ends_seed))
	var end_overshoot := style.overshoot * (0.75 + 0.25 * noise(3.5, ends_seed))
	points[0] += (points[0] - points[1]).normalized() * start_overshoot
	points[n - 1] += (points[n - 1] - points[n - 2]).normalized() * end_overshoot

	var lengths := PackedFloat32Array()
	lengths.resize(n)
	for i in range(1, n):
		lengths[i] = lengths[i - 1] + points[i].distance_to(points[i - 1])
	var total := lengths[n - 1]
	if total <= 0.0:
		return

	var visible := total * minf(reveal, 1.0)
	if visible < total:
		var last := lengths.bsearch(visible)
		var a := points[last - 1]
		var b := points[last]
		var t := (visible - lengths[last - 1]) / maxf(lengths[last] - lengths[last - 1], 0.0001)
		n = last + 1
		points.resize(n)
		lengths.resize(n)
		points[n - 1] = a.lerp(b, t)
		lengths[n - 1] = visible
	if n < 2:
		return

	var wobble_seed := _channel(seed, _CHANNEL_WOBBLE)
	var boil_seed := _channel(seed, _CHANNEL_BOIL + variant)
	var width_seed := _channel(seed, _CHANNEL_WIDTH)
	var steadiness := clampf(total / style.wobble_wavelength, style.small_line_wobble, 1.0)
	var wobble := style.wobble_amplitude * steadiness
	var boil := style.boil_amplitude * steadiness
	var vertices := PackedVector2Array()
	vertices.resize(n * 2)
	var uvs := PackedVector2Array()
	uvs.resize(n * 2)
	for i in n:
		var tangent: Vector2
		if i == 0:
			tangent = points[1] - points[0]
		elif i == n - 1:
			tangent = points[i] - points[i - 1]
		else:
			tangent = points[i + 1] - points[i - 1]
		tangent = tangent.normalized()
		var normal := Vector2(-tangent.y, tangent.x)
		var miter := 1.0
		if i > 0 and i < n - 1:
			var segment := (points[i] - points[i - 1]).normalized()
			var cosine := normal.dot(Vector2(-segment.y, segment.x))
			miter = minf(1.0 / maxf(cosine, 0.001), style.miter_limit)

		var s := lengths[i]
		var offset := wobble * noise(s / style.wobble_wavelength, wobble_seed) \
				+ boil * noise(s / style.boil_wavelength, boil_seed)
		var w := width * (1.0 + style.width_jitter * noise(s / style.width_wavelength, width_seed))
		if style.taper_length > 0.0:
			var t := clampf(minf(s, visible - s) / style.taper_length, 0.0, 1.0)
			w *= lerpf(style.taper_tip, 1.0, t * t * (3.0 - 2.0 * t))
		var center := points[i] + normal * offset
		var half := normal * (w * 0.5 * miter)
		vertices[i * 2] = center + half
		vertices[i * 2 + 1] = center - half
		uvs[i * 2] = Vector2(s, 0.0)
		uvs[i * 2 + 1] = Vector2(s, 1.0)

	var indices := PackedInt32Array()
	indices.resize((n - 1) * 6)
	for i in n - 1:
		var a := i * 2
		var k := i * 6
		indices[k] = a
		indices[k + 1] = a + 1
		indices[k + 2] = a + 2
		indices[k + 3] = a + 1
		indices[k + 4] = a + 3
		indices[k + 5] = a + 2
	var colors := PackedColorArray()
	colors.resize(n * 2)
	colors.fill(color)
	RenderingServer.canvas_item_add_triangle_array(item, indices, vertices, colors, uvs)


## A closed loop as an open path that runs [param overlap] of its length past its own start.
static func _loop_with_overlap(path: PackedVector2Array, overlap: float) -> PackedVector2Array:
	var loop := path.duplicate()
	if loop.size() < 2:
		return loop
	if not loop[0].is_equal_approx(loop[loop.size() - 1]):
		loop.append(loop[0])
	var extra := path_length(loop) * overlap
	var i := 1
	while extra > 0.0 and i < loop.size():
		var step := loop[i].distance_to(loop[i - 1])
		if step >= extra:
			loop.append(loop[i - 1].lerp(loop[i], extra / maxf(step, 0.0001)))
			break
		loop.append(loop[i])
		extra -= step
		i += 1
	return loop


static func _channel(seed: int, channel: int) -> int:
	return seed * 7919 + channel * 104729


static func _make_noise() -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = _NOISE_SEED
	var table := PackedFloat32Array()
	table.resize(_NOISE_SIZE)
	for i in _NOISE_SIZE:
		table[i] = rng.randf_range(-1.0, 1.0)
	return table
