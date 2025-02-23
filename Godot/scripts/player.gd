extends CharacterBody2D

# Get references to the TileMap and Sprite2D nodes
@onready var tileMap = $"../TileMapLayer"
@onready var sprite2D = $Chef
@onready var UI = $"../UI"
@onready var table = $"../Tables"
@onready var main = $".."
var held_ingredient = null  # Store reference to held ingredient

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
	sprite2D.global_position = sprite2D.global_position.move_toward(global_position, 3)

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

	# Get the current and target tile positions
	var currentTile: Vector2i = tileMap.local_to_map(global_position)
	var targetTile: Vector2i = currentTile + Vector2i(
		int(round(direction.x)),
		int(round(direction.y))
	)

	# Check if the tile is walkable
	var tileData: TileData = tileMap.get_cell_tile_data(targetTile)
	if tileData and tileData.get_custom_data("walkable") == false:
		return  # Prevent movement if tile isn't walkable

	# Check if a table is blocking movement
	var table_at_target = main.get_table_at_tile(targetTile)
	if table_at_target:
		return  # Block movement if a table is there

	# Execute player movement
	isMoving = true
	global_position = tileMap.map_to_local(targetTile)
	sprite2D.global_position = tileMap.map_to_local(currentTile)


# Function to determine which direction the player is facing
func get_facing_direction() -> Vector2i:
	return last_direction
	
func get_order_money():
	return 5 # will dynamically change according to customer waittime

func attempt_interaction():
	
	var direction = get_facing_direction()
	# Get the player's current tile position
	var current_tile: Vector2i = tileMap.local_to_map(global_position)
	print("")
	print("Current tile: ", current_tile)
	
	var facing_tile: Vector2i = current_tile + direction

	var table = main.get_table_at_tile(facing_tile)
	if table:
		table.serve("lettuce") # lettuce for now to test

	else:
		var tile_data = tileMap.get_cell_tile_data(facing_tile)  
		if tile_data and tile_data.get_custom_data("interactable"):
		# Picking up from spawn tile
			if tile_data and tile_data.get_custom_data("lettuce"):
				if held_ingredient == null:
					held_ingredient = load("res://scenes/Lettuce.tscn").instantiate()
					held_ingredient.pick_up()
					$Chef.add_child(held_ingredient)  # Attach to player
					
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

		else:
			print("No interactable tile at: ", facing_tile)

func _input(event):
	if event.is_action_pressed("interact"):  # "E" key by default
		attempt_interaction()
