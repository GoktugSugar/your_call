@tool
class_name InkStroke
extends Resource
## One authored line of a drawing: a path through a few points, drawn with the shared wobble and boil.

## The points the line passes through, in its drawing's local space.
@export var points := PackedVector2Array():
	set(value):
		points = value
		_changed()
## Joins the end back to the start.
@export var closed := false:
	set(value):
		closed = value
		_changed()
## Draws a smooth curve through the points rather than straight segments.
@export var smooth := true:
	set(value):
		smooth = value
		_changed()
## Width as a multiple of the drawing's line width.
@export_range(0.0, 8.0, 0.05) var width_scale := 1.0:
	set(value):
		width_scale = value
		emit_changed()
## Palette role of the line, such as ink, amber or red.
@export var color_role: StringName = &"ink":
	set(value):
		color_role = value
		emit_changed()
## Palette role of a wash inside a closed line. Leave empty for no wash.
@export var fill_role: StringName = &"":
	set(value):
		fill_role = value
		emit_changed()
## Opacity of the wash, like coloured pencil inside a pen line.
@export_range(0.0, 1.0, 0.01) var fill_alpha := 0.45:
	set(value):
		fill_alpha = value
		emit_changed()

var _sampled := PackedVector2Array()
var _sampled_spacing := -1.0


## The line ready for the brush, coloured from [param palette].
func to_line(palette: InkPalette, spacing: float) -> InkLine:
	var line := InkLine.along(sampled(spacing), palette.color(color_role), width_scale, closed)
	if closed and fill_role != &"":
		var wash := palette.color(fill_role)
		wash.a = fill_alpha
		line.fill = wash
	return line


## The path sampled about [param spacing] apart. Cached until the points change.
func sampled(spacing: float) -> PackedVector2Array:
	if not is_equal_approx(spacing, _sampled_spacing):
		_sampled_spacing = spacing
		if smooth:
			_sampled = InkBrush.resample_smooth(points, closed, spacing)
		else:
			var corners := points.duplicate()
			if closed and corners.size() > 1:
				corners.append(corners[0])
			_sampled = InkBrush.resample_polyline(corners, spacing)
	return _sampled


func _changed() -> void:
	_sampled_spacing = -1.0
	emit_changed()
