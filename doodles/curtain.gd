@tool
class_name Curtain
extends InkDrawing
## A doodle: a stage curtain drawn back. A rail across the top with a ball at either end, and rings along
## it that the curtain hangs from, its top edge sagging a little between them. The curtain sweeps down
## from across the rail to one side, where a cord ties it in at the waist with a tassel hanging from the
## knot, and below the cord it flares out again to the floor. Folds run down it to the cord and fan out
## below. Ink only, the curtain in a muted wash like the confession booth's, the rail and the cord in
## darker ones. Its origin is the floor under the middle of the rail.

## Which side the curtain is drawn back and tied to.
enum Side { LEFT, RIGHT }

## Which side the curtain is drawn back and tied to, seen from the front.
@export var side := Side.LEFT:
	set(value):
		side = value
		queue_redraw()
## How big the curtain is drawn, as a multiple of its natural size.
@export_range(0.2, 3.0, 0.01) var curtain_scale := 1.0:
	set(value):
		curtain_scale = value
		queue_redraw()
## Palette role of every line.
@export var line_role := &"ink":
	set(value):
		line_role = value
		queue_redraw()
## Palette role of the curtain's wash.
@export var curtain_role := &"muted":
	set(value):
		curtain_role = value
		queue_redraw()
## How strongly the curtain's wash takes its colour over the paper.
@export_range(0.0, 1.0, 0.01) var curtain_wash := 0.35:
	set(value):
		curtain_wash = value
		queue_redraw()
## How strongly the rail's, the cord's and the tassel's wash takes the curtain's colour over the paper.
@export_range(0.0, 1.0, 0.01) var cord_wash := 0.7:
	set(value):
		cord_wash = value
		queue_redraw()

## The curtain at natural size, drawn back to the left; tied to the right, it mirrors. The rail, the
## radius of its rounded ends, and the middle and radius of the ball on its left end.
const _RAIL := Rect2(-106.0, -229.0, 212.0, 7.0)
const _RAIL_CORNER := 3.5
const _FINIAL := Vector3(-108.0, -225.5, 6.0)
## The rings the curtain hangs from: how far across each one is, and their half width and height, round
## the rail's middle.
const _RINGS := [-100.0, -71.0, -42.0, -13.0, 16.0, 45.0, 74.0]
const _RING_RADII := Vector2(6.0, 9.5)
## How far below the rail's middle the curtain hangs from each ring, and how far it sags between them.
const _HANG := 4.0
const _SAG := 3.5
## The curtain's edge that sweeps from its far top corner down to the cord, then on from the cord, flaring
## out to the floor; and how far across its back edge stands, along the side.
const _SWEEP := [Vector2(74.0, -222.0), Vector2(56.0, -192.0), Vector2(26.0, -160.0), Vector2(-14.0, -134.0),
		Vector2(-48.0, -118.0), Vector2(-70.0, -110.0)]
const _FLARE := [Vector2(-70.0, -110.0), Vector2(-63.0, -80.0), Vector2(-52.0, -46.0), Vector2(-40.0, -14.0),
		Vector2(-33.0, 0.0)]
const _BACK := -106.0
## The hem along the floor, from the end of the flare back toward the back edge, lifting a little between
## the folds that reach it.
const _HEM := [Vector2(-44.0, -3.0), Vector2(-55.0, 0.0), Vector2(-65.0, -3.0), Vector2(-75.0, 0.0),
		Vector2(-85.0, -3.0), Vector2(-94.0, 0.0), Vector2(-100.0, -2.0)]
## The folds: from the top down to the cord, then from the cord fanning out to the floor, each from where
## it starts to where it ends.
const _UPPER_FOLDS := [[Vector2(-85.0, -217.0), Vector2(-98.0, -116.0)], [Vector2(-56.0, -217.0), Vector2(-91.0, -115.0)],
		[Vector2(-27.0, -217.0), Vector2(-84.0, -114.0)], [Vector2(2.0, -217.0), Vector2(-77.0, -112.0)]]
const _LOWER_FOLDS := [[Vector2(-96.0, -103.0), Vector2(-94.0, -6.0)], [Vector2(-88.0, -103.0), Vector2(-75.0, -5.0)],
		[Vector2(-79.0, -103.0), Vector2(-55.0, -4.0)]]
