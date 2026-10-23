@tool
class_name Diary
extends InkDrawing
## A doodle: a personal diary. Shut, it lies on the ground turned at a slight angle and seen a little from
## above: a brown cover with a border pressed into it, a strap clasped across from its edge to a lock plate
## with a keyhole, the edges of its pages along its side, and the tail of a ribbon bookmark trailing out
## from between them onto the ground. Open, it lies flat-ish on its cover, its two pages arching up from
## the spine, each written over in a few short lines of scribbled handwriting in thin muted ink, the ribbon
## running down the spine and trailing out over the edge, and the loose strap lying out to the side. Its
## line is brown, with a brown wash in the cover, a darker one in the strap and the ribbon and a pale one
## on the lock plate; the pages are paper. The whole of it is set so it stands centred over its origin,
## the ground under its middle.

## Whether the diary lies open at its pages, or shut with its cover and clasp showing.
@export var open := false:
	set(value):
		open = value
		queue_redraw()
## How big the diary is drawn, as a multiple of its natural size.
@export_range(0.2, 3.0, 0.01) var diary_scale := 1.0:
	set(value):
		diary_scale = value
		queue_redraw()
## How far the shut diary is turned where it lies, in degrees, clockwise.
@export_range(-40.0, 40.0, 0.5) var shut_turn := 16.0:
	set(value):
		shut_turn = value
		queue_redraw()
## How much of its length the shut diary shows from its head to its tail, seen a little from above:
## 1 is straight down from overhead, less is lower.
@export_range(0.2, 1.0, 0.01) var view_squash := 0.62:
	set(value):
		view_squash = value
		queue_redraw()
## Palette role of the diary's line, its cover, its strap and the ribbon.
@export var role := &"brown":
	set(value):
		role = value
		queue_redraw()
## Palette role of the handwriting.
@export var writing_role := &"muted":
	set(value):
		writing_role = value
		queue_redraw()
## How strongly the cover's wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()
## How strongly the strap's and the ribbon's wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var strap_wash := 0.7:
	set(value):
		strap_wash = value
		queue_redraw()
## How strongly the lock plate's wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var plate_wash := 0.15:
	set(value):
		plate_wash = value
		queue_redraw()
## How many lines of handwriting each open page holds.
@export_range(0, 9) var writing_lines := 5:
	set(value):
		writing_lines = value
		queue_redraw()
## Seed for the handwriting's words, so the pages read the same every time.
@export var writing_seed := 11:
	set(value):
		writing_seed = value
		queue_redraw()

## The shut diary at natural size, as it lies on the ground with its spine on the left: how wide its cover
## is across and how long from its head to its tail, and how thick it is.
const _COVER := Vector2(100.0, 140.0)
const _THICKNESS := 17.0
## How thick each board of the cover is, and how far in from the cover's edges the pages stop.
const _BOARD := 3.0
const _PAGES_INSET := 3.0
## Radius of the cover's rounded corners.
const _COVER_CORNER := 7.0
## How far in from the cover's edge the border pressed into it runs, and the radius of its corners.
const _BORDER := Vector2(9.0, 4.0)
## How high up the side of the pages each line between them runs, as shares of the pages' thickness.
const _PAGE_EDGES := [0.35, 0.68]
## How much of each line between the pages is left off at either end, so they stop short of the corners.
const _PAGE_EDGE_TRIM := 7.0
## The strap across the cover, from just past its edge on the right, and the lock plate at its end; with
## the radius of their rounded corners.
const _STRAP := Rect2(20.0, -80.0, 32.0, 20.0)
const _PLATE := Rect2(7.0, -84.0, 19.0, 28.0)
const _CLASP_CORNER := 4.0
## Radius of the keyhole on the lock plate.
const _KEYHOLE_RADIUS := 2.6
## The ribbon's tail on the shut diary: where it comes out from between the pages, across and along the
## diary's tail, then where it lies on the ground in front of it.
const _SHUT_RIBBON := [Vector2(-28.0, -2.0), Vector2(-28.0, 4.0), Vector2(-32.0, 12.0), Vector2(-42.0, 17.0),
		Vector2(-55.0, 16.0)]
