extends Node2D
## Development only: the imp in each expression, and one live imp that appears, talks and hops.

@export var imp: Imp
@export var spacing := 260.0


func _ready() -> void:
	var faces := ImpDrawing.Face.values()
	for i in faces.size():
		var sample := ImpDrawing.new()
		sample.face = faces[i]
		sample.position = Vector2(420.0 + spacing * i, 360.0)
		sample.scale = Vector2.ONE * 1.6
		add_child(sample)
	await imp.appear(Imp.Wing.RIGHT)
	imp.set_talking(true)
	while is_inside_tree():
		await get_tree().create_timer(0.8).timeout
		await imp.hop()
