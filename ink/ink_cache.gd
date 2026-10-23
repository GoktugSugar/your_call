class_name InkCache
extends RefCounted
## The triangles a drawing's lines made, line by line and boil variant by variant, so that painting it
## again can lay them down as they were instead of working them out afresh. A line comes back from here
## only while it is just as it was: the same path, width, colour, wash and share drawn on, painted with
## the same settings. A drawing standing still costs next to nothing at each boil; one moving pays only
## for the lines that moved. Each drawing keeps its own. Only whole variants are kept, as only they come
## round again.

## Line slots by boil variant: for each variant, a slot per line, [what the line was, its triangles].
var _variants := {}
## The settings the slots were painted with: once they change, every slot is out of date.
var _settings: Array = []


## Starts a painting with [param settings]; slots painted with any other settings are dropped.
func begin(settings: Array) -> void:
	if settings != _settings:
		_variants.clear()
		_settings = settings


## The triangles line [param index] made in [param variant], when it was just as [param key] says it
## is now; null otherwise.
func shapes(variant: float, index: int, key: Array) -> Variant:
	var slots: Array = _variants.get(variant, [])
	if index < slots.size() and slots[index] != null and slots[index][0] == key:
		return slots[index][1]
	return null


## Keeps [param shapes], the triangles line [param index] made in [param variant] when it was as
## [param key] says.
func keep(variant: float, index: int, key: Array, shapes: Array) -> void:
	var slots: Array = _variants.get_or_add(variant, [])
	if slots.size() <= index:
		slots.resize(index + 1)
	slots[index] = [key, shapes]
