extends Node2D

signal order_completed(table: Node, customer: Node)

@onready var ingredients_container = $Ingredients
@onready var tilemap = $TileMapLayer
@onready var dayLabel = $UI/dayCounter/dayLabel
@onready var player_scene = preload("res://scenes/player.tscn")
@onready var storeInterface = $UI/storeInterface

var ingredient_scenes = {
	"Lettuce": preload("res://scenes/food/Lettuce.tscn"),
}

var customer_scene = preload("res://scenes/customer.tscn")
var boss_customer_scene = preload("res://scenes/bossCustomer.tscn")
var tutorial_manager_scene = preload("res://scenes/tutorial/tutorial_manager.tscn")

var table_customers = {} # dictionary tracking table and its customer
var spawn_timer: Timer = null
const SPAWN_INTERVAL = 2.0  # time between customer spawns in seconds
var has_spawned_boss = false
var tutorial_manager = null  # eReference to the tutorial manager

func _ready():
	init_tables()
	print("table count = ", table_customers.size())
	
	spawn_timer = Timer.new()
	spawn_timer.one_shot = true
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	
	dayLabel.update_day()
	
	# Get player count from GameData
	var game_data = get_node("/root/GameData")
	if game_data:
		setup_players(game_data.player_count)
		
		# Only spawn customers if not in tutorial mode
		if not game_data.tutorial_mode:
			spawn_customers_for_empty_tables()
		else:
			print("Tutorial mode active - no customers will spawn")
			# Initialize tutorial manager
			setup_tutorial()

func setup_players(count: int):
	# Remove existing player if any
	var existing_player = $player
	if existing_player:
		existing_player.queue_free()
	
	# Disable all cameras first
	$MultiplayerCamera.visible = false
	$MultiplayerCamera.enabled = false
	
	# Handle held item displays
	var held_display2 = $UI/heldItemDisplay2
	if held_display2:
		held_display2.visible = (count == 2)
	
	# Create player 1
	var player1 = player_scene.instantiate()
	player1.name = "player1"
	player1.player_number = 1
	player1.storeInterface = $UI/storeInterface
	add_child(player1)
	player1.global_position = Vector2(-250,-550)
	
	if count == 2:
		# Create player 2
		var player2 = player_scene.instantiate()
		player2.name = "player2"
		player2.player_number = 2
		player2.storeInterface = $UI/storeInterface
		add_child(player2)
		player2.global_position = Vector2(-186,-550)
		
		# Setup multiplayer camera
		var camera = $MultiplayerCamera
		camera.player1 = player1
		camera.player2 = player2
		camera.enabled = true
		camera.visible = true
		camera.make_current()
		
		# Disable individual player cameras
		player1.get_node("Camera2D").enabled = false
		player2.get_node("Camera2D").enabled = false
	else:
		# Single player camera setup
		var player_camera = player1.get_node("Camera2D")
		player_camera.enabled = true
		player_camera.visible = true
		player_camera.make_current()
		
		# Set appropriate zoom for single player - more zoomed out
		player_camera.zoom = Vector2(0.6, 0.6)
		
		# Remove camera limits to allow full level visibility
		player_camera.limit_left = -10000000
		player_camera.limit_top = -10000000
		player_camera.limit_right = 10000000
		player_camera.limit_bottom = 10000000

# finds tables in scene
func init_tables():
	for child in get_children():
		if child.name.begins_with("Tables"):
			for table in child.get_children():
				table_customers[table] = []
				table.order_generated.connect(_on_table_order_generated.bind(table))
				print("table init successful at ", tilemap.local_to_map(table.position))

func get_table_at_tile(tile_pos: Vector2i) -> Node:
	# checks for tables in scene
	for table in table_customers.keys():
		var table_tile = tilemap.local_to_map(table.position)
		if table_tile == tile_pos:
			return table
	return null

func spawn_customers_for_empty_tables():
	var empty_tables = get_empty_tables()
	if empty_tables.is_empty():
		print("No empty tables to spawn customers for")
		return
	spawn_customer_for_table(empty_tables[0])

func spawn_customer_for_table(table: Node):
	var game_data = get_node("/root/GameData")
	
	# In tutorial mode, only spawn if there are no customers at any table
	if game_data and game_data.tutorial_mode:
		for t in table_customers.keys():
			if not table_customers[t].is_empty():
				return
	
	var customer
	# Only spawn boss if it's a boss day and we haven't spawned one yet
	if dayLabel.dayCount % 5 == 0 and not has_spawned_boss:
		customer = boss_customer_scene.instantiate()
		has_spawned_boss = true
	else:
		customer = customer_scene.instantiate()
	
	customer.global_position = Vector2i(-112,-48)
	add_child(customer)
	
	# assigning customer to table
	customer.set_target_table(table)
	table_customers[table].append(customer)
	
	# Only schedule next spawn if not in tutorial mode
	if not game_data or not game_data.tutorial_mode:
		var empty_tables = get_empty_tables()
		if not empty_tables.is_empty():
			# spawning schedule
			spawn_timer.wait_time = SPAWN_INTERVAL
			spawn_timer.start()

func _on_spawn_timer_timeout():
	var empty_tables = get_empty_tables()
	if not empty_tables.is_empty():
		spawn_customer_for_table(empty_tables[0])

