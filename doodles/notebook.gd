@tool
class_name Notebook
extends InkDrawing
## A doodle: the imp's battered notebook, lying open and seen from above at a slight angle, so its far
## edge is a little narrower than its near one. A worn cover, two pages of paper with faint ruled lines
## across them and uneven edges, a couple of loose sheets showing under each page along its foot, the
## pages dipping into the gutter at the spine, a corner turned down on each page (the left page's top
## outer corner, the right page's bottom outer corner), and a stub of pencil lying across the right
## page's top outer corner. The stage writes words over the pages: [method page_rect] says where. Its
## line is the imp's own tint, with a wash of it in the cover, the pages paper, the turned corners a
## little darker, the ruled lines faded; the pencil is ink with a pale wash in its body and a darker one
## at its ends. Its origin is the ground under the middle of the cover's near edge.

## How big the notebook is drawn, as a multiple of its natural size.
@export_range(0.2, 3.0, 0.01) var notebook_scale := 1.0:
	set(value):
		notebook_scale = value
		queue_redraw()
## How much narrower the far edge is than the near one, as a share of the near one, seen at an angle.
@export_range(0.0, 0.3, 0.005) var perspective := 0.07:
	set(value):
		perspective = value
		queue_redraw()
## Distance between the ruled lines, at natural size.
@export_range(8.0, 80.0, 0.5) var rule_spacing := 22.0:
	set(value):
		rule_spacing = value
		queue_redraw()
## Palette role of the notebook's line and its cover: the imp's own tint, since it is his.
@export var role := &"imp":
	set(value):
		role = value
		queue_redraw()
## Palette role of the ruled lines.
@export var rule_role := &"faded":
	set(value):
		rule_role = value
		queue_redraw()
## Palette role of the pencil's line.
@export var pencil_role := &"ink":
	set(value):
		pencil_role = value
		queue_redraw()
## How strongly the cover's wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var cover_wash := 0.45:
	set(value):
		cover_wash = value
		queue_redraw()
## How strongly the ruled lines take their colour over the page: lower is fainter.
@export_range(0.0, 1.0, 0.01) var rule_strength := 0.8:
	set(value):
		rule_strength = value
		queue_redraw()
## How strongly a turned down corner's wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var turned_wash := 0.08:
	set(value):
		turned_wash = value
		queue_redraw()
## How strongly the pencil's body takes its line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var pencil_wash := 0.2:
	set(value):
		pencil_wash = value
		queue_redraw()
## How strongly the pencil's band and rubber take its line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var pencil_end_wash := 0.45:
	set(value):
		pencil_end_wash = value
		queue_redraw()

## The cover at natural size, lying flat before it is seen at an angle, and the radius of its corners.
const _COVER := Rect2(-184.0, -220.0, 368.0, 220.0)
const _COVER_CORNER := 10.0
## The right page, from the spine out, before it is seen at an angle; the left page mirrors it.
const _PAGE := Rect2(0.0, -210.0, 172.0, 194.0)
## The pages under each page, uppermost first: how far out past the page's outer edge, and how far
## below its foot, each one shows.
const _UNDER := [Vector2(2.0, 5.0), Vector2(0.0, 9.0)]
## How far the worn edges of the cover and the pages wander off true, and along how long a stretch.
const _WEAR := Vector3(1.4, 2.4, 26.0)
## How far the pages dip into the gutter at the spine, and how far out from it the dip reaches.
const _GUTTER := Vector2(4.0, 26.0)
## How far along each edge a turned down corner is folded.
const _TURNED := 22.0
## The ruled lines: how far down the page the first one runs and the lowest one may run, and how far in
## from the spine and the outer edge they stop.
const _RULED := Vector4(-188.0, -28.0, 10.0, 8.0)
## Where the words go on the right page, before it is seen at an angle: clear of the gutter, the turned
## corner and the pencil. The left page mirrors it.
const _WRITING := Rect2(20.0, -178.0, 140.0, 134.0)
## The pencil: where its middle lies, how far it tips up toward its rubber, in degrees, its length and
## its thickness.
const _PENCIL_MIDDLE := Vector2(152.0, -206.0)
const _PENCIL_TILT := 34.0
const _PENCIL := Vector2(90.0, 12.0)
## Along the pencil from its point: where the bare wood of its sharpened end starts, where its painted
## body starts, where its metal band starts, and where its rubber starts.
const _PENCIL_PARTS := Vector4(7.0, 22.0, 76.0, 84.0)
## How much thicker the band is than the pencil, and where along it its two rings run, as shares of it.
const _BAND_LIP := 1.0
const _BAND_RINGS := [0.35, 0.65]
## How far off the middle of the pencil's body the line along one of its flat sides runs, as a share of
## half its thickness.
const _FACET := 0.3
## Radius of the rubber's rounded end, as a share of half the pencil's thickness, and how far the rubber
## reaches in under the band.
const _RUBBER_ROUNDING := 0.5
const _RUBBER_TUCK := 1.0
## Points along each straight edge of the pages, so they can bend into the gutter.
const _EDGE_SPACING := 2.0
## Widths of the pages' line, the ruled lines, the line along the pencil's body and the band's rings,
## as multiples of the drawing's line width.
const _PAGE_LINE := 0.8
const _RULE_LINE := 0.45
const _FACET_LINE := 0.45
const _RING_LINE := 0.45


