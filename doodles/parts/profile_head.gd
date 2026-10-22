class_name ProfileHead
extends RefCounted
## The one head the head doodles share, so that they read as a family: a plain head in profile, facing
## right, with a rounded skull, a brow, a bump of a nose and a chin, its neck cut off clean, and no feature
## but a dot eye. A doodle draws it with [method lines] and places what it adds by the head's landmarks.
## Points are at natural size, with the origin on the ground under the head's middle, where the neck is cut.
## It lives apart from the doodles themselves, since every script in [code]res://doodles/[/code] is a doodle.

## The outline at natural size, from the back of the cut up the back of the neck, round the back of the
## skull and over the crown, down the brow, the nose and the chin, and back under the jaw and down the front
## of the neck to the front of the cut. The straight cut closes it.
const _OUTLINE := [Vector2(-32.0, 0.0), Vector2(-34.0, -32.0), Vector2(-43.0, -62.0), Vector2(-60.0, -84.0),
		Vector2(-70.0, -114.0), Vector2(-67.0, -144.0), Vector2(-50.0, -168.0), Vector2(-22.0, -181.0),
		Vector2(10.0, -181.0), Vector2(37.0, -170.0), Vector2(53.0, -152.0), Vector2(59.0, -134.0),
		Vector2(61.0, -122.0), Vector2(57.0, -112.0), Vector2(62.0, -101.0), Vector2(70.0, -89.0),
		Vector2(63.0, -82.0), Vector2(63.0, -71.0), Vector2(61.0, -63.0), Vector2(64.0, -51.0),
		Vector2(57.0, -38.0), Vector2(40.0, -33.0), Vector2(22.0, -36.0), Vector2(18.0, -18.0), Vector2(19.0, 0.0)]
## The dot eye.
const EYE := Vector2(44.0, -108.0)
## The top of the skull, where a thing can rise from the head.
const CROWN := Vector2(-6.0, -182.0)
## The middle of the room inside the skull, where a thing the head holds sits.
const MIND := Vector2(-12.0, -134.0)
## The back of the skull, where a thing can leave the head.
const BACK := Vector2(-70.0, -116.0)


## The head's lines, drawn [param size] times its natural size and moved by [param offset]: its outline in
## [param color] with [param wash] inside, then its dot eye of [param eye_radius] in [param eye_color].
static func lines(offset: Vector2, size: float, color: Color, wash: Color, eye_radius: float, eye_color: Color,
		spacing: float) -> Array[InkLine]:
	var outline := InkLine.along(outline_path(offset, size, spacing), color, 1.0, true)
	outline.fill = wash
	var out: Array[InkLine] = [outline, InkLine.dot(place(EYE, offset, size), eye_radius, eye_color)]
	return out


## The head's closed outline, drawn [param size] times its natural size and moved by [param offset], as
## points about [param spacing] apart: smooth all round, but for the sharp corners where the neck is cut.
static func outline_path(offset: Vector2, size: float, spacing: float) -> PackedVector2Array:
	var points := placed(_OUTLINE, offset, size)
	var path := InkBrush.resample_smooth(points, false, spacing)
	var cut := InkBrush.resample_polyline(PackedVector2Array([points[points.size() - 1], points[0]]), spacing)
	path.append_array(cut.slice(1))
	return path


## Where [param point], given on the head at natural size, lands when the head is drawn [param size] times
## its natural size and moved by [param offset]. A landmark placed this way makes the offset for points
## given from that landmark.
static func place(point: Vector2, offset: Vector2, size: float) -> Vector2:
	return offset + point * size


## Every point of [param points] placed as [method place] places one.
static func placed(points: Array, offset: Vector2, size: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point: Vector2 in points:
		out.append(place(point, offset, size))
	return out
