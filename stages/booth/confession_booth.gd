@tool
class_name ConfessionBooth
extends InkDrawing
## The confession booth the dead file into in Chapter 7: a tall wooden booth seen from the front, open so
## the one confessing stands in full view. A peaked roof with a knob on top, an arched opening, a curtain
## gathered back to one side and tied, and a low step to stand on. Ink only, the curtain in a muted wash.
## Its origin is the middle of the step's top, where a confessor stands.

## Width and height of the opening, from the step to where its arch springs.
@export var opening := Vector2(270.0, 272.0):
	set(value):
		opening = value
		queue_redraw()
## How far the top of the arch rises above where it springs.
@export_range(0.0, 200.0, 0.5) var arch_rise := 34.0:
	set(value):
		arch_rise = value
		queue_redraw()
## How thick the booth's sides are beside the opening.
@export_range(4.0, 120.0, 0.5) var post_width := 26.0:
	set(value):
		post_width = value
		queue_redraw()
## How far the body of the booth rises above the top of the arch, to the eaves.
@export_range(0.0, 200.0, 0.5) var header_height := 28.0:
	set(value):
		header_height = value
		queue_redraw()
## How far the roof overhangs the sides, and how high its peak rises above the eaves.
@export var roof := Vector2(22.0, 56.0):
	set(value):
		roof = value
		queue_redraw()
## Radius of the knob on the peak.
@export_range(0.0, 30.0, 0.5) var knob_radius := 7.0:
	set(value):
		knob_radius = value
		queue_redraw()
## Height of the step, and how far it reaches past the sides.
@export var step := Vector2(22.0, 26.0):
	set(value):
		step = value
		queue_redraw()

@export_group("Curtain")
## Whether a curtain hangs in the opening, gathered back to the screen left side.
@export var curtain := true:
	set(value):
		curtain = value
		queue_redraw()
## How far across the opening the curtain hangs at the top, as a share of its width.
@export_range(0.05, 1.0, 0.01) var curtain_reach := 0.32:
	set(value):
		curtain_reach = value
		queue_redraw()
## How far down the opening it is tied back, as a share of its height.
@export_range(0.1, 0.95, 0.01) var tie_height := 0.5:
	set(value):
		tie_height = value
		queue_redraw()
## How far below the tie it flares out again, as a share of the opening's width.
@export_range(0.0, 0.5, 0.01) var flare := 0.14:
	set(value):
		flare = value
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

## Points along each curve of the arch and the curtain, before smoothing.
const _CURVE_POINTS := 14


## The top of the roof's knob, in local space: where words floating over the booth go.
func top() -> Vector2:
	return Vector2(0.0, -_eaves() - roof.y - knob_radius * 2.0)


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var ink := palette.ink
	var lines: Array[InkLine] = []
	var half_open := opening.x * 0.5
	var outer := half_open + post_width
	var eaves := _eaves()
	# The step, behind everything that stands on it.
	var step_rect := Rect2(-outer - step.y, 0.0, (outer + step.y) * 2.0, step.x)
	lines.append(InkLine.along(InkBrush.resample_polyline(_rect(step_rect), spacing), ink, 1.0, true))
	# The body: the sides and the eaves.
	var body := PackedVector2Array([Vector2(-outer, 0.0), Vector2(-outer, -eaves), Vector2(outer, -eaves), Vector2(outer, 0.0)])
	lines.append(InkLine.along(InkBrush.resample_polyline(body, spacing), ink))
	# The roof, overhanging the sides.
	var eave := outer + roof.x
	var roof_line := PackedVector2Array([Vector2(-eave, -eaves), Vector2(0.0, -eaves - roof.y), Vector2(eave, -eaves)])
	lines.append(InkLine.along(InkBrush.resample_polyline(roof_line, spacing), ink, 1.0, true))
	if knob_radius > 0.0:
		lines.append(InkLine.dot(Vector2(0.0, -eaves - roof.y - knob_radius), knob_radius, ink))
	# The opening, up one side, over the arch and down the other.
	var arch := PackedVector2Array([Vector2(-half_open, 0.0)])
	arch.append_array(_arch_points(half_open))
	arch.append(Vector2(half_open, 0.0))
	lines.append(InkLine.along(InkBrush.resample_smooth(arch, false, spacing), ink))
	if curtain:
		lines.append_array(_curtain(half_open, spacing, ink, palette.paper.lerp(palette.color(curtain_role), curtain_wash)))
	return lines


## The curtain: hung from the top of the opening on the screen left, gathered back to the side and
## tied, then falling and flaring to the step. One washed shape, with two folds drawn down it.
func _curtain(half_open: float, spacing: float, ink: Color, wash: Color) -> Array[InkLine]:
	var top_left := Vector2(-half_open, -opening.y)
	var reach := -half_open + opening.x * curtain_reach
	var tie := Vector2(-half_open + opening.x * 0.06, -opening.y * tie_height)
	var foot := Vector2(-half_open + opening.x * flare, 0.0)
	var top_edge := PackedVector2Array()
	for point in _arch_points(half_open):
		if point.x <= reach:
			top_edge.append(point)
	var hem := top_edge[top_edge.size() - 1]
	var shape := PackedVector2Array(top_edge)
	shape.append_array(_curve(hem, tie + Vector2(18.0, -opening.y * 0.12), tie))
	shape.append_array(_curve(tie, tie + Vector2(10.0, opening.y * 0.18), foot))
	shape.append(Vector2(-half_open, 0.0))
	shape.append(top_left)
	var outline := InkBrush.resample_smooth(shape, true, spacing)
	var lines: Array[InkLine] = []
	var curtain_line := InkLine.along(outline, ink, 0.8, true)
	curtain_line.fill = wash
	lines.append(curtain_line)
	for share: float in [0.35, 0.68]:
		var from := top_left.lerp(hem, share)
		var to := tie.lerp(Vector2(-half_open, -opening.y * tie_height), 0.5) + Vector2(4.0, 0.0)
		var fold := _curve(from, from.lerp(to, 0.5) + Vector2(6.0, 0.0), to)
		lines.append(InkLine.along(InkBrush.resample_smooth(fold, false, spacing), ink, 0.6))
	return lines


## The arch over the opening, from its screen left spring to its screen right, through its top.
func _arch_points(half_open: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in _CURVE_POINTS + 1:
		var angle := PI * float(i) / _CURVE_POINTS
		points.append(Vector2(-cos(angle) * half_open, -opening.y - sin(angle) * arch_rise))
	return points


## A gentle curve from [param from] to [param to], pulled toward [param control].
func _curve(from: Vector2, control: Vector2, to: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in _CURVE_POINTS + 1:
		var t := float(i) / _CURVE_POINTS
		points.append(from.lerp(control, t).lerp(control.lerp(to, t), t))
	return points


## How high the eaves are above the step.
func _eaves() -> float:
	return opening.y + arch_rise + header_height


static func _rect(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end,
			Vector2(rect.position.x, rect.end.y)])