## How wide the ribbon is, and how deep the notch cut into its end.
const _RIBBON := Vector2(7.0, 5.0)

## The open diary at natural size: how wide each page is, how far down a page shows from its head to its
## foot, and how far its outer edge rises above the spine as the page arches up from it.
const _PAGE := Vector3(92.0, 84.0, 12.0)
## How far the cover shows past the pages at their outer edges, above the spine and under their feet.
const _OPEN_COVER := Vector3(5.0, 8.0, 3.0)
## Radius of the open cover's rounded corners.
const _OPEN_CORNER := 6.0
## Points along each edge of an open page.
const _PAGE_STEPS := 16
## How far down a page the handwriting starts and stops, as shares of the page.
const _WRITING_BAND := Vector2(0.17, 0.8)
## How far in the handwriting keeps from the spine and from the outer edge, as shares of the page's width.
const _WRITING_MARGIN := Vector2(0.13, 0.1)
## How long a full line of handwriting runs, as shares of the room on its page, and the last line's.
const _LINE_SHARE := Vector2(0.78, 1.0)
const _LAST_LINE_SHARE := Vector2(0.4, 0.65)
## The shortest and longest word, and the gap between words.
const _WORD := Vector2(11.0, 30.0)
const _WORD_GAP := 6.0
## How tall each loop of a word is, how long it runs along the line, and how much its height varies.
const _LOOP := Vector3(5.5, 6.5, 0.4)
## How far along the line the variation in a word's loops takes to change.
const _LOOP_VARIATION_LENGTH := 9.0
## Sample spacing along the handwriting, finer than a whole line's.
const _WRITING_SPACING := 1.0
## The ribbon on the open diary: down beside the spine from its head, out over the cover's edge and
## trailing on the ground.
const _OPEN_RIBBON := [Vector2(3.0, -82.0), Vector2(5.0, -44.0), Vector2(6.0, -8.0), Vector2(8.0, 3.0),
		Vector2(14.0, 10.0), Vector2(26.0, 13.0), Vector2(40.0, 12.0), Vector2(50.0, 8.0)]
## The loose strap of the open diary, lying out from the right cover's edge, and the tongue at its end.
const _OPEN_STRAP := Rect2(92.0, -51.0, 22.0, 18.0)
const _TONGUE := Rect2(108.0, -54.0, 11.0, 24.0)
## Widths of the pages' line, the lines between the pages, the cover's edge and border, the lock plate
## and the handwriting, as multiples of the drawing's line width.
const _PAGES_LINE := 0.8
const _PAGE_EDGE_LINE := 0.5
const _EDGE_LINE := 0.8
const _BORDER_LINE := 0.5
const _PLATE_LINE := 0.7
const _WRITING_LINE := 0.45


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	# Built at natural size, so its spacing there is the page's shrunk by the diary's scale.
	var spacing := style.sample_spacing / diary_scale
	var color := palette.color(role)
	var lines: Array[InkLine] = []
	if open:
		lines = _open_lines(palette, color, spacing)
	else:
		lines = _shut_lines(palette, color, spacing)
	# Set the whole of it centred over the origin, standing on the ground.
	var box := Rect2(lines[0].path[0], Vector2.ZERO)
	for line in lines:
		for point in line.path:
			box = box.expand(point)
	var place := Transform2D(0.0, Vector2.ONE * diary_scale, 0.0,
			Vector2(-box.get_center().x, -box.end.y) * diary_scale)
	for line in lines:
		line.path = place * line.path
		line.dot_radius *= diary_scale
	return lines


