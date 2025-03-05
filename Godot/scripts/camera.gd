extends Camera2D

@export var target: Node2D
@export var speed: float = 10.0

func _physics_process(delta):
	if target:
		global_position = global_position.lerp(target.global_position, 1.0 - exp(-speed*delta))