## Where words written on page [param index] go, in local space: the left page is 0, the right one 1.
## The rect fits inside the page however it is seen, clear of the gutter, the turned corner and the pencil.
func page_rect(index: int) -> Rect2:
	var inner := _WRITING.position.x * _squeeze(_WRITING.end.y)
	var outer := _WRITING.end.x * _squeeze(_WRITING.position.y)
	var left := inner if index == 1 else -outer
	return Rect2(Vector2(left, _WRITING.position.y) * notebook_scale,
			Vector2(outer - inner, _WRITING.size.y) * notebook_scale)


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	# Built at natural size, so its spacing there is the page's shrunk by the notebook's scale.
	var spacing := style.sample_spacing / notebook_scale
	var color := palette.color(role)
	var page_fill := palette.box_paper
	var lines: Array[InkLine] = []
	# Back to front: the cover, the page under each page, the pages and their ruled lines, the corners
	# turned down over them, then the pencil lying across it all.
	var cover := _closed(InkBrush.rounded_rect(_COVER, _COVER_CORNER, spacing))
	lines.append(_washed(_seen(_worn(cover, _WEAR.x, 0), false), color, palette.paper.lerp(color, cover_wash)))
	for side: float in [-1.0, 1.0]:
		for layer in range(_UNDER.size() - 1, -1, -1):
			var shift: Vector2 = _UNDER[layer]
			var under := _page_outline(side, false, layer + 2)
			for i in under.size():
				under[i] += Vector2(shift.x * side, shift.y)
			lines.append(_washed(_seen(under, true), color, page_fill, _PAGE_LINE))
	var rule_color := palette.box_paper.lerp(palette.color(rule_role), rule_strength)
	for side: float in [-1.0, 1.0]:
		lines.append(_washed(_seen(_page_outline(side, true, 1), true), color, page_fill, _PAGE_LINE))
		var y := _RULED.x
		while y <= _RULED.y:
			var rule := InkBrush.resample_polyline(PackedVector2Array([Vector2(side * _RULED.z, y),
					Vector2(side * (_PAGE.end.x - _RULED.w), y)]), _EDGE_SPACING)
			lines.append(InkLine.along(_seen(rule, true), rule_color, _RULE_LINE))
			y += rule_spacing
	var turned := palette.box_paper.lerp(color, turned_wash)
	for side: float in [-1.0, 1.0]:
		lines.append(_washed(_seen(_turned_corner(side), true), color, turned, _PAGE_LINE))
	lines.append_array(_pencil(palette, spacing))
	var place := Transform2D(0.0, Vector2.ONE * notebook_scale, 0.0, Vector2.ZERO)
	for line in lines:
		line.path = place * line.path
	return lines


