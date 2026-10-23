@tool
class_name GiftBox
extends InkDrawing
## A doodle: the mystery box. A gift box seen from the front and a little from above, a ribbon down its
## front and crossed over its lid, tied in a bow on top. Opening it lifts the lid and tips it back off to
## one side, showing the dark inside of the box. Its line is ink, with a pale wash on the box and the lid
## and a dark one inside; the ribbon and the bow are red, with a red wash. Its origin is the ground under
## its middle.

## How far open the box is: 0 is shut, 1 is open, the lid lifted off and tipped back to one side. The lid
## rises first and tips over as it goes.
@export_range(0.0, 1.0, 0.001) var open := 0.0:
	set(value):
		open = value
		queue_redraw()
## How big the box is drawn, as a multiple of its natural size.
@export_range(0.2, 3.0, 0.01) var box_scale := 1.0:
	set(value):
		box_scale = value
		queue_redraw()
## How high the lid rises over its seat when the box is open, at natural size.
@export_range(0.0, 200.0, 0.5) var lid_lift := 64.0:
	set(value):
		lid_lift = value
		queue_redraw()
## How far to the side the lid goes when the box is open, at natural size. Negative sends it left.
@export_range(-200.0, 200.0, 0.5) var lid_shift := 70.0:
	set(value):
		lid_shift = value
		queue_redraw()
## How far the lid tips when the box is open, in degrees, its far end dipping toward the side it goes to.
@export_range(0.0, 90.0, 0.5) var lid_tilt := 24.0:
	set(value):
		lid_tilt = value
		queue_redraw()

@export_group("Colour")
## Palette role of the box's line and wash.
@export var role := &"ink":
	set(value):
		role = value
		queue_redraw()
## Palette role of the ribbon and the bow.
@export var ribbon_role := &"red":
	set(value):
		ribbon_role = value
		queue_redraw()
## How strongly the box's and the lid's wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.1:
	set(value):
		wash_strength = value
		queue_redraw()
## How strongly the ribbon's wash takes its colour over the paper.
@export_range(0.0, 1.0, 0.01) var ribbon_wash := 0.5:
	set(value):
		ribbon_wash = value
		queue_redraw()
## How dark the inside of the box is, as a share of the way from the paper to the box's line colour.
@export_range(0.0, 1.0, 0.01) var inside_darkness := 0.55:
	set(value):
		inside_darkness = value
		queue_redraw()

## The box at natural size: its front, with the radius of its rounded corners, and its open top seen
## from a little above, from the front's top left corner up the left side, along the back and down to
## the front's top right corner.
const _FRONT := Rect2(-66.0, -94.0, 132.0, 94.0)
const _FRONT_CORNER := 4.0
const _TOP := [Vector2(-66.0, -94.0), Vector2(-57.0, -120.0), Vector2(57.0, -120.0), Vector2(66.0, -94.0)]
## Where the lid sits on the shut box: the middle of the bottom edge of its front.
const _LID_SEAT := Vector2(0.0, -76.0)
## The lid at natural size, from the middle of the bottom edge of its front: its front, with the radius
## of its rounded corners, and its top, from the front's top left corner up the left side, along the back
## and down to the front's top right corner.
const _LID_FRONT := Rect2(-72.0, -22.0, 144.0, 22.0)
const _LID_CORNER := 3.0
const _LID_TOP := [Vector2(-72.0, -22.0), Vector2(-62.0, -52.0), Vector2(62.0, -52.0), Vector2(72.0, -22.0)]
## Half the ribbon's width, at natural size, and the radius of its corners where it runs down a front.
const _RIBBON_HALF := 11.0
const _RIBBON_CORNER := 2.0
## How far back across the lid's top the ribbon from side to side runs, its near edge and its far edge,
## as shares of the way from the top's front edge to its back.
const _RIBBON_ACROSS := Vector2(0.36, 0.64)
## The bow at natural size, from the knot in the middle of the lid's top: the knot's half size and the
## radius of its corners; the right loop, from the knot out and round and back; and the right tail,
## hanging from the knot down over the lid's front with a notch cut in its end. The left loop and tail
## mirror them.
const _KNOT_HALF := Vector2(7.0, 6.0)
const _KNOT_CORNER := 4.0
const _LOOP := [Vector2(3.0, 0.0), Vector2(14.0, -4.0), Vector2(28.0, -12.0), Vector2(38.0, -22.0),
		Vector2(38.0, -32.0), Vector2(28.0, -34.0), Vector2(16.0, -24.0), Vector2(6.0, -8.0)]
