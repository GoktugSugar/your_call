extends Node2D
## Development only: every kind of soul in a row, each named, then a soul pleading out loud, a roped
## pair, a soul turned away and a patch of the dark, so the details can be judged side by side. Between
## the rows a soul walks back and forth.

@export var plea_scene: PackedScene
@export var plead_pose: FigurePose
@export var spacing := 200.0
@export var row_y := 420.0
@export var extras_y := 820.0
@export var label_font_size := 26
## Canvas y of the ground the walking soul walks along.
@export var walk_y := 610.0
## Canvas x of each end of the walk. The soul starts at the first and walks to the second.
@export var walk_ends := Vector2(560.0, 1420.0)
## Seconds the walking soul stands at each end before it turns back.
@export var walk_pause := 0.8

const KINDS_DIR := "res://figures/kinds"


func _ready() -> void:
	var kinds := PackedStringArray()
	for file in DirAccess.get_files_at(KINDS_DIR):
		if file.get_extension() == "tres":
			kinds.append(file.get_basename())
	kinds.sort()
	for i in kinds.size():
		var soul := SoulKind.find(StringName(kinds[i])).make()
		soul.position = Vector2(180.0 + spacing * i, row_y)
		add_child(soul)
		_label(kinds[i], soul.position)

	var pleader := SoulKind.find(&"stranger").make() as StickFigure
	pleader.pose = plead_pose
	pleader.position = Vector2(300.0, extras_y)
	add_child(pleader)
	var plea := plea_scene.instantiate() as Plea
	add_child(plea)
	plea.set_words("Please. My children are waiting up for me.")
	plea.place(pleader.to_global(pleader.head_top()))
	plea.write_on()
	_label("pleading", pleader.position)

	var tied: Array[Soul] = [SoulKind.find(&"guilty").make(), SoulKind.find(&"stranger").make()]
	for i in tied.size():
		tied[i].position = Vector2(700.0 + 68.0 * i, extras_y)
		add_child(tied[i])
	var rope := Rope.new()
	add_child(rope)
	rope.souls = tied
	_label("roped", Vector2(734.0, extras_y))

	var away := SoulKind.find(&"stranger").make() as StickFigure
	away.eyes = StickFigure.Eyes.HIDDEN
	away.position = Vector2(1000.0, extras_y)
	add_child(away)
	_label("turned away", away.position)

	var dark := Darkness.new()
	dark.position = Vector2(1200.0, extras_y)
	dark.area = Rect2(0.0, -150.0, 640.0, 220.0)
	add_child(dark)

	var walker := SoulKind.find(&"stranger").make() as StickFigure
	walker.position = Vector2(walk_ends.x, walk_y)
	add_child(walker)
	_label("walking", Vector2((walk_ends.x + walk_ends.y) * 0.5, walk_y))
	_walk_forever(walker)


func _walk_forever(walker: StickFigure) -> void:
	var ends: Array[float] = [walk_ends.y, walk_ends.x]
	var leg := 0
	while is_inside_tree():
		await walker.walk_to(ends[leg % ends.size()])
		await get_tree().create_timer(walk_pause).timeout
		leg += 1


func _label(text: String, under: Vector2) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override(&"font_size", label_font_size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(spacing, 40.0)
	label.position = under + Vector2(-spacing * 0.5, 24.0)
	add_child(label)
