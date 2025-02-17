extends CharacterBody2D

# Get references to the TileMap and Sprite2D nodes
@onready var tileMap = $"../TileMapLayer"
@onready var sprite2D = $Chef
@onready var moneyLabel = $Chef/Camera2D/MoneyLabel

var held_ingredient = null  # Store reference to held ingredient

# Load ingredient scene
@onready var ingredient_scene = preload("res://scenes/ingredient.tscn")
# Variable to track if the player is moving
var isMoving = false
var last_direction = Vector2i(0, 0)

var is_busy = false

# Called every physics frame
func _physics_process(delta):
	if is_busy:
		return
	# If the player is not moving, return early
	if isMoving == false:
		return
		
	# If the player has reached the target position, stop moving
	if global_position == sprite2D.global_position:
		isMoving = false
		return
	
	# Move the sprite towards the target position
	sprite2D.global_position = sprite2D.global_position.move_toward(global_position, 1.5)

# Called every frame
func _process(delta: float) -> void:
	if is_busy:
		return
	# Block inputs if the player is already moving
	if isMoving:
		return
		
	# Initialize a direction vector
	var direction = Vector2.ZERO
	
	# Check for input and add the corresponding direction
	if Input.is_action_pressed("up"):
		direction.y -= 1
		last_direction = Vector2i(0, -1)
	if Input.is_action_pressed("down"):
		direction.y += 1
		last_direction = Vector2i(0, 1)
	if Input.is_action_pressed("left"):
		direction.x -= 1
		last_direction = Vector2i(-1, 0)
	if Input.is_action_pressed("right"):
		direction.x += 1
		last_direction = Vector2i(1, 0)
	
	# Debug print to check the direction vector
	# Only print the direction if it's not (0,0)
#	if direction != Vector2.ZERO:
#		prints("Direction vector: ", direction)

	# Normalize the direction vector to ensure smooth diagonal movement
	if direction != Vector2.ZERO:
		move(direction.normalized())

# Function to move the player in a given direction           
func move(direction: Vector2):
	if is_busy:
		return
	# Get the current tile position as a Vector2i
	var currentTile: Vector2i = tileMap.local_to_map(global_position)
	# Get the target tile position as a Vector2i
	var targetTile: Vector2i = Vector2i(
		currentTile.x + int(round(direction.x)),  # Use round() to ensure movement in both directions
		currentTile.y + int(round(direction.y))
	)
	
	# Get custom data from the target tile to check if it's walkable
	var tileData: TileData = tileMap.get_cell_tile_data(targetTile)
	if tileData.get_custom_data("walkable") == false:
		return
	
	# Execute player movement
	isMoving = true
	global_position = tileMap.map_to_local(targetTile)
	sprite2D.global_position = tileMap.map_to_local(currentTile)
	
	# Print the current and target tiles
#	prints("currently at", currentTile, " -----  next is", targetTile)



# Function to determine which direction the player is facing
func get_facing_direction() -> Vector2i:
	return last_direction
	
func get_order_money():
	return 5

func attempt_interaction():
	# Get the player's current tile position
	var current_tile: Vector2i = tileMap.local_to_map(global_position)
	print("Current tile: ", current_tile)
	
	# Get the direction the player is facing
	var direction = get_facing_direction()
#	print("Facing direction: ", direction)
	
	# Calculate the adjacent tile in that direction
	var facing_tile: Vector2i = current_tile + direction
#	print("Target tile: ", facing_tile)
	
	# Get the tile data from the TileMap (make sure layer is correct)
	var tile_data = tileMap.get_cell_tile_data(facing_tile)  

#	print("Tile data: ", tile_data)
	
	if tile_data and tile_data.get_custom_data("interactable"):
	# Picking up from spawn tile
		if tile_data and tile_data.get_custom_data("lettuce"):
			if held_ingredient == null:
				held_ingredient = load("res://scenes/ingredient.tscn").instantiate()
				held_ingredient.pick_up()
				add_child(held_ingredient)  # Attach to player
				print("Picked up", held_ingredient.ingredient_name)
			# Chopping at chopping board
		elif tile_data and tile_data.get_custom_data("chopping board"):
			if held_ingredient and not held_ingredient.is_chopped:
				held_ingredient.chop()

			# Packaging at packaging tile
		elif tile_data and tile_data.get_custom_data("package"):

			if held_ingredient and held_ingredient.state == held_ingredient.State.CHOPPED:
				is_busy = true
				print("Packaging tile detected")
				held_ingredient.package()

		# Dropping the ingredient (optional)
		elif tile_data and tile_data.get_custom_data("serve"):
			if held_ingredient and held_ingredient.state == held_ingredient.State.PACKAGED:
				held_ingredient.drop()
				held_ingredient.queue_free()  # Remove from player
				held_ingredient = null
				moneyLabel.update_money(5)
	else:
		print("No interactable tile at: ", facing_tile)
		

func _input(event):
	if event.is_action_pressed("interact"):  # "E" key by default
		attempt_interaction()
