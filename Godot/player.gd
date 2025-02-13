extends Sprite2D

# Get references to the TileMap and Sprite2D nodes
@onready var tileMap = $"../TileMapLayer"
@onready var sprite2D = $Sprite2D

# Variable to track if the player is moving
var isMoving = false

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
		
	# Check for input and move the player in the corresponding direction
	if Input.is_action_pressed("up"):
		move(Vector2.UP)
	if Input.is_action_pressed("down"):
		move(Vector2.DOWN)
	if Input.is_action_pressed("left"):
		move(Vector2.LEFT)
	if Input.is_action_pressed("right"):
		move(Vector2.RIGHT)

# Function to move the player in a given direction           
func move(direction: Vector2):
	# Get the current tile position as a Vector2i
	var currentTile: Vector2i = tileMap.local_to_map(global_position)
	# Get the target tile position as a Vector2i
	var targetTile: Vector2i = Vector2i(
		currentTile.x + direction.x,
		currentTile.y + direction.y,
	)
	prints("currently at", currentTile, " -----  next is", targetTile)
	
	# Get custom data from the target tile to check if it's walkable
	var tileData: TileData = tileMap.get_cell_tile_data(targetTile)
	if tileData.get_custom_data("walkable") == false:
		return
	
	# Execute player movement
	isMoving = true
	global_position = tileMap.map_to_local(targetTile)
	sprite2D.global_position = tileMap.map_to_local(currentTile)
