class_name InkPainter
extends RefCounted
## Paints a list of [InkLine]s into a canvas item, drawn on in order. Each line's wash goes down just
## before the line itself, so later lines and their washes sit on top of earlier ones: list what is
## behind first. No line gets thinner on screen than the style allows, however small the window or the node.
## Also hooks any canvas item up to the ink material and the boil clock, for nodes that cannot extend [InkDrawing], such as Controls.

## Seed step between the lines of one drawing, so neighbouring lines wobble differently.
const _LINE_SEED_STEP := 31
## A dot's smallest radius, as a share of the thinnest line.
const _DOT_TO_WIDTH := 0.6


## Paints [param lines] into [param node]. [param reveal] puts only the first part of the drawing on
## the page, line by line. A colour in [param recolor] (alpha above zero) replaces every line's own colour.
## [param variant] picks the boil shape; a fraction between two blends them.
static func paint(node: CanvasItem, lines: Array[InkLine], line_width: float, seed: int, variant: float,
		style: InkStyle, reveal := 1.0, recolor := Color.TRANSPARENT) -> void:
	if reveal <= 0.0 or lines.is_empty():
		return
	var item := node.get_canvas_item()
	var thinnest := style.min_screen_width / screen_scale(node)
	var shares := _reveal_shares(lines, reveal)
	for i in lines.size():
		if shares[i] <= 0.0:
			break
		var line := lines[i]
		if line.fill.a > 0.0 and shares[i] >= 1.0:
			InkBrush.fill(item, line.path, line.fill)
		var color := recolor if recolor.a > 0.0 else line.color
		var line_seed := seed + i * _LINE_SEED_STEP
		if line.dot_radius > 0.0:
			InkBrush.dot(item, line.path[0], maxf(line.dot_radius, thinnest * _DOT_TO_WIDTH), color, line_seed, variant, style)
		else:
			InkBrush.stroke(item, line.path, line.closed, maxf(line_width * line.width, thinnest), color, line_seed,
					variant, style, shares[i])


## Gives [param node] the ink material and redraws it on every boil tick. Call it from the node's [code]_ready[/code].
static func attach(node: CanvasItem) -> void:
	RenderingServer.canvas_item_set_material(node.get_canvas_item(), InkBrush.shared_material().get_rid())
	if not Engine.is_editor_hint():
		# Bound to the node itself, so the connection goes away when the node does.
		Ink.boiled.connect(node.queue_redraw.unbind(1))


## The boil variant to draw with right now. The editor always shows the first.
static func current_variant() -> int:
	return 0 if Engine.is_editor_hint() else Ink.variant


## How many screen pixels one of [param node]'s local pixels covers, taking in its own scale and the window's.
static func screen_scale(node: CanvasItem) -> float:
	if not node.is_inside_tree():
		return 1.0
	var scale := node.get_global_transform_with_canvas().get_scale().abs() \
			* node.get_viewport().get_final_transform().get_scale().abs()
	return maxf((scale.x + scale.y) * 0.5, 0.0001)


## A seed for a node's wobble, stable for its place in its scene.
static func seed_for(node: Node) -> int:
	var place := String(node.name)
	if node.owner != null:
		place = String(node.owner.get_path_to(node))
	return place.hash()


static func _reveal_shares(lines: Array[InkLine], reveal: float) -> PackedFloat32Array:
	var shares := PackedFloat32Array()
	shares.resize(lines.size())
	if reveal >= 1.0:
		shares.fill(1.0)
		return shares
	var lengths := PackedFloat32Array()
	lengths.resize(lines.size())
	var total := 0.0
	for i in lines.size():
		lengths[i] = lines[i].length()
		total += lengths[i]
	var budget := total * reveal
	for i in lines.size():
		if lengths[i] <= 0.0:
			shares[i] = 1.0 if budget > 0.0 else 0.0
		else:
			shares[i] = clampf(budget / lengths[i], 0.0, 1.0)
		budget -= lengths[i]
	return shares