## The shut diary, back to front: its whole side, which the back board's edge shows along, the pages and
## the lines between them, the front board and its top, the border pressed into it, the strap and its
## lock, then the ribbon in front of it all.
func _shut_lines(palette: InkPalette, color: Color, spacing: float) -> Array[InkLine]:
	var wash := palette.paper.lerp(color, wash_strength)
	var dark := palette.paper.lerp(color, strap_wash)
	var lines: Array[InkLine] = []
	var cover := InkBrush.rounded_rect(Rect2(Vector2(-_COVER.x * 0.5, -_COVER.y), _COVER), _COVER_CORNER, spacing)
	var pages := InkBrush.rounded_rect(Rect2(Vector2(-_COVER.x * 0.5, -_COVER.y + _PAGES_INSET),
			_COVER - Vector2(_PAGES_INSET, _PAGES_INSET * 2.0)), _COVER_CORNER * 0.5, spacing)
	lines.append(_washed(_side_band(cover, 0.0, _THICKNESS), color, wash))
	lines.append(_washed(_side_band(pages, _BOARD, _THICKNESS - _BOARD), color, palette.paper, _PAGES_LINE))
	for share: float in _PAGE_EDGES:
		var edge := _underside(_on_ground(pages, lerpf(_BOARD, _THICKNESS - _BOARD, share)))
		lines.append(InkLine.along(_trimmed(edge, _PAGE_EDGE_TRIM), color, _PAGE_EDGE_LINE))
	var board := _on_ground(cover, _THICKNESS - _BOARD)
	board.append_array(_on_ground(cover, _THICKNESS))
	lines.append(_washed(InkBrush.resample_polyline(Geometry2D.convex_hull(board), spacing), color, wash))
	var top := _on_ground(cover, _THICKNESS)
	lines.append(InkLine.along(_underside(top), color, _EDGE_LINE))
	var border := InkBrush.rounded_rect(Rect2(Vector2(-_COVER.x * 0.5, -_COVER.y), _COVER).grow(-_BORDER.x),
			_BORDER.y, spacing)
	lines.append(InkLine.along(_on_ground(border, _THICKNESS), color, _BORDER_LINE, true))
	# The strap comes up the edge of the pages from the back board and over onto the front one.
	var strap_end := PackedVector2Array([Vector2(_STRAP.end.x, _STRAP.position.y), _STRAP.end])
	var wrap := _on_ground(strap_end, _THICKNESS)
	var wrap_foot := _on_ground(strap_end, 0.0)
	wrap_foot.reverse()
	wrap.append_array(wrap_foot)
	lines.append(_washed(InkBrush.resample_polyline(_closed(wrap), spacing), color, dark))
	var strap := _on_ground(InkBrush.rounded_rect(_STRAP, _CLASP_CORNER, spacing), _THICKNESS)
	lines.append(_washed(strap, color, dark))
	var plate := _on_ground(InkBrush.rounded_rect(_PLATE, _CLASP_CORNER, spacing), _THICKNESS)
	lines.append(_washed(plate, color, palette.paper.lerp(color, plate_wash), _PLATE_LINE))
	lines.append(InkLine.dot(_on_ground(PackedVector2Array([_PLATE.get_center()]), _THICKNESS)[0], _KEYHOLE_RADIUS,
			palette.ink))
	# The ribbon comes out from between the pages, halfway up their side, and lies on the ground.
	var ribbon := _on_ground(PackedVector2Array(_SHUT_RIBBON.slice(1)), 0.0)
	var root := _on_ground(PackedVector2Array([_SHUT_RIBBON[0]]), _THICKNESS * 0.5)
	root.append_array(ribbon)
	lines.append(_washed(_ribbon(InkBrush.resample_smooth(root, false, spacing)), color, dark))
	return lines


