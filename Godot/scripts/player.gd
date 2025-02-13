extends Sprite2D

@onready var tileMap = $"../TileMapLayer"
@onready var sprite2D = $Sprite2D

var isMoving = false
var playerDirection = "right"
var held_item = null  # New variable to track the item the player is holding

func _physics_process(delta):
	if !isMoving:
		return
	
	if global_position == sprite2D.global_position:
		isMoving = false
		return
	
	sprite2D.global_position = sprite2D.global_position.move_toward(global_position, 2)

func _process(delta: float) -> void:
	if isMoving:
		return
	
	var direction = Vector2.ZERO
	
	if Input.is_action_pressed("up"):
		direction.y -= 1
		playerDirection = "up"
	if Input.is_action_pressed("down"):
		direction.y += 1
		playerDirection = "down"
	if Input.is_action_pressed("left"):
		direction.x -= 1
		playerDirection = "left"
	if Input.is_action_pressed("right"):
		direction.x += 1
		playerDirection = "right"
	
	if direction != Vector2.ZERO:
		move(direction.normalized())

	# Check for interaction input
	if Input.is_action_just_pressed("interact"):
		interact()

func move(direction: Vector2):
	var currentTile: Vector2i = tileMap.local_to_map(global_position)
	var targetTile: Vector2i = Vector2i(
		currentTile.x + int(round(direction.x)),
		currentTile.y + int(round(direction.y))
	)
	
	var tileData: TileData = tileMap.get_cell_tile_data(targetTile)
	if tileData and tileData.get_custom_data("walkable") == false:
		return
	
	isMoving = true
	global_position = tileMap.map_to_local(targetTile)
	sprite2D.global_position = tileMap.map_to_local(currentTile)
	
	prints("currently at", currentTile, " -----  next is", targetTile)

func interact():
	# Get the tile in front of the player
	var facing_offset = Vector2.ZERO
	match playerDirection:
		"up": facing_offset = Vector2(0, -1)
		"down": facing_offset = Vector2(0, 1)
		"left": facing_offset = Vector2(-1, 0)
		"right": facing_offset = Vector2(1, 0)
	
	var currentTile: Vector2i = tileMap.local_to_map(global_position)
	var interactTile: Vector2i = currentTile + facing_offset

	# Check if there's an appliance in the target tile
	for child in tileMap.get_children():
		if child is Node2D and tileMap.local_to_map(child.global_position) == interactTile:
			if child.has_method("interact"):
				var result = child.interact(held_item)
				if result != null:
					held_item = result  # Update the held item if the appliance returns something
					prints("Picked up:", held_item)
				break
