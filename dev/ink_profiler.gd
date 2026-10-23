extends Node
## Development only: with [code]--profile[/code], keeps count of how long each frame and the ink take,
## and prints a report every few seconds: frames, the time from one frame to the next on average and at
## worst, the ink's building and painting per second of real time, and the kinds of drawing that took
## longest.
## In a browser build the reports go to the browser's console.

## Seconds of real time between reports.
@export_range(0.5, 60.0, 0.5) var report_every := 4.0
## How many kinds of drawing each report names.
@export_range(1, 20) var top_kinds := 6
## A frame further from the last than this, in milliseconds, is reported the moment it happens.
@export_range(1.0, 1000.0, 1.0) var long_frame_ms := 40.0

var _started := 0
var _frames := 0
var _last_frame := 0
var _worst_ms := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	InkStats.enabled = true
	_begin()


func _exit_tree() -> void:
	_report()
	InkStats.enabled = false


func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	if _last_frame > 0:
		var gap := (now - _last_frame) / 1000.0
		_worst_ms = maxf(_worst_ms, gap)
		if gap > long_frame_ms:
			print("profile: a frame %.1f ms after the last, at %.2f s" % [gap, now / 1000000.0])
			now = Time.get_ticks_usec()
	_last_frame = now
	_frames += 1
	if Time.get_ticks_msec() - _started >= report_every * 1000.0:
		_report()
		_begin()
		# Printing is slow, on a console above all: the frame it took is the report's, not the game's.
		_last_frame = Time.get_ticks_usec()


func _begin() -> void:
	_started = Time.get_ticks_msec()
	_frames = 0
	_worst_ms = 0.0
	InkStats.reset()


func _report() -> void:
	var seconds := maxf((Time.get_ticks_msec() - _started) / 1000.0, 0.001)
	if _frames == 0:
		return
	print("profile: %d frames in %.1f s (%.0f a second, %.2f ms apart, the longest %.2f); ink building %.1f ms a second, painting %.1f, %d paintings a second" % [
		_frames, seconds, _frames / seconds, seconds * 1000.0 / _frames, _worst_ms,
		InkStats.build_usec / 1000.0 / seconds, InkStats.paint_usec / 1000.0 / seconds, roundi(InkStats.paints / seconds)])
	var kinds := InkStats.by_kind.keys()
	var total := func(kind: String) -> int: return InkStats.by_kind[kind][0] + InkStats.by_kind[kind][1]
	kinds.sort_custom(func(a: String, b: String) -> bool: return total.call(a) > total.call(b))
	for kind: String in kinds.slice(0, top_kinds):
		var counts: Array = InkStats.by_kind[kind]
		print("profile:   %-28s %6.1f ms a second (building %.1f, painting %.1f) over %d paintings" % [kind,
				total.call(kind) / 1000.0 / seconds, counts[0] / 1000.0 / seconds, counts[1] / 1000.0 / seconds,
				roundi(counts[2] / seconds)])
