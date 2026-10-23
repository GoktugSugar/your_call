extends GutTest
## A drawing keeps the ink of its lines: a line painted again just as it was comes back from its cache,
## boil variant by variant, a line that changed is worked out afresh, new settings drop all of it, and a
## blend between two variants is never kept. A track keeps the lines it built until one of its settings
## changes.


func _line(to: Vector2) -> InkLine:
	return InkLine.along(InkBrush.resample_polyline(PackedVector2Array([Vector2.ZERO, to]), 4.0), Color.BLACK)


func test_a_line_just_as_it_was_comes_back_and_a_changed_one_does_not() -> void:
	var cache := InkCache.new()
	cache.begin([2.0, 7])
	var key: Array = [PackedVector2Array([Vector2.ZERO, Vector2(10.0, 0.0)]), false, 1.0]
	cache.keep(0.0, 0, key, [[1, 2, 3]])
	assert_eq(cache.shapes(0.0, 0, key.duplicate(true)), [[1, 2, 3]], "the same line comes back")
	assert_null(cache.shapes(1.0, 0, key), "another boil variant is kept apart")
	assert_null(cache.shapes(0.0, 1, key), "another line's slot never answers for it")
	var moved: Array = [PackedVector2Array([Vector2.ZERO, Vector2(12.0, 0.0)]), false, 1.0]
	assert_null(cache.shapes(0.0, 0, moved), "a line that moved is worked out afresh")


func test_new_settings_drop_everything_kept() -> void:
	var cache := InkCache.new()
	var key: Array = [PackedVector2Array([Vector2.ZERO, Vector2(10.0, 0.0)])]
	cache.begin([2.0, 7])
	cache.keep(0.0, 0, key, [[1]])
	cache.begin([2.0, 7])
	assert_eq(cache.shapes(0.0, 0, key), [[1]], "the same settings keep it")
	cache.begin([3.0, 7])
	assert_null(cache.shapes(0.0, 0, key), "a wider line, say, drops it")


func test_painting_keeps_a_whole_variant_and_never_a_blend() -> void:
	var node := Node2D.new()
	add_child_autofree(node)
	var cache := InkCache.new()
	var lines: Array[InkLine] = [_line(Vector2(40.0, 0.0)), _line(Vector2(0.0, 40.0))]
	InkPainter.paint(node, lines, 2.0, 11, 1.0, InkStyle.get_default(), 1.0, Color.TRANSPARENT, cache)
	assert_eq(cache._variants.size(), 1, "the whole variant is kept")
	assert_eq((cache._variants[1.0] as Array).size(), 2, "every line of it")
	InkPainter.paint(node, lines, 2.0, 11, 1.5, InkStyle.get_default(), 1.0, Color.TRANSPARENT, cache)
	assert_eq(cache._variants.size(), 1, "a blend between two is never kept")


func test_a_track_keeps_its_lines_until_a_setting_changes() -> void:
	var track := Track.new()
	track.path_points = PackedVector2Array([Vector2.ZERO, Vector2(300.0, 0.0), Vector2(500.0, 120.0)])
	add_child_autofree(track)
	var style := InkStyle.get_default()
	var palette := InkPalette.get_default()
	var first := track._build_lines(style, palette)
	var first_rail := first[0].path
	assert_same(track._build_lines(style, palette), first, "built once, then kept")
	track.gauge = track.gauge + 10.0
	var wider := track._build_lines(style, palette)
	assert_ne(wider[0].path, first_rail, "a wider gauge builds its rails again")
	assert_false(first.is_empty(), "the lines handed out before are left as they were")