const _TAIL := [Vector2(4.0, 2.0), Vector2(12.0, 0.0), Vector2(32.0, 10.0), Vector2(27.0, 12.0),
		Vector2(26.0, 18.0), Vector2(2.0, 8.0)]


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(role)
	var pale := palette.paper.lerp(color, wash_strength)
	var red := palette.color(ribbon_role)
	var red_wash := palette.paper.lerp(red, ribbon_wash)
	var lines: Array[InkLine] = []
	# The box: its open top, dark inside, then its front and the ribbon down it. The top's line runs only
	# up its sides and along its back; the front's line draws its front edge.
	var top := InkBrush.resample_polyline(_scaled(_TOP), spacing)
	lines.append(_washed(top, color, palette.paper.lerp(color, inside_darkness), false))
	lines.append(_washed(InkBrush.rounded_rect(_scaled_rect(_FRONT), _FRONT_CORNER * box_scale, spacing), color, pale))
	lines.append(_washed(_ribbon_down(_FRONT, spacing), red, red_wash))
	# The lid, moved as one: its top, the ribbon crossed over it, its front and the ribbon down that, then
	# the bow's tails, its loops and its knot.
	var lid := _lid_place()
	lines.append(_washed(lid * InkBrush.resample_polyline(_scaled(_LID_TOP), spacing), color, pale, false))
	var across := [_on_top(0.0, _RIBBON_ACROSS.x), _on_top(1.0, _RIBBON_ACROSS.x), _on_top(1.0, _RIBBON_ACROSS.y),
			_on_top(0.0, _RIBBON_ACROSS.y)]
	lines.append(_washed(lid * InkBrush.resample_polyline(_closed(_scaled(across)), spacing), red, red_wash))
	var half := _RIBBON_HALF / _LID_FRONT.size.x
	var lengthwise := [_on_top(0.5 - half, 0.0), _on_top(0.5 + half, 0.0), _on_top(0.5 + half, 1.0),
			_on_top(0.5 - half, 1.0)]
	lines.append(_washed(lid * InkBrush.resample_polyline(_closed(_scaled(lengthwise)), spacing), red, red_wash))
	lines.append(_washed(lid * InkBrush.rounded_rect(_scaled_rect(_LID_FRONT), _LID_CORNER * box_scale, spacing), color, pale))
	lines.append(_washed(lid * _ribbon_down(_LID_FRONT, spacing), red, red_wash))
	var knot := _on_top(0.5, 0.5)
	for side: float in [1.0, -1.0]:
		var tail := InkBrush.resample_polyline(_closed(_scaled(_from_knot(_TAIL, knot, side))), spacing)
		lines.append(_washed(lid * tail, red, red_wash))
	for side: float in [1.0, -1.0]:
		var loop := InkBrush.resample_smooth(_scaled(_from_knot(_LOOP, knot, side)), true, spacing)
		lines.append(_washed(lid * loop, red, red_wash))
	var knot_rect := Rect2((knot - _KNOT_HALF) * box_scale, _KNOT_HALF * 2.0 * box_scale)
	lines.append(_washed(lid * InkBrush.rounded_rect(knot_rect, _KNOT_CORNER * box_scale, spacing), red, red_wash))
	return lines


## Where the lid is now: lifted off its seat and tipped off to the side as far as the box is open.
func _lid_place() -> Transform2D:
	var rise := sin(open * PI * 0.5)
	var swing := open * open
	var side := -1.0 if lid_shift < 0.0 else 1.0
	var offset := Vector2(lid_shift * swing, -lid_lift * rise)
	return Transform2D(deg_to_rad(lid_tilt) * side * swing, (_LID_SEAT + offset) * box_scale)


## The ribbon running down the middle of [param front], a front at natural size, from its top edge to
## its bottom.
func _ribbon_down(front: Rect2, spacing: float) -> PackedVector2Array:
	var band := Rect2(-_RIBBON_HALF, front.position.y, _RIBBON_HALF * 2.0, front.size.y)
	return InkBrush.rounded_rect(_scaled_rect(band), _RIBBON_CORNER * box_scale, spacing)


## A point on the lid's top at natural size: [param across] it from its left side (0) to its right (1),
## and [param back] from its front edge (0) to its back (1).
static func _on_top(across: float, back: float) -> Vector2:
	var front_left: Vector2 = _LID_TOP[0]
	var back_left: Vector2 = _LID_TOP[1]
	var back_right: Vector2 = _LID_TOP[2]
	var front_right: Vector2 = _LID_TOP[3]
	return front_left.lerp(front_right, across).lerp(back_left.lerp(back_right, across), back)


## [param points], given from the knot for the bow's right side, set at [param knot] with x mirrored by
## [param side].
static func _from_knot(points: Array, knot: Vector2, side: float) -> Array:
	var out := []
	for point: Vector2 in points:
		out.append(knot + Vector2(point.x * side, point.y))
	return out


func _scaled(points: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point: Vector2 in points:
		out.append(point * box_scale)
	return out


func _scaled_rect(rect: Rect2) -> Rect2:
	return Rect2(rect.position * box_scale, rect.size * box_scale)


## A line along [param path] with [param wash] inside it, closed unless [param closed] is false: the
## wash still fills the whole shape, and the line leaves its last edge to whatever is drawn over it.
static func _washed(path: PackedVector2Array, color: Color, wash: Color, closed := true) -> InkLine:
	var line := InkLine.along(path, color, 1.0, closed)
	line.fill = wash
	return line


## [param corners] with the first repeated at the end, to draw them as a closed polyline.
static func _closed(corners: PackedVector2Array) -> PackedVector2Array:
	var out := corners.duplicate()
	out.append(corners[0])
	return out
