class_name MenuList
extends VBoxContainer
## A column of menu entries, one above the next. The keys go up and down the live entries and wrap round
## from the last to the first; greyed out entries are passed over.

## Whether a list is making an entry current itself, rather than the player: the entry keeps quiet then.
static var focusing := false


## The entries the keys can reach, in order: every child that can take the focus and is shown.
func live_entries() -> Array[Control]:
	var live: Array[Control] = []
	for child in get_children():
		if child is Control and child.visible and (child as Control).focus_mode == Control.FOCUS_ALL:
			live.append(child)
	return live


## Links the keys round the live entries, the last to the first. Link again after greying one out.
func link() -> void:
	var live := live_entries()
	for i in live.size():
		var entry := live[i]
		var above := entry.get_path_to(live[i - 1])
		var below := entry.get_path_to(live[(i + 1) % live.size()])
		entry.focus_neighbor_top = above
		entry.focus_previous = above
		entry.focus_neighbor_bottom = below
		entry.focus_next = below


## Makes [param entry] the current one, or the first live entry when it is not given or cannot be reached.
func focus(entry: Control = null) -> void:
	var live := live_entries()
	if entry == null or not entry in live:
		entry = live[0] if not live.is_empty() else null
	if entry != null:
		focusing = true
		entry.grab_focus()
		focusing = false
