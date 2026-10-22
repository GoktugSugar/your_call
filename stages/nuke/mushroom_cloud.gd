@tool
class_name MushroomCloud
extends InkDrawing
## A small mushroom cloud in ink: red lines, with an amber wash in its stem and its billowing cap. Drawn
## on, its stem rises from the ground, the cap billows out on top, a skirt rings the stem and a puff of
## dust rolls along the ground. No gore, nothing photographic. Its origin is its foot.

## How tall it stands, ground to the top of the cap.
@export_range(20.0, 400.0, 1.0) var height := 100.0:
	set(value):
		height = value
		queue_redraw()
## Half the cap's width and height.
@export var cap_radii := Vector2(42.0, 25.0):
	set(value):
		cap_radii = value
		queue_redraw()
## Width of the stem at the ground and under the cap.
@export var stem_widths := Vector2(22.0, 13.0):
	set(value):
		stem_widths = value
		queue_redraw()
## How many billows the cap has round its edge.
@export_range(3, 16) var billows := 8:
	set(value):
		billows = value
		queue_redraw()
## How far each billow bulges, as a share of the cap's size.
@export_range(0.0, 0.5, 0.01) var billow_depth := 0.14:
	set(value):
		billow_depth = value
		queue_redraw()
## How far up the stem its skirt rings it, as a share of the stem.
@export_range(0.0, 1.0, 0.01) var skirt_height := 0.5:
	set(value):
		skirt_height = value
		queue_redraw()
## Half the skirt's width and height.
@export var skirt_radii := Vector2(20.0, 5.0):
	set(value):
		skirt_radii = value
		queue_redraw()
## Half the width and the height of the puff of dust at its foot.
@export var dust_size := Vector2(46.0, 13.0):
	set(value):
		dust_size = value
		queue_redraw()
## Palette role of the lines.
@export var line_role := &"red":
	set(value):
		line_role = value
		queue_redraw()
## Palette role of the washes.
@export var wash_role := &"amber":
	set(value):
		wash_role = value
		queue_redraw()
## How strongly the washes take their colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash := 0.5:
	set(value):
		wash = value
		queue_redraw()

## Points per billow round the cap's edge, before it is smoothed.
const _BILLOW_POINTS := 4
## Bumps along the puff of dust.
const _DUST_BUMPS := 5


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(line_role)
	var fill := palette.paper.lerp(palette.color(wash_role), wash)
	var cap_middle := Vector2(0.0, -height + cap_radii.y)
	var stem_top := cap_middle.y + cap_radii.y * 0.6
	var lines: Array[InkLine] = []
	# The stem first, up one side and down the other, so it rises as it draws on.
	var stem := PackedVector2Array([Vector2(-stem_widths.x * 0.5, 0.0), Vector2(-stem_widths.y * 0.5, stem_top),
			Vector2(stem_widths.y * 0.5, stem_top), Vector2(stem_widths.x * 0.5, 0.0)])
	var stem_line := InkLine.along(InkBrush.resample_smooth(stem, true, spacing), color, 1.0, true)
	stem_line.fill = fill
	lines.append(stem_line)
	var cap := InkLine.along(InkBrush.resample_smooth(_billowed(cap_middle), true, spacing), color, 1.0, true)
	cap.fill = fill
	lines.append(cap)
	var skirt_middle := Vector2(0.0, stem_top * skirt_height)
	lines.append(InkLine.along(InkBrush.ellipse(skirt_middle, skirt_radii, spacing * 0.5, PI), color, 0.8, true))
	lines.append(InkLine.along(InkBrush.resample_smooth(_dust(), false, spacing), color, 0.8))
	return lines


## The cap's edge: an ellipse round [param middle] that bulges into billows.
func _billowed(middle: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	var count := billows * _BILLOW_POINTS
	for i in count:
		var angle := TAU * i / count
		var bulge := 1.0 + billow_depth * absf(sin(angle * billows * 0.5))
		points.append(middle + Vector2(cos(angle) * cap_radii.x, sin(angle) * cap_radii.y) * bulge)
	return points


## A low rolling puff of dust along the ground, from one side of the stem to the other.
func _dust() -> PackedVector2Array:
	var points := PackedVector2Array()
	var count := _DUST_BUMPS * 2
	for i in count + 1:
		var along := float(i) / count
		var x := lerpf(-dust_size.x, dust_size.x, along)
		var rise := sin(along * PI) * dust_size.y * (0.75 if i % 2 == 0 else 1.0)
		points.append(Vector2(x, -rise))
	return points
