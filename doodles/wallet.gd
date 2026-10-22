@tool
class_name Wallet
extends InkDrawing
## A doodle: a wallet that holds twenty dollars again every morning. A green bifold wallet stands on
## its fold, seen from the front and a little open, so the back half shows over the front one, and a
## banknote peeks out between them: a plain rectangle with a small oval on it. A line of stitches runs
## round the front half, a little in from its edge. Green washes fill the halves and a paler one the
## note. Its origin is the ground under its middle.

## How big the wallet is drawn, as a multiple of its natural size.
@export_range(0.2, 3.0, 0.01) var wallet_scale := 1.0:
	set(value):
		wallet_scale = value
		queue_redraw()
## How far the note leans, in degrees, clockwise.
@export_range(-30.0, 30.0, 0.5) var note_tilt := -5.0:
	set(value):
		note_tilt = value
		queue_redraw()
## Palette role of the line.
@export var line_role := &"green":
	set(value):
		line_role = value
		queue_redraw()
## How strongly the halves' washes take the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var wash_strength := 0.45:
	set(value):
		wash_strength = value
		queue_redraw()
## How strongly the note's wash takes the line's colour over the paper.
@export_range(0.0, 1.0, 0.01) var note_wash := 0.15:
	set(value):
		note_wash = value
		queue_redraw()
## How far in from the front half's edge its stitches run, at natural size.
@export_range(0.0, 40.0, 0.5) var stitch_inset := 10.0:
	set(value):
		stitch_inset = value
		queue_redraw()
## Length of each stitch, at natural size.
@export_range(1.0, 40.0, 0.5) var stitch_length := 9.0:
	set(value):
		stitch_length = value
		queue_redraw()
## Gap between stitches, at natural size.
@export_range(1.0, 40.0, 0.5) var stitch_gap := 7.0:
	set(value):
		stitch_gap = value
		queue_redraw()

## The back half at natural size, standing on the ground; its top shows over the front half.
const _BACK := Rect2(-92.0, -144.0, 184.0, 144.0)
## The front half, tipped a little toward us, so its top sits lower than the back half's.
const _FRONT := Rect2(-92.0, -120.0, 184.0, 120.0)
## Radius of the halves' rounded corners.
const _CORNER := 16.0
## The note's middle and size before it leans; the front half hides its bottom.
const _NOTE_MIDDLE := Vector2(-4.0, -140.0)
const _NOTE_SIZE := Vector2(124.0, 92.0)
## The oval on the note, from the note's middle, and its radii.
const _NOTE_OVAL := Vector2(0.0, -24.0)
const _NOTE_OVAL_RADII := Vector2(15.0, 11.0)
## Sample spacing for the stitches and the note's oval, finer than a whole line's.
const _FINE_SPACING := 2.0


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(line_role)
	var wash := palette.paper.lerp(color, wash_strength)
	var lines: Array[InkLine] = []
	lines.append(_washed(InkBrush.rounded_rect(_scaled_rect(_BACK), _CORNER * wallet_scale, spacing), color, wash))
	var note_corners := PackedVector2Array()
	for corner: Vector2 in [Vector2(-0.5, -0.5), Vector2(0.5, -0.5), Vector2(0.5, 0.5), Vector2(-0.5, 0.5), Vector2(-0.5, -0.5)]:
		note_corners.append(_on_note(corner * _NOTE_SIZE))
	lines.append(_washed(InkBrush.resample_polyline(note_corners, spacing), color, palette.paper.lerp(color, note_wash)))
	var oval := InkBrush.ellipse(Vector2.ZERO, _NOTE_OVAL_RADII, _FINE_SPACING)
	for i in oval.size():
		oval[i] = _on_note(_NOTE_OVAL + oval[i])
	lines.append(InkLine.along(oval, color, 0.7, true))
	var front := _scaled_rect(_FRONT)
	lines.append(_washed(InkBrush.rounded_rect(front, _CORNER * wallet_scale, spacing), color, wash))
	var inset := stitch_inset * wallet_scale
	var seam := InkBrush.rounded_rect(front.grow(-inset), maxf(_CORNER - stitch_inset, 0.0) * wallet_scale, _FINE_SPACING)
	for stitch in _dashes(seam, stitch_length * wallet_scale, stitch_gap * wallet_scale):
		lines.append(InkLine.along(stitch, color, 0.55))
	return lines


## A closed line along [param path] with [param wash] inside it.
static func _washed(path: PackedVector2Array, color: Color, wash: Color) -> InkLine:
	var line := InkLine.along(path, color, 1.0, true)
	line.fill = wash
	return line


## The closed [param path] cut into dashes [param length] long with [param gap] between them.
static func _dashes(path: PackedVector2Array, length: float, gap: float) -> Array[PackedVector2Array]:
	var dashes: Array[PackedVector2Array] = []
	var loop := path.duplicate()
	loop.append(path[0])
	var dash := PackedVector2Array([loop[0]])
	var travelled := 0.0
	for i in range(1, loop.size()):
		travelled += loop[i].distance_to(loop[i - 1])
		if travelled <= length:
			dash.append(loop[i])
		elif travelled >= length + gap:
			if dash.size() > 1:
				dashes.append(dash)
			dash = PackedVector2Array([loop[i]])
			travelled = 0.0
	if dash.size() > 1:
		dashes.append(dash)
	return dashes


## A point on the note, from its middle before it leans, leant and scaled.
func _on_note(point: Vector2) -> Vector2:
	return (_NOTE_MIDDLE + point.rotated(deg_to_rad(note_tilt))) * wallet_scale


func _scaled_rect(rect: Rect2) -> Rect2:
	return Rect2(rect.position * wallet_scale, rect.size * wallet_scale)
