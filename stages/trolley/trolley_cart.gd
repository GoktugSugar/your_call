@tool
class_name TrolleyCart
extends InkDrawing
## The trolley: a little tram in ink, seen side on and facing right. Its body is filled with paper
## so it hides whatever it rolls past. Its origin is where its wheels meet the rail.

## Radius of each wheel.
@export_range(4.0, 40.0, 0.5) var wheel_radius := 13.0:
	set(value):
		wheel_radius = value
		queue_redraw()

const _BODY := [Vector2(-82.0, -30.0), Vector2(-82.0, -96.0), Vector2(-74.0, -104.0), Vector2(70.0, -104.0),
		Vector2(82.0, -92.0), Vector2(84.0, -30.0)]
const _ROOF := [Vector2(-88.0, -109.0), Vector2(88.0, -109.0)]
const _BELT := [Vector2(-82.0, -52.0), Vector2(84.0, -52.0)]
const _WINDOWS := [Rect2(-68.0, -92.0, 30.0, 28.0), Rect2(-16.0, -92.0, 30.0, 28.0), Rect2(36.0, -92.0, 30.0, 28.0)]
const _WHEEL_X := [-50.0, 50.0]
const _POLE := [Vector2(-24.0, -109.0), Vector2(-58.0, -152.0)]
const _POLE_SHOE_RADIUS := 3.5


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var lines: Array[InkLine] = []
	var body := InkLine.along(InkBrush.resample_polyline(_closed(_BODY), spacing), palette.ink, 1.0, true)
	body.fill = palette.paper
	lines.append(body)
	lines.append(_straight(_ROOF, palette.ink, spacing))
	lines.append(_straight(_BELT, palette.ink, spacing, 0.8))
	for window: Rect2 in _WINDOWS:
		var corners := [window.position, Vector2(window.end.x, window.position.y), window.end, Vector2(window.position.x, window.end.y)]
		lines.append(InkLine.along(InkBrush.resample_polyline(_closed(corners), spacing), palette.ink, 0.8, true))
	for x: float in _WHEEL_X:
		var wheel := InkLine.along(InkBrush.ellipse(Vector2(x, -wheel_radius), Vector2.ONE * wheel_radius, spacing),
				palette.ink, 1.0, true)
		wheel.fill = palette.paper
		lines.append(wheel)
		lines.append(InkLine.dot(Vector2(x, -wheel_radius), 2.5, palette.ink))
	lines.append(_straight(_POLE, palette.ink, spacing, 0.8))
	lines.append(InkLine.dot(_POLE[1], _POLE_SHOE_RADIUS, palette.ink))
	return lines


static func _straight(points: Array, color: Color, spacing: float, width := 1.0) -> InkLine:
	return InkLine.along(InkBrush.resample_polyline(PackedVector2Array(points), spacing), color, width)


static func _closed(points: Array) -> PackedVector2Array:
	var out := PackedVector2Array(points)
	out.append(points[0])
	return out
