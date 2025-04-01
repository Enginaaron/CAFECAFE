extends CharacterBody2D

@onready var tileMap = $"../TileMapLayer"
@onready var sprite2D = $Chef
@onready var UI = $"../UI"
@onready var main = $".."
@onready var heldItemTexture = $"../UI/heldItemDisplay/heldItemTexture"
@export var player_number: int = 1
@export var storeInterface: CanvasLayer = null

var held_ingredient = null
var is_busy = false
var last_direction = Vector2i(0, 0)

# Player stats
var MOVE_SPEED: int
var CHOP_SPEED: int
var PACKAGE_SPEED: int
var FRY_TIME: int
var TAPIOCA_SCOOP: int
var TEA_SPEED: int
var GRILL_SPEED: int

# Ingredient scene paths
const INGREDIENT_SCENES = {
	"lettuce": "res://scenes/food/Lettuce.tscn",
	"tomato": "res://scenes/food/Tomato.tscn",
	"chicken": "res://scenes/food/Chicken.tscn",
	"boba": "res://scenes/food/Boba.tscn",
	"patty": "res://scenes/food/Patty.tscn",
	"burger": "res://scenes/food/Burger.tscn"
}

func _ready():
	initialize_stats()
	add_to_group("players")
	setup_collision()
	setup_player_position()

func initialize_stats():
	var game_data = get_node("/root/GameData")
	if game_data:
		var stats = game_data.get_player_stats(player_number)
		MOVE_SPEED = stats["MOVE_SPEED"]
		CHOP_SPEED = stats["CHOP_SPEED"]
		PACKAGE_SPEED = stats["PACKAGE_SPEED"]
		FRY_TIME = stats["FRY_TIME"]
		TAPIOCA_SCOOP = stats["TAPIOCA_SCOOP"]
		TEA_SPEED = stats["TEA_SPEED"]
		GRILL_SPEED = stats["GRILL_SPEED"]
	else:
		MOVE_SPEED = 200
		CHOP_SPEED = 6
		PACKAGE_SPEED = 5
		FRY_TIME = 15
		TAPIOCA_SCOOP = 5
		TEA_SPEED = 5
		GRILL_SPEED = 15

func setup_collision():
	collision_mask = 3  # walls (layer 1) and customers (layer 2)

func setup_player_position():
	if player_number == 1:
		position = Vector2(16, 16)
		sprite2D.texture = preload("res://textures/PlayerSprites/bear1Front.tres")
	else:
		position = Vector2(48, 16)
		sprite2D.texture = preload("res://textures/PlayerSprites/panda1Front.tres")

func _physics_process(_delta):
	if is_busy or (storeInterface and storeInterface.visible):
		velocity = Vector2.ZERO
		return
	
	handle_movement()

func handle_movement():
	var direction = get_input_direction()
	if direction != Vector2.ZERO:
		direction = direction.normalized()
		last_direction = Vector2i(direction)
		velocity = direction * MOVE_SPEED
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()

func get_input_direction() -> Vector2:
	var direction = Vector2.ZERO
	var prefix = "" if player_number == 1 else "_p2"
	
	if Input.is_action_pressed("up" + prefix):
		direction.y -= 1
	if Input.is_action_pressed("down" + prefix):
		direction.y += 1
	if Input.is_action_pressed("left" + prefix):
		direction.x -= 1
	if Input.is_action_pressed("right" + prefix):
		direction.x += 1
	
	return direction

func get_facing_direction() -> Vector2i:
	return last_direction

func get_facing_tile() -> Vector2i:
	var current_tile = tileMap.local_to_map(global_position)
	var facing_tile = current_tile + get_facing_direction()
	
	# player can walk inside some counter tiles so just return current position instead
	var current_tile_data = tileMap.get_cell_tile_data(current_tile)
	if current_tile_data and current_tile_data.get_custom_data("type") == "counter":
		return current_tile
	return facing_tile

func attempt_interaction():
	if is_busy:
		return
	
	var facing_tile = get_facing_tile()
	
	# Check for table interaction
	var table = main.get_table_at_tile(facing_tile)
	if table:
		table.serve(held_ingredient)
		return
	
	# Check for ingredient interaction
	if handle_ingredient_interaction(facing_tile):
		return
	
	# Check for tile-based interactions
	handle_tile_interaction(facing_tile)