## How far each fold bows toward the curtain's free edge, at its middle.
const _FOLD_BOW := 6.0
## The cord round the curtain's waist: its middle, how far it reaches past the curtain either side, how
## thick it is and how far it bows down in the middle.
const _CORD := Vector2(-88.0, -111.0)
const _CORD_REACH := Vector2(-110.0, -66.0)
const _CORD_THICKNESS := 7.0
const _CORD_BOW := 3.0
## The tassel hanging from the cord's knot: the knot's radius, how far the tassel's string hangs, and its
## skirt's top and bottom half widths and height, with the number of strands drawn down it.
const _KNOT_RADIUS := 5.0
const _STRING := 16.0
const _TASSEL := Vector3(4.0, 9.0, 22.0)
const _STRANDS := 3
## Widths of the curtain's line, its folds, the hem's dips and the tassel's strands, as multiples of the
## drawing's line width.
const _CURTAIN_LINE := 0.8
const _FOLD_LINE := 0.6
const _STRAND_LINE := 0.5


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	# Built at natural size, so its spacing there is the page's shrunk by the curtain's scale.
	var spacing := style.sample_spacing / curtain_scale
	var ink := palette.color(line_role)
	var cloth := palette.color(curtain_role)
	var wash := palette.paper.lerp(cloth, curtain_wash)
	var dark := palette.paper.lerp(cloth, cord_wash)
	var lines: Array[InkLine] = []
	# Back to front: the rail, the curtain and its folds, the rings over its top and the balls on the rail's
	# ends, then the cord tying it in and the tassel hanging from the knot.
	lines.append(_washed(InkBrush.rounded_rect(_RAIL, _RAIL_CORNER, spacing), ink, dark, 1.0))
	lines.append(_washed(_drape(spacing), ink, wash, _CURTAIN_LINE))
	for fold: Array in _UPPER_FOLDS + _LOWER_FOLDS:
		lines.append(InkLine.along(InkBrush.resample_smooth(_bowed(fold[0], fold[1]), false, spacing), ink, _FOLD_LINE))
	var rail_middle := _RAIL.get_center().y
	for across: float in _RINGS:
		lines.append(InkLine.along(InkBrush.ellipse(Vector2(across, rail_middle), _RING_RADII, spacing * 0.5), ink,
				_FOLD_LINE, true))
	for way: float in [1.0, -1.0]:
		var finial := Vector2(_FINIAL.x * way, _FINIAL.y)
		lines.append(_washed(InkBrush.ellipse(finial, Vector2.ONE * _FINIAL.z, spacing * 0.5), ink, dark, 1.0))
	var cord := _cord_band()
	lines.append(_washed(InkBrush.resample_smooth(cord, true, spacing), ink, dark, _CURTAIN_LINE))
	var knot := _CORD + Vector2(0.0, _CORD_BOW)
	var string := PackedVector2Array([knot, knot + Vector2(0.0, _STRING)])
	lines.append(InkLine.along(InkBrush.resample_polyline(string, spacing * 0.5), ink, _FOLD_LINE))
	var top := knot.y + _STRING
	var skirt := PackedVector2Array([Vector2(knot.x - _TASSEL.x, top), Vector2(knot.x + _TASSEL.x, top),
			Vector2(knot.x + _TASSEL.y, top + _TASSEL.z), Vector2(knot.x - _TASSEL.y, top + _TASSEL.z)])
	lines.append(_washed(InkBrush.resample_smooth(skirt, true, spacing * 0.5), ink, dark, _CURTAIN_LINE))
	for strand in _STRANDS:
		var share := (strand + 1.0) / (_STRANDS + 1.0)
		var line := PackedVector2Array([Vector2(knot.x + lerpf(-_TASSEL.x, _TASSEL.x, share), top + _TASSEL.z * 0.3),
				Vector2(knot.x + lerpf(-_TASSEL.y, _TASSEL.y, share), top + _TASSEL.z)])
		lines.append(InkLine.along(InkBrush.resample_polyline(line, spacing * 0.5), ink, _STRAND_LINE))
	lines.append(_washed(InkBrush.ellipse(knot, Vector2.ONE * _KNOT_RADIUS, spacing * 0.5), ink, dark, _CURTAIN_LINE))
	var mirror := -1.0 if side == Side.RIGHT else 1.0
	var place := Transform2D(0.0, Vector2(mirror, 1.0) * curtain_scale, 0.0, Vector2.ZERO)
	for line in lines:
		line.path = place * line.path
	return lines


## The curtain's outline, drawn back to the left, as points about [param spacing] apart in smooth runs
## that meet in its corners: along its top from ring to ring, sagging between them; down its sweep to the
## cord and flaring out to the floor; back along the hem; then straight up its back edge.
func _drape(spacing: float) -> PackedVector2Array:
	var hang := _RAIL.get_center().y + _HANG
	var top := PackedVector2Array([Vector2(_BACK, hang)])
	for i in range(1, _RINGS.size()):
		var from: float = _RINGS[i - 1]
		var to: float = _RINGS[i]
		top.append(Vector2((from + to) * 0.5, hang + _SAG))
		top.append(Vector2(to, hang))
	var sweep := PackedVector2Array([top[top.size() - 1]])
	for point: Vector2 in _SWEEP.slice(1) + _FLARE.slice(1):
		sweep.append(point)
	var hem := PackedVector2Array([sweep[sweep.size() - 1]])
	for point: Vector2 in _HEM:
		hem.append(point)
	hem.append(Vector2(_BACK, 0.0))
	var outline := InkBrush.resample_smooth(top, false, spacing)
	for run in [InkBrush.resample_smooth(sweep, false, spacing), InkBrush.resample_smooth(hem, false, spacing),
			InkBrush.resample_polyline(PackedVector2Array([Vector2(_BACK, 0.0), Vector2(_BACK, hang)]), spacing)]:
		outline.append_array((run as PackedVector2Array).slice(1))
	return outline


## A gentle curve from [param from] to [param to], bowed toward the curtain's free edge at its middle.
static func _bowed(from: Vector2, to: Vector2) -> PackedVector2Array:
	var bow := (to - from).normalized().orthogonal() * _FOLD_BOW
	if bow.x < 0.0:
		bow = -bow
	return PackedVector2Array([from, from.lerp(to, 0.5) + bow, to])


## The cord round the curtain's waist, as the corners of a band bowed down in the middle.
static func _cord_band() -> PackedVector2Array:
	var half := _CORD_THICKNESS * 0.5
	var middle := _CORD + Vector2(0.0, _CORD_BOW)
	return PackedVector2Array([Vector2(_CORD_REACH.x, _CORD.y - half), middle - Vector2(0.0, half),
			Vector2(_CORD_REACH.y, _CORD.y - half), Vector2(_CORD_REACH.y, _CORD.y + half),
			middle + Vector2(0.0, half), Vector2(_CORD_REACH.x, _CORD.y + half)])


## A closed line along [param path] with [param wash] inside it, [param width] times the drawing's
## line width.
static func _washed(path: PackedVector2Array, color: Color, wash: Color, width: float) -> InkLine:
	var line := InkLine.along(path, color, width, true)
	line.fill = wash
	return line
