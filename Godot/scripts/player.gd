extends CharacterBody2D

@onready var tileMap = $"../TileMapLayer"
@onready var sprite2D = $Chef
@onready var UI = $"../UI"
@onready var table = $"../Tables"
@onready var main = $".."
@onready var store = $"../Store"



var held_ingredient = null
var isMoving = false
var last_direction = Vector2i(0, 0)
var is_busy = false
var target_position: Vector2  

const MOVE_SPEED = 160

func _physics_process(delta):
	if is_busy or not isMoving:
		return
	
	# moves sprite smoothly toward the target position
	global_position = global_position.move_toward(target_position, MOVE_SPEED * delta)
	
	if global_position == target_position:
		isMoving = false

func _process(delta: float):
	if is_busy or isMoving:
		return
	
	var direction = Vector2.ZERO
	if Input.is_action_pressed("up"):
		direction.y -= 1
	if Input.is_action_pressed("down"):
		direction.y += 1
	if Input.is_action_pressed("left"):
		direction.x -= 1
	if Input.is_action_pressed("right"):
		direction.x += 1
	
	if direction != Vector2.ZERO:
		last_direction = Vector2i(direction.normalized())
		move(direction)

func move(direction: Vector2):
	if is_busy:
		return

	var current_tile: Vector2i = tileMap.local_to_map(global_position)
	var target_tile: Vector2i = current_tile + Vector2i(direction.x, direction.y)

	var horizontal_tile = current_tile + Vector2i(direction.x, 0)
	var vertical_tile = current_tile + Vector2i(0, direction.y)

	var horizontal_valid = is_tile_walkable(horizontal_tile)
	var vertical_valid = is_tile_walkable(vertical_tile)
	var diagonal_valid = is_tile_walkable(target_tile)

	# determining movement direction
	if diagonal_valid:
		target_tile = target_tile
	elif horizontal_valid and direction.x != 0:
		target_tile = horizontal_tile
	elif vertical_valid and direction.y != 0:
		target_tile = vertical_tile
	else:
		return  # no movement possible

	isMoving = true
	target_position = tileMap.map_to_local(target_tile)

func is_tile_walkable(tile: Vector2i) -> bool:
	var tile_data = tileMap.get_cell_tile_data(tile)
	if tile_data and not tile_data.get_custom_data("walkable"):
		return false
	if main.get_table_at_tile(tile):
		return false
	return true

func get_facing_direction() -> Vector2i:
	return last_direction

func attempt_interaction():
	if is_busy:
		return

	var facing_tile: Vector2i = tileMap.local_to_map(global_position) + get_facing_direction()
	var table = main.get_table_at_tile(facing_tile)
	if table:
		table.serve("lettuce")
		return

	var tile_data = tileMap.get_cell_tile_data(facing_tile)
	if not tile_data or not tile_data.get_custom_data("interactable"):
		return

	if tile_data.get_custom_data("lettuce"):
		pick_up_ingredient("res://scenes/Lettuce.tscn")
	elif tile_data.get_custom_data("chopping board") and held_ingredient and not held_ingredient.is_chopped:
		held_ingredient.chop()
	elif tile_data.get_custom_data("package") and held_ingredient and held_ingredient.state == held_ingredient.State.CHOPPED:
		is_busy = true
		held_ingredient.package()
	elif tile_data.get_custom_data("store"):
		store.open_store()

func pick_up_ingredient(scene_path: String):
	if held_ingredient == null:
		held_ingredient = load(scene_path).instantiate()
		held_ingredient.pick_up()
		$Chef.add_child(held_ingredient)

func _input(event):
	if event.is_action_pressed("interact"):
		attempt_interaction()
