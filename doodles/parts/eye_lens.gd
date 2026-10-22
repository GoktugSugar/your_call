class_name EyeLens
extends RefCounted
## The open eye the eye doodles share: an upper and a lower lid, each arching from one corner of the eye
## to the other, meeting in sharp corners. Each lid is pulled furthest from the eye's middle halfway
## across and not at all at the corners; [code]pull.x[/code] is how far the upper lid is pulled up and
## [code]pull.y[/code] how far the lower lid is pulled down. The corners are [code]half_width[/code]
## either side of the middle. It lives apart from the doodles themselves, since every script in
## [code]res://doodles/[/code] is a doodle.

## Points along each lid, from corner to corner, before the outline is resampled.
const _LID_POINTS := 24


## The eye's closed outline round [param middle]: the upper lid from its left corner to its right, then the
## lower lid back. Resample it before drawing it.
static func outline(middle: Vector2, half_width: float, pull: Vector2) -> PackedVector2Array:
	var path := PackedVector2Array()
	for i in _LID_POINTS + 1:
		path.append(upper(middle, half_width, pull, lerpf(-half_width, half_width, float(i) / _LID_POINTS)))
	for i in range(1, _LID_POINTS + 1):
		path.append(lower(middle, half_width, pull, lerpf(half_width, -half_width, float(i) / _LID_POINTS)))
	return path


## The point on the upper lid [param x] across from the eye's middle.
static func upper(middle: Vector2, half_width: float, pull: Vector2, x: float) -> Vector2:
	return middle + Vector2(x, -pull.x * _share(x / half_width))


## The point on the lower lid [param x] across from the eye's middle.
static func lower(middle: Vector2, half_width: float, pull: Vector2, x: float) -> Vector2:
	return middle + Vector2(x, pull.y * _share(x / half_width))


## The way straight out of the upper lid [param x] across from the eye's middle, as a lash would grow.
static func upper_normal(half_width: float, pull: Vector2, x: float) -> Vector2:
	var slope := 2.0 * pull.x * x / (half_width * half_width)
	return Vector2(slope, -1.0).normalized()


## How much of its full pull a lid has at [param across], from -1 at the left corner to 1 at the right.
static func _share(across: float) -> float:
	return 1.0 - across * across