## The open diary, back to front: the loose strap, whose root the cover hides, the cover, the stacked
## edges of the pages on it, the pages and their handwriting, then the ribbon over them.
func _open_lines(palette: InkPalette, color: Color, spacing: float) -> Array[InkLine]:
	var wash := palette.paper.lerp(color, wash_strength)
	var dark := palette.paper.lerp(color, strap_wash)
	var lines: Array[InkLine] = []
	lines.append(_washed(InkBrush.rounded_rect(_OPEN_STRAP, _CLASP_CORNER, spacing), color, dark))
	lines.append(_washed(InkBrush.rounded_rect(_TONGUE, _CLASP_CORNER, spacing), color,
			palette.paper.lerp(color, plate_wash), _PLATE_LINE))
	var cover := Rect2(-_PAGE.x - _OPEN_COVER.x, -_PAGE.y - _OPEN_COVER.y, (_PAGE.x + _OPEN_COVER.x) * 2.0,
			_PAGE.y + _OPEN_COVER.y + _OPEN_COVER.z)
	lines.append(_washed(InkBrush.rounded_rect(cover, _OPEN_CORNER, spacing), color, wash))
	var rng := RandomNumberGenerator.new()
	rng.seed = writing_seed
	var writing := palette.color(writing_role)
	for side: float in [-1.0, 1.0]:
		# The stacked pages show under each page's foot, from the spine out to the outer edge.
		var stack := _page_edge(side, 1.0, 0.0, 1.0)
		stack.append(Vector2(side * _PAGE.x, 0.0))
		lines.append(_washed(InkBrush.resample_polyline(_closed(stack), spacing), color, palette.paper, _PAGES_LINE))
		for share: float in _PAGE_EDGES:
			var edge := _page_edge(side, 1.0, 0.15, 1.0)
			for i in edge.size():
				edge[i] = Vector2(edge[i].x, edge[i].y * share)
			lines.append(InkLine.along(InkBrush.resample_smooth(edge, false, spacing), color, _PAGE_EDGE_LINE))
		var page := _page_edge(side, 0.0, 0.0, 1.0)
		var foot := _page_edge(side, 1.0, 0.0, 1.0)
		foot.reverse()
		page.append_array(foot)
		lines.append(_washed(InkBrush.resample_polyline(_closed(page), spacing), color, palette.paper, _PAGES_LINE))
		for word in _handwriting(side, rng):
			lines.append(InkLine.along(word, writing, _WRITING_LINE))
	lines.append(_washed(_ribbon(InkBrush.resample_smooth(PackedVector2Array(_OPEN_RIBBON), false, spacing)), color, dark))
	return lines


## A point on the open page on [param side] (-1 the left page, 1 the right): [param across] it from the
## spine (0) to its outer edge (1), and [param down] it from its head (0) to its foot (1). The page arches
## up from the spine, steeply at first and levelling out toward its edge.
func _on_page(side: float, across: float, down: float) -> Vector2:
	var rise := _PAGE.z * (1.0 - pow(1.0 - clampf(across, 0.0, 1.0), 2.0))
	return Vector2(side * across * _PAGE.x, lerpf(-_PAGE.y, 0.0, down) - rise)


