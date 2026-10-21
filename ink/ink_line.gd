class_name InkLine
extends RefCounted
## One line ready for the brush: a densely sampled path and how to draw it.
## Drawings build a list of these every time they redraw.

## The line's path, sampled densely, in the drawing's local space.
var path := PackedVector2Array()
## Joins the end back to the start.
var closed := false
## Width as a multiple of the drawing's line width.
var width := 1.0
## Colour of the line.
var color := Color.BLACK
## Colour of a wash inside a closed line. Transparent means no wash.
var fill := Color.TRANSPARENT
## When above zero, the line is a round dot of this radius at the first point of its path.
var dot_radius := 0.0


## A line along [param points] (already sampled densely).
static func along(points: PackedVector2Array, color: Color, width := 1.0, closed := false) -> InkLine:
	var line := InkLine.new()
	line.path = points
	line.color = color
	line.width = width
	line.closed = closed
	return line


## A round dot, like an eye.
static func dot(center: Vector2, radius: float, color: Color) -> InkLine:
	var line := InkLine.new()
	line.path = PackedVector2Array([center])
	line.dot_radius = radius
	line.color = color
	return line


## How much ink the line takes to draw on, in pixels along it. A dot takes none.
func length() -> float:
	if dot_radius > 0.0:
		return 0.0
	var total := InkBrush.path_length(path)
	if closed and path.size() > 1:
		total += path[path.size() - 1].distance_to(path[0])
	return total
