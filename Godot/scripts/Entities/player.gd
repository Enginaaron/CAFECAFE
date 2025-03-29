extends CharacterBody2D

@onready var tileMap = $"../TileMapLayer"
@onready var sprite2D = $Chef
@onready var UI = $"../UI"
@onready var main = $".."
@onready var store = $"../Store"
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

# Ingredient scene paths
const INGREDIENT_SCENES = {
	"lettuce": "res://scenes/food/Lettuce.tscn",
	"tomato": "res://scenes/food/Tomato.tscn",
	"chicken": "res://scenes/food/Chicken.tscn",
	"boba": "res://scenes/food/Boba.tscn"
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
	else:
		MOVE_SPEED = 200
		CHOP_SPEED = 6
		PACKAGE_SPEED = 5

func setup_collision():
	collision_mask = 3  # walls (layer 1) and customers (layer 2)

func setup_player_position():
	if player_number == 1:
		position = Vector2(16, 16)
	else:
		position = Vector2(48, 16)
		sprite2D.modulate = Color(0.2, 0.8, 1.0)  # Blue tint for player 2

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
	return tileMap.local_to_map(global_position) + get_facing_direction()

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
			elif node.on_tapioca_station and node.has_method("getTapioca"):
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
		"store":
			main.toggle_store()
		"grill":
			if held_ingredient and held_ingredient.has_method("grill"):
				held_ingredient.grill()
		"fryer":
			if held_ingredient and held_ingredient.has_method("fry"):
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
		held_ingredient.global_position += Vector2(0, 32)
		# Ensure the ingredient is in the ingredients group
		if not held_ingredient.is_in_group("ingredients"):
			held_ingredient.add_to_group("ingredients")

func drop_ingredient():
	if held_ingredient:
		$Chef.remove_child(held_ingredient)
		held_ingredient.drop()
		held_ingredient = null
		$"../UI/heldItemDisplay/heldItemTexture".clear_box_sprite()

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

func is_facing_position(target_pos: Vector2) -> bool:
	return get_facing_tile() == tileMap.local_to_map(target_pos)