## The outline of the page on [param side] (-1 the left page, 1 the right), before it is seen at an
## angle, its edges worn by the noise [param wear_seed] picks, closed. With [param turned], its turned
## down corner is cut off along the fold.
func _page_outline(side: float, turned: bool, wear_seed: int) -> PackedVector2Array:
	var corners := PackedVector2Array([_PAGE.position, Vector2(_PAGE.end.x, _PAGE.position.y), _PAGE.end,
			Vector2(_PAGE.position.x, _PAGE.end.y), _PAGE.position])
	var true_edge := InkBrush.resample_polyline(corners, _EDGE_SPACING)
	var outline := _worn(true_edge, _WEAR.y, wear_seed)
	# The wear calms toward the spine, so the two pages meet along a straight gutter.
	for i in outline.size():
		outline[i] = true_edge[i].lerp(outline[i], smoothstep(0.0, _GUTTER.y, true_edge[i].x))
	if turned:
		# Everything past the fold goes, worn edge and all, so the cut runs straight along the fold.
		var fold := _fold(side)
		var along := (fold[1] - fold[0]).normalized()
		var out := (fold[2] - fold[0].lerp(fold[1], 0.5)).normalized()
		var reach := _TURNED
		var beyond := PackedVector2Array([fold[0] - along * reach, fold[1] + along * reach,
				fold[1] + along * reach + out * reach * 2.0, fold[0] - along * reach + out * reach * 2.0])
		var kept := Geometry2D.clip_polygons(outline.slice(0, -1), beyond)
		var largest := PackedVector2Array()
		for piece in kept:
			if piece.size() > largest.size():
				largest = piece
		if not largest.is_empty():
			outline = InkBrush.resample_polyline(_closed(largest), _EDGE_SPACING)
	for i in outline.size():
		outline[i] = Vector2(outline[i].x * side, outline[i].y)
	return outline


## The turned down corner of the page on [param side], lying folded over onto the page: the corner
## reflected across its fold.
func _turned_corner(side: float) -> PackedVector2Array:
	var fold := _fold(side)
	var flap := fold[0] + fold[1] - fold[2]
	var outline := InkBrush.resample_polyline(PackedVector2Array([fold[0], fold[1], flap, fold[0]]), _EDGE_SPACING)
	for i in outline.size():
		outline[i] = Vector2(outline[i].x * side, outline[i].y)
	return outline


## The fold of the turned down corner of the page on [param side], on the right page's side of the spine:
## its two ends along the page's edges, then the corner it folds over. The left page's top outer corner
## is turned down, and the right page's bottom outer one.
func _fold(side: float) -> PackedVector2Array:
	var edge := _PAGE.end.x
	var row := _PAGE.position.y if side < 0.0 else _PAGE.end.y
	var inward := 1.0 if side < 0.0 else -1.0
	return PackedVector2Array([Vector2(edge - _TURNED, row), Vector2(edge, row + _TURNED * inward), Vector2(edge, row)])


