extends Sprite2D

@onready var tileMap = $"../TileMapLayer"
@onready var sprite2D = $Sprite2D

var isMoving = false

func _physics_process(delta):
	if isMoving == false:
		return
		
	if global_position == sprite2D.global_position:
		isMoving = false
		return
	
	sprite2D.global_position = sprite2D.global_position.move_toward(global_position, 2)

func _process(delta: float) -> void:
	# block inputs if player is alr moving
	if isMoving:
		return
		
	if Input.is_action_pressed("up"):
		move(Vector2.UP)
	elif Input.is_action_pressed("down"):
		move(Vector2.DOWN)
	elif Input.is_action_pressed("left"):
		move(Vector2.LEFT)
	elif Input.is_action_pressed("right"):
		move(Vector2.RIGHT)


func move(direction: Vector2):
	# get current tile Vector2i
	var currentTile: Vector2i = tileMap.local_to_map(global_position)
	# get target tile Vector2i
	var targetTile: Vector2i = Vector2i(
		currentTile.x + direction.x,
		currentTile.y + direction.y,
	)
	prints("currently at",currentTile," -----  next is", targetTile);
	# get custom data layer from target file (see if walkable)
	var tileData: TileData = tileMap.get_cell_tile_data(targetTile)
	
	if tileData.get_custom_data("walkable") == false:
		return
	
	# execute player movement
	isMoving = true
	global_position = tileMap.map_to_local(targetTile)
	sprite2D.global_position = tileMap.map_to_local(currentTile);