func handle_ingredient_interaction(facing_tile: Vector2i) -> bool:
	for node in get_tree().get_nodes_in_group("ingredients"):
		var ingredient_tile = tileMap.local_to_map(node.global_position)
		if ingredient_tile == facing_tile:
			# Handle chopping board interactions
			if node.has_method("chop") and node.on_chopping_board and node.state == node.State.WHOLE:
				if held_ingredient == null:
					node.chop()
				return true
			# Handle tapioca station interactions
			elif node.has_method("getTapioca") and node.on_tapioca_station:
				if held_ingredient == null:
					node.getTapioca()
				return true
			# Add more ingredient-specific interactions here as needed
	return false

func handle_tile_interaction(facing_tile: Vector2i):
	var tile_data = tileMap.get_cell_tile_data(facing_tile)
	if not tile_data:
		return
	
	match tile_data.get_custom_data("type"):
		"store":
			main.toggle_store()
		"trash":
			drop_ingredient()
		"counter":
			# Check for existing items at the counter
			var found_item = false
			var found_plate = false
			for node in get_tree().get_nodes_in_group("ingredients"):
				var ingredient_tile = tileMap.local_to_map(node.global_position)
				if ingredient_tile == facing_tile:
					found_item = true
					# Check if the item is a plate
					if node.scene_file_path == "res://scenes/food/Plate.tscn":
						if held_ingredient:
							node.transform(held_ingredient)
							return
					# If we're not holding anything, pick up the item
					if held_ingredient == null:
						# Remove from main scene
						main.remove_child(node)
						# Add to player's chef node
						$Chef.add_child(node)
						node.position = Vector2(0, 16)
						# Set as held ingredient
						held_ingredient = node
						# Update the held item display
						var display_name = "heldItemDisplay" if player_number == 1 else "heldItemDisplay2"
						var display = main.get_node_or_null("UI/" + display_name + "/heldItemTexture")
						if display:
							display.update_box_sprite(node.sprite.texture, node.state)
					return
			
			# If no item exists and we're holding one, place it
			if not found_item and held_ingredient:
				# Get the counter's position - use current tile if standing on counter
				var current_tile = tileMap.local_to_map(global_position)
				var current_tile_data = tileMap.get_cell_tile_data(current_tile)
				var target_tile = facing_tile
				if current_tile_data and current_tile_data.get_custom_data("type") == "counter":
					target_tile = current_tile
				
				var counter_position = tileMap.map_to_local(target_tile)
				
				# Remove from player's chef node
				$Chef.remove_child(held_ingredient)
				
				# Add to main scene at counter position
				main.add_child(held_ingredient)
				held_ingredient.global_position = counter_position
				
				# Clear the held ingredient reference
				held_ingredient = null
				
				# Clear the held item display
				var display_name = "heldItemDisplay" if player_number == 1 else "heldItemDisplay2"
				var display = main.get_node_or_null("UI/" + display_name + "/heldItemTexture")
				if display:
					display.clear_box_sprite()
		"ingredient":
			var ingredient_type = tile_data.get_custom_data("ingredient_type")
			if ingredient_type in INGREDIENT_SCENES:
				pick_up_ingredient(INGREDIENT_SCENES[ingredient_type])
		"chopping_board":
			if held_ingredient:
				# Only allow chopping for ingredients that support it
				if held_ingredient.has_method("chop") and held_ingredient.state == held_ingredient.State.WHOLE:
					held_ingredient.chop()
		"bowl":
			if held_ingredient:
				# Only allow bowl interaction for ingredients that support it
				if held_ingredient.has_method("bowl") and held_ingredient.state == held_ingredient.State.CHOPPED:
					held_ingredient.bowl()
		"plate":
			if held_ingredient:
				# Only allow bowl interaction for ingredients that support it
				if held_ingredient.has_method("plate") and held_ingredient.state == held_ingredient.State.COOKED:
					held_ingredient.plate()
			else:
				print("yoink")
				pick_up_ingredient("res://scenes/food/Plate.tscn")
				
		"grill":
			var found_patty = false
			for node in get_tree().get_nodes_in_group("ingredients"):
				var ingredient_tile = tileMap.local_to_map(node.global_position)
				if ingredient_tile == facing_tile and node.has_method("grill"):
					found_patty = true
					if not found_patty and held_ingredient and held_ingredient.has_method("grill"):
						if held_ingredient.state == held_ingredient.State.RAW:
							held_ingredient.grill()
					elif held_ingredient == null:
						node.grill()
			if not found_patty and held_ingredient and held_ingredient.has_method("grill"):
				if held_ingredient.state == held_ingredient.State.RAW:
					held_ingredient.grill()
		"fryer":
			var found_chicken = false
			for node in get_tree().get_nodes_in_group("ingredients"):
				var ingredient_tile = tileMap.local_to_map(node.global_position)
				if ingredient_tile == facing_tile and node.has_method("fry"):
					found_chicken = true
					if not found_chicken and held_ingredient and held_ingredient.has_method("fry"):
						if held_ingredient.state == held_ingredient.State.RAW:
							held_ingredient.fry()
					elif held_ingredient == null:
						node.fry()
			if not found_chicken and held_ingredient and held_ingredient.has_method("fry"):
				if held_ingredient.state == held_ingredient.State.RAW:
					held_ingredient.fry()
					
		"tea":
			if held_ingredient and held_ingredient.has_method("getTea"):
				held_ingredient.getTea()
		"tapioca":
			# Check for existing cups at the tapioca station
			var found_cup = false
			for node in get_tree().get_nodes_in_group("ingredients"):
				var ingredient_tile = tileMap.local_to_map(node.global_position)
				if ingredient_tile == facing_tile and node.has_method("getTapioca"):
					found_cup = true
					# If we're holding a cup, try to place it
					if held_ingredient and held_ingredient.has_method("getTapioca"):
						if held_ingredient.state == held_ingredient.State.CUP or held_ingredient.state == held_ingredient.State.TEA:
							held_ingredient.getTapioca()
					# If we're not holding anything, interact with the existing cup
					elif held_ingredient == null:
						node.getTapioca()
					return
			
			# If no cup exists and we're holding one, place it
			if not found_cup and held_ingredient and held_ingredient.has_method("getTapioca"):
				if held_ingredient.state == held_ingredient.State.CUP or held_ingredient.state == held_ingredient.State.TEA:
					held_ingredient.getTapioca()
		"lid":
			if held_ingredient and held_ingredient.has_method("lid"):
				held_ingredient.lid()

