@tool
class_name Darkness
extends InkDrawing
## The dark the imp swears is hiding a crowd: a heavy ink wash over the far end of a track, its near
## edge feathered into scribbles that thin out toward the light. It hides whatever is behind it,
## the trolley included, until it is lifted.

## The area the dark covers, in this node's space. Its left side is the feathered edge.
@export var area := Rect2(0.0, -150.0, 900.0, 220.0):
	set(value):
		area = value
		queue_redraw()
## How wide the feathered edge is, in pixels.
@export_range(0.0, 600.0, 1.0) var feather := 170.0:
	set(value):
		feather = value
		queue_redraw()
## Distance between the scribbles in the feathered edge.
@export_range(2.0, 60.0, 0.5) var scribble_spacing := 7.0:
	set(value):
		scribble_spacing = value
		queue_redraw()
## How far each scribble zigzags across, in pixels.
@export_range(0.0, 60.0, 0.5) var scribble_swing := 14.0:
	set(value):
		scribble_swing = value
		queue_redraw()
## How far the wash's outline wanders in and out, in pixels.
@export_range(0.0, 60.0, 0.5) var ragged := 14.0:
	set(value):
		ragged = value
		queue_redraw()
## How opaque the wash is: 1 hides everything behind it.
@export_range(0.0, 1.0, 0.01) var depth := 0.96:
	set(value):
		depth = value
		queue_redraw()
## Seconds the dark takes to lift.
@export_range(0.0, 5.0, 0.01) var lift_duration := 1.1


## Lifts the dark, showing what was behind it all along.
func lift() -> void:
	await dissolve_away(lift_duration).finished


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var lines: Array[InkLine] = []
	var edge := area.position.x + feather
	var x := area.position.x
	var row := 0
	while x < edge:
		# Each scribble zigzags down at a slant. Toward the wash they reach further and crowd closer.
		var weight := (x - area.position.x) / maxf(feather, 0.001)
		var shrink := area.size.y * 0.3 * (1.0 - weight)
		var top := area.position.y + (0.5 + 0.5 * InkBrush.noise(row * 0.61, _seed)) * shrink
		var bottom := area.end.y - (0.5 + 0.5 * InkBrush.noise(row * 0.61 + 40.0, _seed)) * shrink
		var scribble := PackedVector2Array()
		var y := top
		var side := 1.0
		var turn := 0
		while y < bottom:
			var swing := scribble_swing * (0.75 + 0.25 * InkBrush.noise(turn * 1.7 + row * 5.3, _seed))
			scribble.append(Vector2(x + side * swing * 0.5 + (y - top) * 0.12, y))
			side = -side
			y += scribble_swing * (0.55 + 0.25 * InkBrush.noise(turn * 0.9 + row * 2.1, _seed))
			turn += 1
		if scribble.size() > 1:
			lines.append(InkLine.along(InkBrush.resample_polyline(scribble, spacing), Color(palette.ink, lerpf(0.15, depth, weight)), 0.9))
		x += scribble_spacing * lerpf(1.6, 0.7, weight)
		row += 1
	# The wash itself, its outline pushed in and out so no edge runs straight.
	var body := Rect2(edge, area.position.y, area.end.x - edge, area.size.y)
	var outline := InkBrush.rounded_rect(body, minf(body.size.y * 0.3, 40.0), spacing)
	var centre := body.get_center()
	for i in outline.size():
		var out := (outline[i] - centre).normalized()
		outline[i] += out * ragged * InkBrush.noise(i * spacing / 40.0, _seed + 7)
	var wash := InkLine.along(outline, Color(palette.ink, depth), 1.0, true)
	wash.fill = Color(palette.ink, depth)
	lines.append(wash)
	return lines