func get_empty_tables() -> Array:
	var empty_tables: Array = []
	for table in table_customers.keys():
		if table_customers[table].is_empty():
			empty_tables.append(table)
	return empty_tables

@warning_ignore("shadowed_variable_base_class")
func spawn_ingredient(type, position):
	if ingredient_scenes.has(type):
		var ingredient = ingredient_scenes[type].instantiate()
		ingredient.ingredient_type = type
		ingredient.position = position
		ingredients_container.add_child(ingredient)

func remove_customer_from_table(customer, table):
	if table_customers.has(table):
		table_customers[table].erase(customer)

func _on_table_order_generated(table: Node):
	print("order generated at ", table.position)
	
	# If in tutorial mode, track the order
	if tutorial_manager:
		var game_data = get_node("/root/GameData")
		if game_data and game_data.tutorial_mode:
			# Get the order from the table's current_dishes array
			if table.current_dishes.size() > 0:
				# Get the first dish from the array
				var order = table.current_dishes[0]
				if order and table.possible_dishes.has(order):
					# Store the order in the tutorial manager's pending orders
					tutorial_manager.pending_orders[table] = order
					print("Tutorial: Stored pending order ", order, " for table")

# Add a new function to handle order completion
func _on_order_completed(table: Node, customer: Node):
	# If in tutorial mode, track the completed order
	if tutorial_manager:
		var game_data = get_node("/root/GameData")
		if game_data and game_data.tutorial_mode:
			# Get the order that was completed
			if tutorial_manager.pending_orders.has(table):
				var order = tutorial_manager.pending_orders[table]
				# Mark this item as served in the tutorial manager
				tutorial_manager.served_items[order] = true
				# Remove the pending order
				tutorial_manager.pending_orders.erase(table)
				
				# Check if we've served all possible items
				var all_items_served = true
				for item in game_data.possible_dishes:
					if not tutorial_manager.served_items.has(item):
						all_items_served = false
						break
				
				if all_items_served:
					tutorial_manager.finish_tutorial()
				else:
					# Generate a new order with the next unserved dish
					var next_dish = null
					for item in game_data.possible_dishes:
						if not tutorial_manager.served_items.has(item):
							next_dish = item
							break
					
					if next_dish:
						# Update the table's possible_dishes array to only include the next dish
						table.possible_dishes.clear()
						table.possible_dishes.append(next_dish)
						
						# Wait a short moment before spawning the next customer
						await get_tree().create_timer(1.0).timeout
						# Spawn a new customer for the table
						spawn_customer_for_table(table)

func toggle_store():
	if storeInterface.visible:
		storeInterface.hide()
	else:
		storeInterface.show()

func _on_day_label_day_changed() -> void:
	has_spawned_boss = false
	storeInterface.refresh_stock()
	
	# clear all customers if they exist
	print("regular customers spawning")
	for table in table_customers.keys():
		for customer in table_customers[table]:
			customer.queue_free()
		table_customers[table].clear()
	
	# Only spawn customers if not in tutorial mode
	var game_data = get_node("/root/GameData")
	if game_data and not game_data.tutorial_mode:
		spawn_customers_for_empty_tables()

func setup_tutorial():
	# Initialize tutorial manager
	tutorial_manager = tutorial_manager_scene.instantiate()
	add_child(tutorial_manager)
	
	# Force set visibility
	tutorial_manager.visible = true
	
	# Initialize tutorial with reference to player 1
	var player1 = get_node_or_null("player1")
	var player2 = get_node_or_null("player2")
	
	if player1 and player2:
		print("Found both players, initializing tutorial")
		tutorial_manager.initialize(player1, false)  # false for player 1
		
		# Create a second tutorial manager for player 2
		var tutorial_manager2 = tutorial_manager_scene.instantiate()
		add_child(tutorial_manager2)
		tutorial_manager2.visible = true
		tutorial_manager2.initialize(player2, true)  # true for player 2
		
		# Get the first table and initialize its possible_dishes array
		var first_table = get_node("Tables").get_child(0)
		if first_table:
			# Get the game data
			var game_data = get_node("/root/GameData")
			if game_data:
				# Copy the table's possible_dishes to game_data
				game_data.possible_dishes = first_table.possible_dishes.duplicate()
				print("Tutorial: Initialized possible_dishes with ", game_data.possible_dishes.size(), " dishes")
				
				# Spawn initial customer
				spawn_customer_for_table(first_table)
	else:
		print("WARNING: Could not find both players for tutorial")
		# Try to find any player nodes
		if not player1:
			player1 = find_player_node()
		if not player2:
			player2 = find_player_node()
			
		if player1:
			print("Found player1, initializing tutorial")
			tutorial_manager.initialize(player1, false)  # false for player 1
		if player2:
			print("Found player2, initializing tutorial")
			var tutorial_manager2 = tutorial_manager_scene.instantiate()
			add_child(tutorial_manager2)
			tutorial_manager2.visible = true
			tutorial_manager2.initialize(player2, true)  # true for player 2
		if not player1 and not player2:
			print("ERROR: Cannot initialize tutorial - no players found")

# Find the first player node in the scene
func find_player_node():
	for child in get_children():
		if child.name.begins_with("player"):
			return child
	return null

# Add a function to handle order completion
func complete_order(table: Node, customer: Node):
	# Emit the order completion signal
	order_completed.emit(table, customer)
