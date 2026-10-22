@tool
class_name FutureBaby
extends BabyBundle
## The future baby: the same swaddled baby, with two cues kept one step removed from any real person.
## A small square mustache sits on its face just under the eyes, a little block of ink, and a paintbrush
## lies on the ground beside the bundle with a dab of paint on the tip of its bristles. Its origin is the
## ground under the middle of the bundle.

## Where the bristles are widest, as a share of their length from the band, and how wide they are there,
## as a multiple of the brush's width.
const _BRISTLE_SWELL := Vector2(0.3, 1.1)

@export_group("Mustache")
## A small square mustache just under the eyes.
@export var mustache := true:
	set(value):
		mustache = value
		queue_redraw()
## Width of the mustache along its bottom edge, and its height.
@export var mustache_size := Vector2(4.4, 2.3):
	set(value):
		mustache_size = value
		queue_redraw()
## How much narrower the mustache is along its flat top than along its bottom, as a share of its width.
@export_range(0.0, 0.8, 0.01) var mustache_taper := 0.12:
	set(value):
		mustache_taper = value
		queue_redraw()
## How far below the middle of the head the middle of the mustache sits.
@export_range(-10.0, 15.0, 0.1) var mustache_drop := 3.3:
	set(value):
		mustache_drop = value
		queue_redraw()
## Width of the mustache's edge, as a multiple of the baby's line.
@export_range(0.1, 2.0, 0.05) var mustache_line := 0.45

@export_group("Paintbrush")
## A paintbrush lying on the ground beside the bundle, its bristles toward the baby.
@export var paintbrush := true:
	set(value):
		paintbrush = value
		queue_redraw()
## Length of the brush, from the end of its handle to the tip of its bristles.
@export_range(5.0, 120.0, 0.5) var brush_length := 38.0:
	set(value):
		brush_length = value
		queue_redraw()
## Thickness of the brush where the bristles meet the handle.
@export_range(1.0, 30.0, 0.5) var brush_width := 7.0:
	set(value):
		brush_width = value
		queue_redraw()
## Shares of the brush's length taken by the metal band and by the bristles. The handle takes the rest.
@export var brush_shares := Vector2(0.12, 0.34):
	set(value):
		brush_shares = value
		queue_redraw()
## Gap between the tip of the bristles and the end of the blanket.
@export_range(-20.0, 60.0, 0.5) var brush_gap := 5.0:
	set(value):
		brush_gap = value
		queue_redraw()
## How far the tip end of the brush tips up off the ground, in degrees.
@export_range(-45.0, 45.0, 0.5) var brush_tilt := 0.0:
	set(value):
		brush_tilt = value
		queue_redraw()
## How much of the bristles the paint covers, from the tip, as a share of their length.
@export_range(0.0, 1.0, 0.01) var paint_share := 0.45:
	set(value):
		paint_share = value
		queue_redraw()
## Palette role of the paint: an identification colour, never red.
@export var paint_role := &"sky":
	set(value):
		paint_role = value
		queue_redraw()
## How strongly the paint takes its colour over the paper.
@export_range(0.0, 1.0, 0.01) var paint_wash := 0.6:
	set(value):
		paint_wash = value
		queue_redraw()
## Width of the handle's line, as a multiple of the baby's line.
@export_range(0.1, 2.0, 0.05) var handle_line := 1.0
## Width of the line round the band and the bristles, as a multiple of the baby's line.
@export_range(0.1, 2.0, 0.05) var brush_line := 0.7


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var lines := super(style, palette)
	if mustache:
		var middle := _head_centre() + Vector2(0.0, mustache_drop)
		var half := mustache_size * 0.5
		var top := half.x * (1.0 - mustache_taper)
		var corners := PackedVector2Array([middle + Vector2(-top, -half.y), middle + Vector2(top, -half.y),
				middle + half, middle + Vector2(-half.x, half.y), middle + Vector2(-top, -half.y)])
		var block := InkLine.along(InkBrush.resample_polyline(corners, spacing * 0.25), palette.ink, mustache_line, true)
		block.fill = palette.ink
		lines.append(block)
	if paintbrush:
		_add_paintbrush(lines, palette, spacing)
	return lines


## The paintbrush lying on the ground to the left of the blanket, its tip toward the baby: a handle that
## tapers to its end, a metal band, and the bristles with their tip dipped in paint.
func _add_paintbrush(lines: Array[InkLine], palette: InkPalette, spacing: float) -> void:
	var along := Vector2.RIGHT.rotated(-deg_to_rad(brush_tilt))
	var across := -along.orthogonal()
	var half := brush_width * 0.5
	var start := Vector2(_blanket().position.x - brush_gap - brush_length * along.x, -half)
	var bristles_from := brush_length * (1.0 - brush_shares.y)
	var band_from := bristles_from - brush_length * brush_shares.x
	var place := func(u: float, v: float) -> Vector2: return start + along * u + across * v
	lines.append(InkLine.along(InkBrush.resample_polyline(PackedVector2Array([place.call(0.0, 0.0),
			place.call(band_from, 0.0)]), spacing), palette.ink, handle_line))
	# The bristles swell a little past the band, then come to a point at the tip.
	var swell_at := lerpf(bristles_from, brush_length, _BRISTLE_SWELL.x)
	var bristles := InkBrush.resample_smooth(PackedVector2Array([place.call(bristles_from, -half),
			place.call(swell_at, -half * _BRISTLE_SWELL.y), place.call(brush_length, 0.0)]), false, spacing * 0.5)
	bristles.append_array(InkBrush.resample_smooth(PackedVector2Array([place.call(brush_length, 0.0),
			place.call(swell_at, half * _BRISTLE_SWELL.y), place.call(bristles_from, half)]), false, spacing * 0.5).slice(1))
	bristles.append_array(InkBrush.resample_polyline(PackedVector2Array([place.call(bristles_from, half),
			place.call(bristles_from, -half)]), spacing * 0.5).slice(1))
	var outline := InkLine.along(bristles, palette.ink, brush_line, true)
	outline.fill = palette.paper
	lines.append(outline)
	var paint := palette.color(paint_role)
	var dipped_from := lerpf(brush_length, bristles_from, paint_share)
	var tip := PackedVector2Array()
	for point in bristles:
		if (point - start).dot(along) >= dipped_from:
			tip.append(point)
	if tip.size() > 2:
		var dab := InkLine.along(tip, paint, brush_line, true)
		dab.fill = palette.paper.lerp(paint, paint_wash)
		lines.append(dab)
	var band := PackedVector2Array([place.call(band_from, -half), place.call(bristles_from, -half),
			place.call(bristles_from, half), place.call(band_from, half), place.call(band_from, -half)])
	var ring := InkLine.along(InkBrush.resample_polyline(band, spacing * 0.5), palette.ink, brush_line, true)
	ring.fill = palette.paper
	lines.append(ring)
