extends Sprite2D

# Get references to the TileMap and Sprite2D nodes
@onready var tileMap = $"../TileMapLayer"
@onready var sprite2D = $Sprite2D

# Variable to track if the player is moving
var isMoving = false
var last_direction = Vector2i(0, 0)
var heldItem = null

# Called every physics frame
func _physics_process(delta):
	# If the player is not moving, return early
	if isMoving == false:
		return
		
	# If the player has reached the target position, stop moving
	if global_position == sprite2D.global_position:
		isMoving = false
		return
	
	# Move the sprite towards the target position
	sprite2D.global_position = sprite2D.global_position.move_toward(global_position, 2)

# Called every frame
func _process(delta: float) -> void:
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
	
	# Normalize the direction vector to ensure smooth diagonal movement
	if direction != Vector2.ZERO:
		move(direction.normalized())

# Function to move the player in a given direction           
func move(direction: Vector2):
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

func handle_interaction(tile: Vector2i):
	var tile_name = tileMap.get_cell_source_id(tile)  # Get the tile type ID

	match tile_name:
		0:  # Example: Tile ID for a chopping board
			print("Using Chopping Board")
			chop_ingredient()
		2:  # Example: Tile ID for a stove
			print("Cooking on Stove")
			cook_ingredient()
		_:
			print("Nothing to interact with here")

func chop_ingredient():
	print("Chopping ingredient...")

func cook_ingredient():
	print("Cooking...")
# Detect interaction when the player presses "E"

# Function to determine which direction the player is facing
func get_facing_direction() -> Vector2i:
	return last_direction

func attempt_interaction():
	# Get the player's current tile position
	var current_tile: Vector2i = tileMap.local_to_map(global_position)
	print("Current tile: ", current_tile)
	
	# Get the direction the player is facing
	var direction = get_facing_direction()
	print("Facing direction: ", direction)
	
	# Calculate the adjacent tile in that direction
	var facing_tile: Vector2i = current_tile + direction
	print("Target tile: ", facing_tile)
	
	# Get the tile data from the TileMap (make sure layer is correct)
	var tile_data = tileMap.get_cell_tile_data(facing_tile)  

	print("Tile data: ", tile_data)
	
	if tile_data and tile_data.get_custom_data("interactable"):
		print("Interacting with tile at: ", facing_tile)
		var tile_id = tileMap.get_cell_source_id(facing_tile)
		print("Tile ID at ", facing_tile, " is ", tile_id)

		handle_interaction(facing_tile)
	else:
		print("No interactable tile at: ", facing_tile)

func _input(event):
	if event.is_action_pressed("interact"):  # "E" key by default
		attempt_interaction()
