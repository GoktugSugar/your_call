@tool
class_name InkDrawing
extends Node2D
## A node drawn in ink. It draws its lines with the shared wobble, redraws on every boil tick,
## and can draw itself on line by line or dissolve away.
## Drawings that build their lines in code override [method _build_lines].

## Authored lines, in this node's local space, drawn in order.
@export var strokes: Array[InkStroke] = []:
	set(value):
		for stroke in strokes:
			if stroke != null and stroke.changed.is_connected(queue_redraw):
				stroke.changed.disconnect(queue_redraw)
		strokes = value
		for stroke in strokes:
			if stroke != null:
				stroke.changed.connect(queue_redraw)
		queue_redraw()
## Width of every line, as a multiple of the style's line width.
@export_range(0.0, 8.0, 0.05) var width_scale := 1.0:
	set(value):
		width_scale = value
		queue_redraw()
## Recolours every line to this palette role. Leave empty to keep each line's own colour.
@export var color_override: StringName = &"":
	set(value):
		color_override = value
		queue_redraw()
## Keeps lines the same width on screen however this node is scaled, the way a pen would.
@export var constant_line_width := true
## Seed for the hand's wobble. Zero picks one from the node's place in its scene.
@export var wobble_seed := 0
## A line style of this drawing's own, for a drawing whose line differs from the rest of the page.
## Leave empty to use the shared style.
@export var style_override: InkStyle:
	set(value):
		style_override = value
		queue_redraw()
## How much of the drawing is on the page, drawn in line order: 0 is blank, 1 is whole.
@export_range(0.0, 1.0, 0.001) var reveal := 1.0:
	set(value):
		reveal = value
		queue_redraw()
## Eats the drawing away like ink soaking into paper: 0 is whole, 1 is gone.
@export_range(0.0, 1.0, 0.001) var dissolve := 0.0:
	set(value):
		dissolve = value
		_apply_dissolve()

var _seed := 0
var _dissolve_material: ShaderMaterial
## The ink of this drawing's lines, kept to lay down again while they stay as they were.
var _cache := InkCache.new()


func _ready() -> void:
	_seed = wobble_seed if wobble_seed != 0 else InkPainter.seed_for(self)
	InkPainter.attach(self)
	_apply_dissolve()


func _draw() -> void:
	var counting := InkStats.enabled
	var started := Time.get_ticks_usec() if counting else 0
	var style := style_override if style_override != null else InkStyle.get_default()
	var lines := _build_lines(style, InkPalette.get_default())
	var built := Time.get_ticks_usec() if counting else 0
	var recolor := Color.TRANSPARENT
	if color_override != &"":
		recolor = InkPalette.get_default().color(color_override)
	if counting:
		InkStats.record_build(self, built - started)
	InkPainter.paint(self, lines, style.width * width_scale * _width_compensation(),
			_seed, _variant(), style, reveal, recolor, _cache)


## Which boil variant to draw. The default follows the page's boil clock. A fraction between two
## variants blends their shapes, for a line that wavers softly.
func _variant() -> float:
	return InkPainter.current_variant()


## The lines to draw, in local space and in drawing order. The default draws the authored strokes.
func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var lines: Array[InkLine] = []
	for stroke in strokes:
		if stroke != null and stroke.points.size() > 1:
			lines.append(stroke.to_line(palette, style.sample_spacing))
	return lines


## Draws the drawing on from blank over [param duration] seconds. Await the returned tween's [code]finished[/code].
func draw_on(duration: float) -> Tween:
	reveal = 0.0
	var tween := create_tween()
	tween.tween_property(self, ^"reveal", 1.0, duration)
	return tween


## Dissolves the drawing away over [param duration] seconds. Await the returned tween's [code]finished[/code].
func dissolve_away(duration: float) -> Tween:
	var tween := create_tween()
	tween.tween_property(self, ^"dissolve", 1.0, duration)
	return tween


## A still copy of the drawing as it is right now, its line wobbling the same way, for an effect that
## leaves the drawing behind, such as the imp soaking away where he was while he inks himself on
## somewhere else. The caller adds it to the page and frees it.
func ghost() -> InkDrawing:
	var copy := duplicate(DUPLICATE_SCRIPTS) as InkDrawing
	copy.wobble_seed = _seed
	return copy


func _width_compensation() -> float:
	if not constant_line_width or not is_inside_tree():
		return 1.0
	var scale_2d := get_global_transform().get_scale().abs()
	var average := (scale_2d.x + scale_2d.y) * 0.5
	return 1.0 / average if average > 0.0001 else 1.0


func _apply_dissolve() -> void:
	if not is_inside_tree() or Engine.is_editor_hint():
		return
	if dissolve > 0.0 and _dissolve_material == null:
		_dissolve_material = InkBrush.shared_material().duplicate() as ShaderMaterial
		RenderingServer.canvas_item_set_material(get_canvas_item(), _dissolve_material.get_rid())
	if _dissolve_material != null:
		_dissolve_material.set_shader_parameter(&"dissolve", dissolve)
