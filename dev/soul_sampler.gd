extends Node2D
## Development only: every kind of soul in rows, each named, then a soul pleading out loud, a roped
## pair, a soul turned away and a patch of the dark, so the details can be judged side by side. Between
## the rows a soul walks back and forth, beside an armed soul with its pistol lowered.
## [codeblock]
## Godot --path . res://dev/capture_runner.tscn -- --scene=res://dev/soul_sampler.tscn --fold=bear,dying
## [/codeblock]
## [code]--fold=<kind>[,<kind>...][/code] folds the souls of those kinds in the rows once
## [member fold_delay] has passed, toward the right, or the left with [code]--fold_left[/code];
## [code]--fold=all[/code] folds every one.

@export var plea_scene: PackedScene
@export var plead_pose: FigurePose
## The pose of the armed soul beside the walk, its pistol lowered.
@export var lowered_pose: FigurePose
@export var spacing := 250.0
## How many kinds stand in a row before the next row starts.
@export var row_size := 7
## Canvas y of the ground under the first row of kinds.
@export var row_y := 260.0
## How far down each next row of kinds stands.
@export var row_gap := 230.0
@export var extras_y := 930.0
@export var label_font_size := 26
## Canvas y of the ground the walking soul walks along.
@export var walk_y := 690.0
## Canvas x of each end of the walk. The soul starts at the first and walks to the second.
@export var walk_ends := Vector2(560.0, 1420.0)
## Seconds the walking soul stands at each end before it turns back.
@export var walk_pause := 0.8
## Canvas x of the armed soul with its pistol lowered, on the walk's ground.
@export var lowered_x := 1700.0
## Seconds after the sampler opens before the kinds named by [code]--fold[/code] fold.
@export var fold_delay := 1.0

const KINDS_DIR := "res://figures/kinds"
## What [code]--fold[/code] takes to mean every kind.
const FOLD_ALL := "all"


func _ready() -> void:
	var args := DevArgs.parse()
	var folding := String(args.get("fold", "")).split(",", false)
	var fold_way := -1.0 if args.has("fold_left") else 1.0
	var kinds := PackedStringArray()
	for file in DirAccess.get_files_at(KINDS_DIR):
		if file.get_extension() == "tres":
			kinds.append(file.get_basename())
	kinds.sort()
	for i in kinds.size():
		var soul := SoulKind.find(StringName(kinds[i])).make()
		var row := floori(float(i) / row_size)
		soul.position = Vector2(180.0 + spacing * (i - row * row_size), row_y + row_gap * row)
		add_child(soul)
		_label(kinds[i], soul.position)
		if folding.has(kinds[i]) or folding.has(FOLD_ALL):
			_fold_later(soul, fold_way)

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

	var lowered := SoulKind.find(&"armed").make() as StickFigure
	lowered.pose = lowered_pose
	lowered.position = Vector2(lowered_x, walk_y)
	add_child(lowered)
	_label("armed, lowered", lowered.position)


func _walk_forever(walker: StickFigure) -> void:
	var ends: Array[float] = [walk_ends.y, walk_ends.x]
	var leg := 0
	while is_inside_tree():
		await walker.walk_to(ends[leg % ends.size()])
		await get_tree().create_timer(walk_pause).timeout
		leg += 1


func _fold_later(soul: Soul, way: float) -> void:
	await get_tree().create_timer(fold_delay).timeout
	soul.fold(way)


func _label(text: String, under: Vector2) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override(&"font_size", label_font_size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(spacing, 40.0)
	label.position = under + Vector2(-spacing * 0.5, 24.0)
	add_child(label)
