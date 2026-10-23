extends Node
## The voice, chapter by chapter, in a browser (autoload [code]VoicePacks[/code]). A browser build carries
## the voice of the menu and the first chapter, and fetches every other chapter's in the background, one
## after another, from packs beside its own files ([code]voice/<chapter>.bin[/code], listed in
## [code]voice/packs.json[/code] by the web export), so the page starts quickly; the chapter a run is
## heading into is fetched first. Anywhere else every voice is in the game already.

## Emitted when a chapter's voice has arrived.
signal arrived(chapter: StringName)

## The folder beside the game's own files the packs are in.
@export var folder := "voice"
## Seconds a fetch may take before it is given up and tried again.
@export_range(5.0, 600.0, 1.0) var fetch_timeout := 120.0
## Times a pack is tried before it is given up for good.
@export_range(1, 10) var tries := 3

## The packs the build has, in run order, by chapter. Empty until the list is in, and always empty
## outside a browser.
var packs: PackedStringArray = []

var _fetcher: HTTPRequest
var _base := ""
var _loaded := {}
var _failed := {}
var _wanted := &""
var _listed := false


func _ready() -> void:
	if not OS.has_feature("web"):
		return
	_fetcher = HTTPRequest.new()
	_fetcher.timeout = fetch_timeout
	# A host's gzip is the browser's to undo: the game undoing it again would fail.
	_fetcher.accept_gzip = false
	add_child(_fetcher)
	var page := str(JavaScriptBridge.eval("window.location.href", true))
	_base = page.substr(0, page.rfind("/") + 1) + folder + "/"
	_fetch_list()


## Whether [param chapter]'s voice is all there will be: always outside a browser; in one, once its
## pack has arrived (or been given up on), or when the build carries it.
func ready_for(chapter: StringName) -> bool:
	if not OS.has_feature("web") or _loaded.has(chapter) or _failed.has(chapter):
		return true
	return _listed and not String(chapter) in packs


## Fetches [param chapter]'s voice next, ahead of the rest.
func want(chapter: StringName) -> void:
	_wanted = chapter


## Waits until [param chapter]'s voice is here, or [param seconds] have gone by.
func wait_for(chapter: StringName, seconds: float) -> void:
	want(chapter)
	var gave_up := Time.get_ticks_msec() + seconds * 1000.0
	while not ready_for(chapter) and Time.get_ticks_msec() < gave_up and is_inside_tree():
		await get_tree().process_frame


func _fetch_list() -> void:
	_fetcher.request(_base + "packs.json")
	var result: Array = await _fetcher.request_completed
	_listed = true
	if result[0] == HTTPRequest.RESULT_SUCCESS and result[1] == 200:
		var list: Variant = JSON.parse_string((result[3] as PackedByteArray).get_string_from_utf8())
		if list is Array:
			packs = PackedStringArray(list)
	_fetch_next()


## Fetches the next pack: the one wanted, if it is still to come, or the next in run order.
func _fetch_next() -> void:
	var next := ""
	if _wanted != &"" and String(_wanted) in packs and not _loaded.has(_wanted) and not _failed.has(_wanted):
		next = String(_wanted)
	else:
		for chapter in packs:
			if not _loaded.has(StringName(chapter)) and not _failed.has(StringName(chapter)):
				next = chapter
				break
	if next.is_empty():
		return
	for attempt in tries:
		_fetcher.request(_base + next + ".bin")
		var result: Array = await _fetcher.request_completed
		if result[0] == HTTPRequest.RESULT_SUCCESS and result[1] == 200 and _load(next, result[3]):
			_loaded[StringName(next)] = true
			print("VoicePacks: the voice of %s is here" % next)
			arrived.emit(StringName(next))
			_fetch_next()
			return
		push_warning("VoicePacks: could not fetch %s (result %d, code %d), try %d" % [next, result[0], result[1], attempt + 1])
	# Given up for good: its lines are said unvoiced, inking on at the typing pace.
	_failed[StringName(next)] = true
	_fetch_next()


## Loads [param body], the pack fetched for [param chapter], from a file of its own in the browser's
## memory. The fetch keeps it in memory and writes the file itself: told to write the file, it leaves it
## empty in a browser.
func _load(chapter: String, body: PackedByteArray) -> bool:
	var file := "/tmp/voice_%s.pck" % chapter
	var out := FileAccess.open(file, FileAccess.WRITE)
	if out == null:
		return false
	out.store_buffer(body)
	out.close()
	return ProjectSettings.load_resource_pack(file, false)
