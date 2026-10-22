@tool
class_name DoodleGroup
extends InkDrawing
## Drawings that stand, lift, hop and dissolve as one, in a doodle's place on a stage: a crowd of small
## copies of a doodle, or a figure standing in for one. It draws nothing itself; dissolving it dissolves
## every drawing in it. Its origin is the ground under its middle, like a doodle's.


## A crowd of [param shown] small copies of the doodle [param id] in palette [param role], each at
## [param size] of its natural size, packed into rows across [param width] and stepping back, and up,
## [param row_step] a row. The back rows are drawn first, so the front ones stand over them.
static func crowd(id: String, shown: int, role: StringName, size: float, width: float, row_step: float) -> DoodleGroup:
	var group := DoodleGroup.new()
	var per_row := maxi(1, ceili(sqrt(shown * 1.8)))
	var rows := ceili(float(shown) / per_row)
	for row in range(rows - 1, -1, -1):
		var in_row := mini(per_row, shown - row * per_row)
		for i in in_row:
			var copy := DoodlesStage.make_doodle(id)
			if copy == null:
				continue
			if role != &"" and &"role" in copy:
				copy.set(&"role", role)
			copy.scale = Vector2.ONE * size
			var across := (i - (in_row - 1) * 0.5) * width / maxf(per_row, 1.0)
			# Every other row sits half a place over, so the crowd reads as a crowd and not a grid.
			across += (width / maxf(per_row, 1.0)) * 0.5 * (row % 2) - (width / maxf(per_row, 1.0)) * 0.25
			copy.position = Vector2(across, -row * row_step)
			group.add_child(copy)
	return group


## One doodle [param id] in palette [param role] at [param size] of its natural size, as a group.
static func single(id: String, role: StringName, size: float) -> DoodleGroup:
	var group := DoodleGroup.new()
	var doodle := DoodlesStage.make_doodle(id)
	if doodle != null:
		if role != &"" and &"role" in doodle:
			doodle.set(&"role", role)
		doodle.scale = Vector2.ONE * size
		group.add_child(doodle)
	return group


func _build_lines(_style: InkStyle, _palette: InkPalette) -> Array[InkLine]:
	return []


func _apply_dissolve() -> void:
	if not is_inside_tree():
		return
	for drawing in _drawings():
		drawing.dissolve = dissolve


func _drawings() -> Array[InkDrawing]:
	var found: Array[InkDrawing] = []
	var pending: Array[Node] = get_children()
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if node is InkDrawing:
			found.append(node)
		pending.append_array(node.get_children())
	return found
