extends CharacterBody2D

@onready var tileMap = $"../TileMapLayer"
@onready var sprite2D = $Chef
@onready var UI = $"../UI"
@onready var table = $"../Tables"
@onready var main = $".."
@onready var store = $"../Store"
@export var storeInterface: CanvasLayer = null  # Make it optional with default null value
@export var player_number: int = 1  # Default to player 1

var held_ingredient = null
var is_busy = false
var last_direction = Vector2i(0, 0)

# player stats
var MOVE_SPEED: int
var CHOP_SPEED: int
var PACKAGE_SPEED: int

func _ready():
	# Initialize stats from GameData
	var game_data = get_node("/root/GameData")
	if game_data:
		var stats = game_data.get_player_stats(player_number)
		MOVE_SPEED = stats["MOVE_SPEED"]
		CHOP_SPEED = stats["CHOP_SPEED"]
		PACKAGE_SPEED = stats["PACKAGE_SPEED"]
	else:
		# Fallback default values if GameData is not available
		MOVE_SPEED = 200
		CHOP_SPEED = 6
		PACKAGE_SPEED = 5
	
	# Add to players group for easy reference
	add_to_group("players")
	
	# walls (layer 1) and customers (layer 2)
	collision_mask = 3
	if player_number == 1:
		self.position = Vector2(16,16)
	else:
		self.position = Vector2(48,16)
		sprite2D.modulate = Color(0.2, 0.8, 1.0)  # Blue tint for player 2
	
func _physics_process(_delta):
	if is_busy or (storeInterface and storeInterface.visible):
		velocity = Vector2.ZERO
		return
	
	# input direction
	var direction = Vector2.ZERO
	var up_action = "up" if player_number == 1 else "up_p2"
	var down_action = "down" if player_number == 1 else "down_p2"
	var left_action = "left" if player_number == 1 else "left_p2"
	var right_action = "right" if player_number == 1 else "right_p2"
	
	if Input.is_action_pressed(up_action):
		direction.y -= 1
	if Input.is_action_pressed(down_action):
		direction.y += 1
	if Input.is_action_pressed(left_action):
		direction.x -= 1
	if Input.is_action_pressed(right_action):
		direction.x += 1
	
	# normalizing direction for consistent speed
	if direction != Vector2.ZERO:
		direction = direction.normalized()
		last_direction = Vector2i(direction)
		velocity = direction * MOVE_SPEED
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()

func get_facing_direction() -> Vector2i:
	return last_direction

func attempt_interaction():
	if is_busy:
		return

	# get tile player is facing
	var facing_tile: Vector2i = tileMap.local_to_map(global_position) + get_facing_direction()
	
	# check for table interaction
	var table = main.get_table_at_tile(facing_tile)
	if table:
		table.serve("lettuce")
		return

	# check for ingredients on the facing tile
	for node in get_tree().get_nodes_in_group("ingredients"):
		var ingredient_tile = tileMap.local_to_map(node.global_position)
		if ingredient_tile == facing_tile and node.on_chopping_board and node.state == node.State.WHOLE:
			# Only allow chopping if hands are empty
			if held_ingredient == null:
				# interact with ingredient on chopping board
				node.chop()
			else:
				print("Cannot chop with item in hands!")
			return

	# check for other interactions
	var tile_data = tileMap.get_cell_tile_data(facing_tile)
	if not tile_data:
		return

	if tile_data.get_custom_data("trash"):
		drop_ingredient()
	elif tile_data.get_custom_data("lettuce"):
		pick_up_ingredient("res://scenes/Lettuce.tscn")
	elif tile_data.get_custom_data("chopping board") and held_ingredient and not held_ingredient.is_chopped:
		held_ingredient.chop()
	elif tile_data.get_custom_data("bowl") and held_ingredient and held_ingredient.state == held_ingredient.State.CHOPPED:
		held_ingredient.bowl()
	elif tile_data.get_custom_data("store"):
		main.toggle_store()

func pick_up_ingredient(scene_path: String):
	if held_ingredient == null:
		held_ingredient = load(scene_path).instantiate()
		held_ingredient.pick_up()
		$Chef.add_child(held_ingredient)
func drop_ingredient():
	if held_ingredient:
		$Chef.remove_child(held_ingredient)
		held_ingredient.drop()
		held_ingredient = null
		print("Dropped item")

# interact is [E] for P1, Right Shift for P2
func _input(event):
	var interact_action = "interact" if player_number == 1 else "interact_p2"
	if event.is_action_pressed(interact_action):
		attempt_interaction()

func apply_bonus(stat_bonus) -> void:
	for stat in stat_bonus.keys():
		if stat == "moveSpeed":
			MOVE_SPEED += stat_bonus["moveSpeed"]
			print("item purchased! movement increased to "+str(MOVE_SPEED))
		elif stat == "packageSpeed":
			PACKAGE_SPEED += stat_bonus["packageSpeed"]
			print("item purchased! packaging speed increased to "+str(PACKAGE_SPEED))
		elif stat == "chopSpeed":
			CHOP_SPEED += stat_bonus["chopSpeed"]
			print("item purchased! chopping speed increased to "+str(CHOP_SPEED))

func is_facing_position(target_pos: Vector2) -> bool:
	# Get the tile the player is on and the tile they're facing
	var player_tile = tileMap.local_to_map(global_position)
	var facing_tile = player_tile + get_facing_direction()
	
	# Get the tile of the target position
	var target_tile = tileMap.local_to_map(target_pos)
	
	# Return true if the player is facing the target tile
	return facing_tile == target_tile
