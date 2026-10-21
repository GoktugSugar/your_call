extends Node2D
## Development only: a row of figures in every fold pose, and one that folds over and over.

@export var poses: Array[FigurePose] = []
@export var figure_scene: PackedScene
@export var spacing := 200.0
@export var refold_delay := 0.6


func _ready() -> void:
	for i in poses.size():
		var figure := figure_scene.instantiate() as StickFigure
		figure.position = Vector2(300.0 + spacing * i, 420.0)
		add_child(figure)
		figure.pose = poses[i]
	_fold_forever()


func _fold_forever() -> void:
	while is_inside_tree():
		var figure := figure_scene.instantiate() as StickFigure
		figure.position = Vector2(860.0, 760.0)
		add_child(figure)
		await get_tree().create_timer(refold_delay).timeout
		await figure.fold(1.0)
		figure.queue_free()
