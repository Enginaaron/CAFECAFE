extends Camera2D

@export var player1: Node2D
@export var player2: Node2D
@export var min_zoom: float = 0.1
@export var max_zoom: float = 0.4
@export var zoom_sens: float = 150 # lower for more sensitivity
@export var margin: float = 50

func _physics_process(_delta):
	if not player1 or not player2:
		return
		
	# Calculate center point between players
	var center = (player1.global_position + player2.global_position) / 2
	global_position = center
	
	# Calculate required zoom to keep both players in view with margin
	var distance = player1.global_position.distance_to(player2.global_position)
	var required_zoom = clamp(zoom_sens / (distance + margin), min_zoom, max_zoom)
	
	# Smoothly update zoom
	zoom = zoom.lerp(Vector2(required_zoom, required_zoom), 0.1)
