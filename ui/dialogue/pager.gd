class_name Pager
extends RefCounted
## Splits a line of narration into dialogue box pages of whole sentences. It never splits a sentence,
## uses as few pages as the box allows, and spreads the sentences across them as evenly as it can.
## A colour tag left open at a page break is closed there and reopened on the next page.

const _ENDINGS := ".?!"


## The sentences of [param text], tags kept. A sentence ends at . ? or ! (after any tag that closes
## right there) when a space or the end of the text follows.
static func sentences(text: String) -> PackedStringArray:
	var out := PackedStringArray()
	var start := 0
	var i := 0
	while i < text.length():
		if _ENDINGS.contains(text[i]):
			var end := i + 1
			while text.substr(end, 2) == "[/" and text.find("]", end) > 0:
				end = text.find("]", end) + 1
			if end >= text.length() or text[end] == " ":
				out.append(text.substr(start, end - start).strip_edges())
				start = end
				i = end
				continue
		i += 1
	var rest := text.substr(start).strip_edges()
	if not rest.is_empty():
		out.append(rest)
	return out


## The pages for [param text]. [param fits] takes a run of sentences joined by spaces and says
## whether it fits one dialogue box. A sentence too long to fit gets a page to itself.
static func paginate(text: String, fits: Callable) -> PackedStringArray:
	var parts := sentences(text)
	if parts.size() <= 1:
		return PackedStringArray([text.strip_edges()])
	var state := {"parts": parts, "fits": fits, "fit_cache": {}, "memo": {}}
	var count := 0
	var at := 0
	while at < parts.size():
		var end := at + 1
		while end < parts.size() and _fits(state, at, end + 1):
			end += 1
		at = end
		count += 1
	var cuts: Array = _best_cuts(state, 0, count)[1]
	var pages := PackedStringArray()
	var from := 0
	for cut: int in cuts + [parts.size()]:
		pages.append(_join(parts, from, cut))
		from = cut
	return _rebalance(pages)


## The best way to split sentences [param from] onward into [param pages] pages: the split whose
## longest page is shortest. Returns [code][longest, cuts][/code].
static func _best_cuts(state: Dictionary, from: int, pages: int) -> Array:
	var key := Vector2i(from, pages)
	if state.memo.has(key):
		return state.memo[key]
	var parts: PackedStringArray = state.parts
	var best: Array = [INF, []]
	if pages == 1:
		if _fits(state, from, parts.size()):
			best = [float(_length(parts, from, parts.size())), []]
	else:
		for cut in range(from + 1, parts.size() - pages + 2):
			if not _fits(state, from, cut):
				break
			var rest := _best_cuts(state, cut, pages - 1)
			var longest := maxf(_length(parts, from, cut), rest[0])
			if longest < best[0]:
				best = [longest, [cut] + rest[1]]
	state.memo[key] = best
	return best


static func _fits(state: Dictionary, from: int, to: int) -> bool:
	if to - from <= 1:
		return true
	var key := Vector2i(from, to)
	if not state.fit_cache.has(key):
		state.fit_cache[key] = (state.fits as Callable).call(_join(state.parts, from, to))
	return state.fit_cache[key]


static func _join(parts: PackedStringArray, from: int, to: int) -> String:
	return " ".join(parts.slice(from, to))


static func _length(parts: PackedStringArray, from: int, to: int) -> int:
	return Markup.strip(_join(parts, from, to)).length()


static func _rebalance(pages: PackedStringArray) -> PackedStringArray:
	var out := PackedStringArray()
	var carried := ""
	var regex := RegEx.create_from_string("\\[(/?)([a-zA-Z_]+)\\]")
	for page in pages:
		var text := ("[%s]" % carried if not carried.is_empty() else "") + page
		var open := ""
		for found in regex.search_all(text):
			open = "" if found.get_string(1) == "/" else found.get_string(2)
		if not open.is_empty():
			text += "[/%s]" % open
		carried = open
		out.append(text)
	return out
