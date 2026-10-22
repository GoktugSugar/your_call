@tool
class_name FoulIceCream
extends InkDrawing
## A doodle: an ice cream cone whose scoop has exactly the swirl of [SweetPoop], the ice cream that
## tastes like shit. An orange cone with a crosshatch, under a pink scoop.
## Its origin is the tip of the cone.

## Height of the cone.
@export_range(20.0, 200.0, 0.5) var cone_height := 112.0:
	set(value):
		cone_height = value
		queue_redraw()
## Width of the cone's rim.
@export_range(20.0, 200.0, 0.5) var cone_width := 84.0:
	set(value):
		cone_width = value
		queue_redraw()
## How far the scoop sinks into the cone's rim.
@export_range(0.0, 40.0, 0.5) var scoop_sink := 8.0:
	set(value):
		scoop_sink = value
		queue_redraw()
## How big the scoop is drawn, as a multiple of the poop's natural size.
@export_range(0.2, 3.0, 0.01) var scoop_scale := 0.9:
	set(value):
		scoop_scale = value
		queue_redraw()
## Palette role of the cone.
@export var cone_role := &"orange":
	set(value):
		cone_role = value
		queue_redraw()
## Palette role of the scoop.
@export var scoop_role := &"pink":
	set(value):
		scoop_role = value
		queue_redraw()
## How strongly the cone's wash takes its colour over the paper.
@export_range(0.0, 1.0, 0.01) var cone_wash := 0.4:
	set(value):
		cone_wash = value
		queue_redraw()
## How strongly the scoop's wash takes its colour over the paper.
@export_range(0.0, 1.0, 0.01) var scoop_wash := 0.4:
	set(value):
		scoop_wash = value
		queue_redraw()

## Where the crosshatch lines cross the cone's edges, as fractions of its height from the tip.
const _HATCH_FROM := [0.4, 0.62, 0.84]
## How far down the cone each hatch line runs as it crosses, as a fraction of its height.
const _HATCH_DROP := 0.24


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var cone_color := palette.color(cone_role)
	var half := cone_width * 0.5
	var rim := -cone_height
	var lines: Array[InkLine] = []
	var cone := InkLine.along(InkBrush.resample_polyline(PackedVector2Array([Vector2.ZERO, Vector2(-half, rim),
			Vector2(half, rim), Vector2.ZERO]), spacing), cone_color, 1.0, true)
	cone.fill = palette.paper.lerp(cone_color, cone_wash)
	lines.append(cone)
	for from: float in _HATCH_FROM:
		var to: float = from - _HATCH_DROP
		lines.append(_hatch(_edge(from, -1.0), _edge(to, 1.0), cone_color, spacing))
		lines.append(_hatch(_edge(from, 1.0), _edge(to, -1.0), cone_color, spacing))
	var scoop_color := palette.color(scoop_role)
	lines.append_array(SweetPoop.swirl_lines(Vector2(0.0, rim + scoop_sink), scoop_scale, scoop_color,
			palette.paper.lerp(scoop_color, scoop_wash), spacing))
	return lines


## The point on the cone's left (-1) or right (1) edge at [param height_share] of its height.
func _edge(height_share: float, side: float) -> Vector2:
	return Vector2(cone_width * 0.5 * side, -cone_height) * height_share


func _hatch(from: Vector2, to: Vector2, color: Color, spacing: float) -> InkLine:
	return InkLine.along(InkBrush.resample_polyline(PackedVector2Array([from, to]), spacing), color, 0.6)