## The edge of the open page on [param side] running across it at [param down], from [param from] to
## [param to] of the way out from the spine.
func _page_edge(side: float, down: float, from: float, to: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in _PAGE_STEPS + 1:
		points.append(_on_page(side, lerpf(from, to, float(i) / _PAGE_STEPS), down))
	return points


## The handwriting on the open page on [param side]: its lines, each a run of scribbled words, left to
## right across the page, the last line shorter. Each word is a run of loops, its own path.
func _handwriting(side: float, rng: RandomNumberGenerator) -> Array[PackedVector2Array]:
	var words: Array[PackedVector2Array] = []
	# A line starts near the outer edge on the left page and near the spine on the right one.
	var start := 1.0 - _WRITING_MARGIN.y if side < 0.0 else _WRITING_MARGIN.x
	var room := (1.0 - _WRITING_MARGIN.x - _WRITING_MARGIN.y) * _PAGE.x
	for row in writing_lines:
		var down := lerpf(_WRITING_BAND.x, _WRITING_BAND.y, row / maxf(writing_lines - 1.0, 1.0))
		var share := _LAST_LINE_SHARE if row == writing_lines - 1 else _LINE_SHARE
		var length := room * rng.randf_range(share.x, share.y)
		var at := 0.0
		var variation := rng.randi()
		while length - at >= _WORD.x:
			var word := minf(rng.randf_range(_WORD.x, _WORD.y), length - at)
			var path := PackedVector2Array()
			var steps := ceili(word / _WRITING_SPACING)
			for k in steps + 1:
				var along := at + word * k / steps
				var height := _LOOP.x * (1.0 + _LOOP.z * InkBrush.noise(along / _LOOP_VARIATION_LENGTH, variation))
				var lift := height * 0.5 * (1.0 - cos(TAU * (along - at) / _LOOP.y))
				path.append(_on_page(side, start + side * along / _PAGE.x, down - lift / _PAGE.y))
			words.append(path)
			at += word + _WORD_GAP
	return words


## [param points] of the shut diary as it lies, turned and seen a little from above, raised
## [param height] off the ground.
func _on_ground(points: PackedVector2Array, height: float) -> PackedVector2Array:
	var turn := deg_to_rad(shut_turn)
	var out := PackedVector2Array()
	for point in points:
		var turned := point.rotated(turn)
		out.append(Vector2(turned.x, turned.y * view_squash - height))
	return out


## The side of the shut diary's [param outline] seen between [param low] and [param high] off the ground:
## the outline's underside at the top of that, and again at its foot, joined at their ends.
func _side_band(outline: PackedVector2Array, low: float, high: float) -> PackedVector2Array:
	var band := _underside(_on_ground(outline, high))
	var foot := _underside(_on_ground(outline, low))
	foot.reverse()
	band.append_array(foot)
	return _closed(band)


## The part of the closed convex [param outline] that faces down the page: from its leftmost point round
## its bottom to its rightmost.
static func _underside(outline: PackedVector2Array) -> PackedVector2Array:
	var count := outline.size()
	var left := 0
	var right := 0
	for i in count:
		if outline[i].x < outline[left].x:
			left = i
		if outline[i].x > outline[right].x:
			right = i
	var ways: Array[PackedVector2Array] = []
	for step: int in [1, -1]:
		var way := PackedVector2Array([outline[left]])
		var i := left
		while i != right:
			i = posmod(i + step, count)
			way.append(outline[i])
		ways.append(way)
	return ways[0] if _mean_y(ways[0]) > _mean_y(ways[1]) else ways[1]


static func _mean_y(points: PackedVector2Array) -> float:
	var total := 0.0
	for point in points:
		total += point.y
	return total / maxf(points.size(), 1.0)


## [param path] with [param length] left off at either end.
static func _trimmed(path: PackedVector2Array, length: float) -> PackedVector2Array:
	var first := 0
	var travelled := 0.0
	while first < path.size() - 2 and travelled < length:
		travelled += path[first + 1].distance_to(path[first])
		first += 1
	var last := path.size() - 1
	travelled = 0.0
	while last > first + 1 and travelled < length:
		travelled += path[last].distance_to(path[last - 1])
		last -= 1
	return path.slice(first, last + 1)


## A closed outline round [param spine], the ribbon's width all along it, square across where it starts
## and with a notch cut into its end.
static func _ribbon(spine: PackedVector2Array) -> PackedVector2Array:
	var count := spine.size()
	var near := PackedVector2Array()
	var far := PackedVector2Array()
	for i in count:
		var along := spine[mini(i + 1, count - 1)] - spine[maxi(i - 1, 0)]
		var across := along.normalized().orthogonal() * _RIBBON.x * 0.5
		near.append(spine[i] + across)
		far.append(spine[i] - across)
	var end := spine[count - 1]
	var back := (spine[count - 1] - spine[maxi(count - 2, 0)]).normalized()
	near.append(end - back * _RIBBON.y)
	far.reverse()
	near.append_array(far)
	return _closed(near)


## [param corners] with the first repeated at the end, to draw them as a closed polyline.
static func _closed(corners: PackedVector2Array) -> PackedVector2Array:
	var out := corners.duplicate()
	out.append(corners[0])
	return out


## A closed line along [param path] with [param wash] inside it, [param width] times the drawing's
## line width.
static func _washed(path: PackedVector2Array, color: Color, wash: Color, width := 1.0) -> InkLine:
	var line := InkLine.along(path, color, width, true)
	line.fill = wash
	return line
