class_name InkStats
extends RefCounted
## How long the ink takes, for profiling: time spent building drawings' lines and painting them, by the
## kind of drawing or control painted. Off unless a development tool turns it on, so the game itself
## never pays for it beyond one check per drawing drawn.

## Whether the ink keeps count.
static var enabled := false
## Microseconds spent building lines and painting them, and the paintings done, since the last reset.
static var build_usec := 0
static var paint_usec := 0
static var paints := 0
## Microseconds building, microseconds painting and paintings by the kind of thing painted, its script's
## file, since the last reset: kind to [build usec, paint usec, paintings].
static var by_kind := {}


## Counts [param usec] microseconds spent building the lines of [param drawing].
static func record_build(drawing: Object, usec: int) -> void:
	build_usec += usec
	_tally(drawing, usec, 0, 0)


## Counts one painting of [param node], [param usec] microseconds long.
static func record_paint(node: Object, usec: int) -> void:
	paint_usec += usec
	paints += 1
	_tally(node, 0, usec, 1)


## Starts the counts again.
static func reset() -> void:
	build_usec = 0
	paint_usec = 0
	paints = 0
	by_kind.clear()


static func _tally(node: Object, build: int, paint: int, painted: int) -> void:
	var script := node.get_script() as Script
	var kind := script.resource_path.get_file() if script != null else node.get_class()
	var counts: Array = by_kind.get(kind, [0, 0, 0])
	counts[0] += build
	counts[1] += paint
	counts[2] += painted
	by_kind[kind] = counts