func pick_up_ingredient(scene_path: String):
	if held_ingredient == null:
		held_ingredient = load(scene_path).instantiate()
		held_ingredient.pick_up()
		$Chef.add_child(held_ingredient)
		held_ingredient.global_position += Vector2(0, 16)
		# Ensure the ingredient is in the ingredients group
		if not held_ingredient.is_in_group("ingredients"):
			held_ingredient.add_to_group("ingredients")

func drop_ingredient():
	if held_ingredient:
		$Chef.remove_child(held_ingredient)
		held_ingredient.drop()
		held_ingredient = null
		# Get the correct held item display based on player number
		var display_name = "heldItemDisplay" if player_number == 1 else "heldItemDisplay2"
		var main_scene = get_node("/root/Node2D")
		if main_scene:
			var display = main_scene.get_node_or_null("UI/" + display_name + "/heldItemTexture")
			if display:
				display.clear_box_sprite()

func _input(event):
	var interact_action = "interact" if player_number == 1 else "interact_p2"
	if event.is_action_pressed(interact_action):
		attempt_interaction()

func apply_bonus(stat_bonus: Dictionary) -> void:
	for stat in stat_bonus:
		match stat:
			"moveSpeed":
				MOVE_SPEED += stat_bonus[stat]
			"packageSpeed":
				PACKAGE_SPEED += stat_bonus[stat]
			"chopSpeed":
				CHOP_SPEED += stat_bonus[stat]
			"fryTime":
				FRY_TIME += stat_bonus[stat]
			"tapiocaScoop":
				TAPIOCA_SCOOP += stat_bonus[stat]
			"teaSpeed":
				TEA_SPEED += stat_bonus[stat]
			"grillSpeed":
				GRILL_SPEED += stat_bonus[stat]

func is_facing_position(target_pos: Vector2) -> bool:
	return get_facing_tile() == tileMap.local_to_map(target_pos)
