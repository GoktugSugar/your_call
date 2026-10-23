@tool
class_name QuestionMark
extends InkDrawing
## A doodle: the truth, as one big bold question mark. Its hook and stem are a single fat brush
## stroke drawn round as an outline, swelling through the curve and rounded at both ends, with its dot
## below, each with a wash inside. It is drawn as outlines rather than one thick line so it still
## looks right blown up to fill the screen. Its origin is the ground under its middle.
## To grow it large, raise [member mark_scale] rather than the node's scale: scaling the node blows up
## the hand's wobble along with the shape while the line keeps its width, which opens slivers between
## the line and its wash.

## How big the question mark is drawn, as a multiple of its natural size.
@export_range(0.2, 6.0, 0.01) var mark_scale := 1.0:
	set(value):
		mark_scale = value
		queue_redraw()
## How fat the stroke and the dot are, as a multiple of their natural thickness.
@export_range(0.2, 3.0, 0.01) var boldness := 1.0:
	set(value):
		boldness = value
		queue_redraw()
## Palette role of the line.
@export var role := &"ink":
	set(value):
		role = value
		queue_redraw()
## How strongly the wash inside takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()

## The middle of the stroke at natural size, from the loose end of the hook, up over the top and round,
## and down the stem. It leans forward a little, as a hand writes it.
const _SPINE := [Vector2(-53.0, -152.0), Vector2(-53.0, -178.0), Vector2(-35.0, -199.0), Vector2(-7.0, -208.0),
		Vector2(23.0, -205.0), Vector2(46.0, -189.0), Vector2(52.0, -164.0), Vector2(42.0, -140.0),
		Vector2(20.0, -121.0), Vector2(0.0, -104.0), Vector2(-7.0, -86.0), Vector2(-10.0, -70.0)]
## How far the stroke reaches either side of its middle at natural size, along its length: each entry
## is how far along the stroke, from zero to one, and the half width there.
const _THICKNESS := [Vector2(0.0, 11.0), Vector2(0.25, 18.0), Vector2(0.55, 20.0), Vector2(0.8, 15.0), Vector2(1.0, 14.0)]
## Where the outline starts and ends, as a fraction of the way along the stroke, on the outside of
## the hook: a smooth stretch, where the line's run past its own start looks like a pen join.
const _SEAM := 0.3
## The dot under the stem at natural size: its middle, and its radius.
const _DOT := Vector2(-13.0, -26.0)
const _DOT_RADIUS := 19.0


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var wash := palette.paper.lerp(color, wash_strength)
	var lines: Array[InkLine] = []
	var spine := PackedVector2Array()
	for point: Vector2 in _SPINE:
		spine.append(point * mark_scale)
	lines.append(_washed(_stroke_outline(InkBrush.resample_smooth(spine, false, spacing), spacing), color, wash))
	var dot := InkBrush.ellipse(_DOT * mark_scale, Vector2.ONE * _DOT_RADIUS * mark_scale * boldness, spacing, -PI * 0.6)
	lines.append(_washed(dot, color, wash))
	return lines


## The outline round a fat stroke along [param spine]: down one side, round the far end, back up the
## other side and round the near end.
func _stroke_outline(spine: PackedVector2Array, spacing: float) -> PackedVector2Array:
	var n := spine.size()
	var total := InkBrush.path_length(spine)
	var walked := 0.0
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var widths := PackedFloat32Array()
	for i in n:
		if i > 0:
			walked += spine[i].distance_to(spine[i - 1])
		var width := _half_width(walked / total) * mark_scale * boldness
		var normal := (spine[mini(i + 1, n - 1)] - spine[maxi(i - 1, 0)]).normalized().orthogonal()
		left.append(spine[i] + normal * width)
		right.append(spine[i] - normal * width)
		widths.append(width)
	var outline := left
	outline.append_array(_cap(spine[n - 1], spine[n - 1] - spine[n - 2], widths[n - 1], spacing))
	right.reverse()
	outline.append_array(right)
	outline.append_array(_cap(spine[0], spine[0] - spine[1], widths[0], spacing))
	# Start the line partway round the outside of the hook, where its pen join sits on a smooth curve.
	var seam := int(n * _SEAM)
	var turned := outline.slice(seam)
	turned.append_array(outline.slice(0, seam))
	return turned


## The stroke's half width at [param along], from zero at its loose end to one at the foot of its stem.
func _half_width(along: float) -> float:
	for i in range(1, _THICKNESS.size()):
		var from: Vector2 = _THICKNESS[i - 1]
		var to: Vector2 = _THICKNESS[i]
		if along <= to.x:
			return lerpf(from.y, to.y, inverse_lerp(from.x, to.x, along))
	return (_THICKNESS[_THICKNESS.size() - 1] as Vector2).y


## A round end on a stroke, from one side of [param end] round to the other, bulging out along
## [param outward]. The sides run down the left of the stroke and back up its right.
static func _cap(end: Vector2, outward: Vector2, width: float, spacing: float) -> PackedVector2Array:
	var ahead := outward.normalized()
	var side := ahead.orthogonal()
	var steps := maxi(4, ceili(PI * width / spacing))
	var out := PackedVector2Array()
	for k in range(1, steps):
		var angle := PI * k / steps
		out.append(end + (side * cos(angle) + ahead * sin(angle)) * width)
	return out


## A closed line along [param path] with [param wash] inside.
static func _washed(path: PackedVector2Array, color: Color, wash: Color) -> InkLine:
	var line := InkLine.along(path, color, 1.0, true)
	line.fill = wash
	return line