## The stub of pencil lying across the right page's top outer corner: its sharpened point down onto the
## page, its rubber off past the cover's corner.
func _pencil(palette: InkPalette, spacing: float) -> Array[InkLine]:
	var ink := palette.color(pencil_role)
	var body := palette.paper.lerp(ink, pencil_wash)
	var ends := palette.paper.lerp(ink, pencil_end_wash)
	var half := _PENCIL.y * 0.5
	var start := -_PENCIL.x * 0.5
	var wood := start + _PENCIL_PARTS.x
	var paint := start + _PENCIL_PARTS.y
	var band := start + _PENCIL_PARTS.z
	var rubber := start + _PENCIL_PARTS.w
	var finish := start + _PENCIL.x
	var lay := Transform2D(deg_to_rad(-_PENCIL_TILT), _PENCIL_MIDDLE)
	var lines: Array[InkLine] = []
	var cone := PackedVector2Array([Vector2(start, 0.0), Vector2(paint, -half), Vector2(paint, half), Vector2(start, 0.0)])
	lines.append(_washed(lay * InkBrush.resample_polyline(cone, spacing * 0.5), ink, palette.paper))
	var lead := half * _PENCIL_PARTS.x / (_PENCIL_PARTS.y)
	var point := PackedVector2Array([Vector2(start, 0.0), Vector2(wood, -lead), Vector2(wood, lead), Vector2(start, 0.0)])
	lines.append(_washed(lay * InkBrush.resample_polyline(point, spacing * 0.5), ink, ink))
	var stick := Rect2(paint, -half, band - paint, _PENCIL.y)
	lines.append(_washed(lay * InkBrush.resample_polyline(_rect(stick), spacing), ink, body))
	var facet := PackedVector2Array([Vector2(paint, -half * _FACET), Vector2(band, -half * _FACET)])
	lines.append(InkLine.along(lay * InkBrush.resample_polyline(facet, spacing), ink, _FACET_LINE))
	var tip := Rect2(rubber - _RUBBER_TUCK, -half, finish - rubber + _RUBBER_TUCK, _PENCIL.y)
	lines.append(_washed(lay * InkBrush.rounded_rect(tip, half * _RUBBER_ROUNDING, spacing * 0.5), ink, ends))
	var ferrule := Rect2(band, -half - _BAND_LIP, rubber - band, _PENCIL.y + _BAND_LIP * 2.0)
	lines.append(_washed(lay * InkBrush.resample_polyline(_rect(ferrule), spacing * 0.5), ink, ends))
	for share: float in _BAND_RINGS:
		var x := lerpf(band, rubber, share)
		var ring := PackedVector2Array([Vector2(x, -half - _BAND_LIP), Vector2(x, half + _BAND_LIP)])
		lines.append(InkLine.along(lay * InkBrush.resample_polyline(ring, spacing * 0.5), ink, _RING_LINE))
	return lines


## [param points], lying flat on the cover's plane, as they are seen at an angle: squeezed toward the
## middle the further back they lie, and with [param on_pages], dipping into the gutter near the spine.
func _seen(points: PackedVector2Array, on_pages: bool) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point in points:
		var dip := 0.0
		if on_pages:
			dip = _GUTTER.x * (1.0 - smoothstep(0.0, _GUTTER.y, absf(point.x)))
		out.append(Vector2(point.x * _squeeze(point.y), point.y + dip))
	return out


## How much a row [param y] down the cover is squeezed toward the middle, seen at an angle: none at the
## near edge, the most at the far one.
func _squeeze(y: float) -> float:
	return 1.0 - perspective * clampf(-y / _COVER.size.y, 0.0, 1.0)


## The closed [param outline], ending back on its first point, with its edge worn: pushed in and out by
## up to [param amount] along slow noise picked by [param wear_seed], meeting itself where it closes.
static func _worn(outline: PackedVector2Array, amount: float, wear_seed: int) -> PackedVector2Array:
	var count := outline.size()
	var total := InkBrush.path_length(outline)
	var out := PackedVector2Array()
	var travelled := 0.0
	for i in count:
		if i > 0:
			travelled += outline[i].distance_to(outline[i - 1])
		var along := outline[mini(i + 1, count - 1)] - outline[maxi(i - 1, 0)]
		if i == 0 or i == count - 1:
			along = outline[1] - outline[count - 2]
		var share := travelled / maxf(total, 0.0001)
		# Two runs of noise, one from each end, blended so the edge comes back to where it started.
		var wander := lerpf(InkBrush.noise(travelled / _WEAR.z, wear_seed),
				InkBrush.noise((travelled - total) / _WEAR.z, wear_seed), share)
		out.append(outline[i] + along.normalized().orthogonal() * amount * wander)
	return out


## [param corners] with the first repeated at the end, to draw them as a closed polyline.
static func _closed(corners: PackedVector2Array) -> PackedVector2Array:
	var out := corners.duplicate()
	out.append(corners[0])
	return out


## The corners of [param rect] as a closed polyline.
static func _rect(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end,
			Vector2(rect.position.x, rect.end.y), rect.position])


## A closed line along [param path] with [param wash] inside it, [param width] times the drawing's
## line width.
static func _washed(path: PackedVector2Array, color: Color, wash: Color, width := 1.0) -> InkLine:
	var line := InkLine.along(path, color, width, true)
	line.fill = wash
	return line
