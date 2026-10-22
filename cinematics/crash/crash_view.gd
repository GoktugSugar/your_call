@tool
class_name CrashView
extends InkDrawing
## The last thing the judge saw, in pale ink on black: a night road running to a vanishing point, its
## centre line streaming by, and two headlights bearing down. [CrashCinematic] drives it.
## Its origin is the middle of the screen.

## How close the headlights are: 0 is far down the road, 1 is right on top of you.
@export_range(0.0, 1.0, 0.001) var approach := 0.0:
	set(value):
		approach = value
		queue_redraw()
## How far the centre line has streamed past, in dashes.
@export var dash_phase := 0.0:
	set(value):
		dash_phase = value
		queue_redraw()
## When set, the frame is lost: nothing is drawn, like a gap in a memory.
@export var dropout := false:
	set(value):
		dropout = value
		queue_redraw()

@export_group("Road")
## Height of the vanishing point, from the middle of the screen. Negative is up.
@export var horizon_y := -70.0
## Height of the road's near edge, from the middle of the screen.
@export var near_y := 560.0
## Half the road's width at the vanishing point.
@export_range(0.0, 200.0, 0.5) var far_half_width := 14.0
## Half the road's width at the bottom of the screen.
@export_range(0.0, 2000.0, 1.0) var near_half_width := 980.0
## How many dashes the centre line has between the horizon and the bottom of the screen.
@export_range(1, 30) var dash_count := 7
## Length of a dash, as a share of the road's depth.
@export_range(0.01, 0.5, 0.005) var dash_length := 0.06
## Width of a dash far down the road and close up, as a multiple of the line width.
@export var dash_width := Vector2(0.4, 2.6)
## Width of the road's edges, as a multiple of the line width.
@export_range(0.0, 8.0, 0.05) var edge_width := 0.9
## How strong the road's ink is, as an alpha.
@export_range(0.0, 1.0, 0.01) var road_alpha := 0.45

@export_group("Headlights")
## How far apart the headlights are when they arrive.
@export_range(0.0, 3000.0, 1.0) var light_spread := 880.0
## Radius of each headlight when it arrives.
@export_range(1.0, 600.0, 1.0) var light_radius := 150.0
## Height of the headlights when they arrive, from the middle of the screen.
@export var light_near_y := 40.0
## How small the headlights start, far down the road, as a share of their final size.
@export_range(0.001, 1.0, 0.001) var light_far_scale := 0.03
## How far the glow reaches, as a multiple of the light's radius.
@export_range(1.0, 8.0, 0.05) var glow_reach := 2.6
## Opacity of the glow at the rim of the light.
@export_range(0.0, 1.0, 0.005) var glow_alpha := 0.35
## How fast the glow falls away: 1 is even, higher hugs the light.
@export_range(0.5, 6.0, 0.05) var glow_falloff := 2.0
## How many rings the glow's falloff is traced through. More follows the curve more closely.
@export_range(1, 32) var glow_rings := 8

## Sampling of the round shapes, in pixels.
const _ROUND_SPACING := 6.0
## Wedges round each glow.
const _GLOW_SEGMENTS := 72

## The glow is light, not ink. It goes on a canvas item of its own under the lines, without the ink
## material, so its falloff blends smoothly instead of in bands.
var _glow_item: RID


func _ready() -> void:
	super()
	_glow_item = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(_glow_item, get_canvas_item())
	RenderingServer.canvas_item_set_draw_behind_parent(_glow_item, true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and _glow_item.is_valid():
		RenderingServer.free_rid(_glow_item)


## How large the headlights look at [param progress]: one over the distance, so they swell as they come.
func light_scale(progress: float) -> float:
	var far_distance := 1.0 / light_far_scale
	return 1.0 / lerpf(far_distance, 1.0, clampf(progress, 0.0, 1.0))


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var lines: Array[InkLine] = []
	if dropout:
		return lines
	var spacing := style.sample_spacing
	var chalk := Color(palette.paper, road_alpha)
	for side: float in [-1.0, 1.0]:
		var edge := PackedVector2Array([Vector2(far_half_width * side, horizon_y), Vector2(near_half_width * side, near_y)])
		lines.append(InkLine.along(InkBrush.resample_polyline(edge, spacing), chalk, edge_width))
	for k in dash_count:
		var start := fposmod(float(k) / dash_count + dash_phase / dash_count, 1.0)
		var end := minf(start + dash_length, 1.0)
		var near_start := start * start
		var near_end := end * end
		var dash := PackedVector2Array([Vector2(0.0, lerpf(horizon_y, near_y, near_start)), Vector2(0.0, lerpf(horizon_y, near_y, near_end))])
		lines.append(InkLine.along(InkBrush.resample_polyline(dash, spacing), chalk, lerpf(dash_width.x, dash_width.y, near_end)))
	for center: Vector2 in _light_centers():
		var core := InkLine.along(InkBrush.ellipse(center, Vector2.ONE * _light_radius(), _ROUND_SPACING), palette.paper, 1.0, true)
		core.fill = palette.paper
		lines.append(core)
	return lines


func _draw() -> void:
	if _glow_item.is_valid():
		RenderingServer.canvas_item_clear(_glow_item)
		if not dropout:
			for center: Vector2 in _light_centers():
				_add_glow(center, _light_radius())
	super()


## A soft disc of light round a headlight: full at its rim, falling away to nothing at [member glow_reach].
## The rings share one colour and fade only in alpha, which the triangles blend smoothly between them.
func _add_glow(center: Vector2, radius: float) -> void:
	var paper := InkPalette.get_default().paper
	var points := PackedVector2Array([center])
	var colors := PackedColorArray([Color(paper, glow_alpha)])
	for ring in glow_rings + 1:
		var t := float(ring) / glow_rings
		var color := Color(paper, glow_alpha * pow(1.0 - t, glow_falloff))
		for segment in _GLOW_SEGMENTS:
			points.append(center + Vector2.from_angle(TAU * segment / _GLOW_SEGMENTS) * radius * lerpf(1.0, glow_reach, t))
			colors.append(color)
	var indices := PackedInt32Array()
	for segment in _GLOW_SEGMENTS:
		indices.append_array([0, 1 + segment, 1 + (segment + 1) % _GLOW_SEGMENTS])
	for ring in glow_rings:
		var inner := 1 + ring * _GLOW_SEGMENTS
		var outer := inner + _GLOW_SEGMENTS
		for segment in _GLOW_SEGMENTS:
			var next := (segment + 1) % _GLOW_SEGMENTS
			indices.append_array([inner + segment, outer + segment, outer + next, inner + segment, outer + next, inner + next])
	RenderingServer.canvas_item_add_triangle_array(_glow_item, indices, points, colors)


func _light_centers() -> PackedVector2Array:
	var size := light_scale(approach)
	var y := lerpf(horizon_y, light_near_y, size)
	return PackedVector2Array([Vector2(-light_spread * 0.5 * size, y), Vector2(light_spread * 0.5 * size, y)])


func _light_radius() -> float:
	return light_radius * light_scale(approach)
