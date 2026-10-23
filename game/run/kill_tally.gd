class_name KillTally
extends RefCounted
## Everything the player has killed across the run, counted by kind: the souls on the tracks, the
## strangers who folded for money, a nuked country's people, everyone shot. The last matchup of
## Who Would Win sends all of it at the player at once.

## How many have been killed, of every kind.
var count := 0
## How many of each kind, such as [code]bear[/code] or [code]people[/code].
var kinds: Dictionary[StringName, int] = {}


## Counts [param number] more of [param kind].
func add(kind: StringName, number := 1) -> void:
	if number <= 0:
		return
	count += number
	kinds[kind] = kinds.get(kind, 0) + number


## Whether any of [param kind] were killed.
func has(kind: StringName) -> bool:
	return kinds.get(kind, 0) > 0


## The tally as plain data, for the save: how many of each kind.
func to_data() -> Dictionary:
	var data := {}
	for kind in kinds:
		data[String(kind)] = kinds[kind]
	return data


## A tally from [method to_data], or null when [param data] is not one.
static func from_data(data: Variant) -> KillTally:
	if not data is Dictionary:
		return null
	var tally := KillTally.new()
	for kind: Variant in data:
		if not (data[kind] is int or data[kind] is float):
			return null
		tally.add(StringName(str(kind)), int(data[kind]))
	return tally
