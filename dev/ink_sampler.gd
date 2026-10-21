@tool
extends InkDrawing
## Development only: a page of sample lines for judging the ink look at a glance.


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var s := style.sample_spacing
	var lines: Array[InkLine] = []
	lines.append(InkLine.along(InkBrush.resample_polyline(PackedVector2Array([Vector2(200, 200), Vector2(800, 200)]), s), palette.ink))
	lines.append(InkLine.along(InkBrush.resample_smooth(PackedVector2Array([
			Vector2(200, 330), Vector2(400, 270), Vector2(600, 390), Vector2(800, 310)]), false, s), palette.ink))
	lines.append(InkLine.along(InkBrush.resample_polyline(PackedVector2Array([
			Vector2(200, 560), Vector2(320, 450), Vector2(440, 560), Vector2(560, 450)]), s), palette.ink))
	var circle := InkLine.along(InkBrush.ellipse(Vector2(1100, 260), Vector2(60, 60), s, -PI * 0.6), palette.ink, 1.0, true)
	lines.append(circle)
	var washed := InkLine.along(InkBrush.ellipse(Vector2(1350, 260), Vector2(90, 60), s, -PI * 0.6), palette.ink, 1.0, true)
	washed.fill = Color(palette.pink, 0.45)
	lines.append(washed)
	lines.append(InkLine.dot(Vector2(1080, 250), 2.6, palette.ink))
	lines.append(InkLine.dot(Vector2(1120, 250), 2.6, palette.ink))
	lines.append(InkLine.along(InkBrush.resample_polyline(PackedVector2Array([Vector2(1000, 520), Vector2(1080, 420)]), s), palette.amber, 1.6))
	lines.append(InkLine.along(InkBrush.resample_smooth(PackedVector2Array([
			Vector2(1300, 420), Vector2(1600, 420), Vector2(1600, 600), Vector2(1300, 600)]), true, s), palette.red, 1.0, true))
	return lines
