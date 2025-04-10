extends Node2D

# Preload key icon scene and E key texture
var key_icon_scene = preload("res://scenes/tutorial/key_icon.tscn")
var e_key_texture = preload("res://textures/UISprites/icons8-e-key-50.png")

# Reference to the player
var player: Node = null

# Reference to player 2
var player2: Node = null

# Reference to E key sprite
var e_key_sprite: Sprite2D = null

# Icon positions relative to the player
var icon_positions = {
	"w": Vector2(0, -50),  # Above
	"a": Vector2(-40, 0),  # Left
	"s": Vector2(0, 40),   # Below
	"d": Vector2(40, 0),   # Right
	"up": Vector2(0, -50),    # player 2
	"left": Vector2(-40, 0),
	"down": Vector2(0, 40),
	"right": Vector2(40, 0)
}

# Icon scales
var key_scales = {
	"w": Vector2(0.6, 0.6),  # WASD keys
	"a": Vector2(0.6, 0.6),
	"s": Vector2(0.6, 0.6),
	"d": Vector2(0.6, 0.6),
	"up": Vector2(0.6, 0.6),    #player 2
	"left": Vector2(0.6, 0.6),
	"down": Vector2(0.6, 0.6),
	"right": Vector2(0.6, 0.6)
}

# Tutorial stages
enum TutorialStage {
	MOVEMENT,
	LETTUCE_INTERACTION
}

var current_stage = TutorialStage.MOVEMENT

# key icons created
var created_icons = {}

# Dictionary to store appliance positions
var appliance_positions = {
	"lettuce": Vector2(-1, -11),    
	"tomato": Vector2(-4, -11),    
	"cup": Vector2(-3, -8),     
	"chicken": Vector2(5, -11),  
	"chopping_board": Vector2(-2, -11),
	"tea": Vector2(-2, -8),        
	"tapioca": Vector2(0, -8),     
	"fryer": Vector2(2, -11),      
	"bowl": Vector2(-4, -8),       
	"plate": Vector2(0, -11),      
	"lid": Vector2(2, -8),         
	"table": Vector2(-1, -5)       
}

var served_items = {}

var pending_orders = {}

var current_dish_index = 0
var current_step_index = 0
var dish_steps = {
	"lettuce_salad": [
		{"appliance": "lettuce", "action": "pick_up_lettuce"},
		{"appliance": "chopping_board", "action": "chop_lettuce"},
		{"appliance": "bowl", "action": "bowl_lettuce"},
		{"appliance": "table", "action": "serve"}
	],
	"tomato_salad": [
		{"appliance": "tomato", "action": "pick_up_tomato"},
		{"appliance": "chopping_board", "action": "chop_tomato"},
		{"appliance": "bowl", "action": "bowl_tomato"},
		{"appliance": "table", "action": "serve"}
	],
	"boba": [
		{"appliance": "cup", "action": "pick_up_cup"},
		{"appliance": "tea", "action": "getTea"},
		{"appliance": "tapioca", "action": "getTapioca"},
		{"appliance": "lid", "action": "lid"},
		{"appliance": "table", "action": "serve"}
	],
	"fried_chicken": [
		{"appliance": "chicken", "action": "pick_up_chicken"},
		{"appliance": "fryer", "action": "fry"},
		{"appliance": "plate", "action": "plate_chicken"},
		{"appliance": "table", "action": "serve"}
	]
}

# track if this is player 2
var is_player2 = false

var is_step_transitioning = false

var player1_progress = {"dish_index": 0, "step_index": 0}
var player2_progress = {"dish_index": 0, "step_index": 0}

var current_step_last_printed = ""

# Add this variable at the top with other variables
var last_bowl_check_texture = null

func _ready():
	# Display is initially disabled
	visible = false
	
	# Connect to the order completion signal
	var main_scene = get_parent()
	if main_scene:
		main_scene.order_completed.connect(_on_order_completed)

# setup the tutorial manager
func initialize(player_node, player2: bool = false):
	player = player_node
	is_player2 = player2
	visible = true
	
	for key in appliance_positions.keys():
		var tile_pos = appliance_positions[key]
		appliance_positions[key] = player.tileMap.map_to_local(tile_pos)
	
	
	start_movement_tutorial()

	spawn_first_customer()

func spawn_first_customer():
	var game_data = get_node("/root/GameData")
	if not game_data or not game_data.possible_dishes or current_dish_index >= game_data.possible_dishes.size():
		print("Cannot spawn customer: no valid dish available")
		return
	
	var current_dish = game_data.possible_dishes[current_dish_index]
	print("Spawning customer for dish index: ", current_dish_index)
	print("Dish: ", current_dish)
	
	if current_dish is AtlasTexture:
		print("DEBUG: Spawning customer for dish with texture path: ", current_dish.resource_path)
	
	if current_dish:
		var main_scene = player.get_parent()
		if main_scene:
			for table in main_scene.table_customers.keys():
				if main_scene.table_customers[table].is_empty():
					table.possible_dishes.clear()
					table.possible_dishes.append(current_dish)

					pending_orders[table] = current_dish
					print("Tutorial: Stored pending order ", current_dish, " for table")
					main_scene.spawn_customer_for_table(table)
					break

func _on_order_completed(table: Node, customer: Node):
	var game_data = get_node("/root/GameData")
	if not game_data or not game_data.possible_dishes:
		return
	
	# Get the order that was completed
	if pending_orders.has(table):
		var order = pending_orders[table]
		served_items[order] = true
		pending_orders.erase(table)
		
		print_detailed_tutorial_state()
		
		var all_items_served = true
		for item in game_data.possible_dishes:
			if not served_items.has(item):
				all_items_served = false
				break
		
		if all_items_served:
			finish_tutorial()
		else:			
			is_step_transitioning = true
			
			current_dish_index += 1
			current_step_index = 0
			
			if current_dish_index >= game_data.possible_dishes.size():
				finish_tutorial()
				is_step_transitioning = false
				return
			
			
			if current_dish_index == 1:  # Moving to tomato salad
				if e_key_sprite != null and appliance_positions.has("tomato"):
					e_key_sprite.position = appliance_positions["tomato"] + Vector2(0, -15)
					
					player1_progress.dish_index = 1
					player1_progress.step_index = 0
					player2_progress.dish_index = 1
					player2_progress.step_index = 0
			elif current_dish_index == 2:  # Moving to boba 
				var cup_position = appliance_positions["cup"] + Vector2(0, -15)
				if e_key_sprite != null and appliance_positions.has("cup"):
					e_key_sprite.position = cup_position
					
					player1_progress.dish_index = 2
					player1_progress.step_index = 0
					player2_progress.dish_index = 2
					player2_progress.step_index = 0
					
				else:
					print("ERROR: Cup appliance position not found or E key is null!")
			elif current_dish_index == 3:  # Moving to fried chicken (fourth dish)
				if e_key_sprite != null and appliance_positions.has("chicken"):
					e_key_sprite.position = appliance_positions["chicken"] + Vector2(0, -15)
					
					player1_progress.dish_index = 3
					player1_progress.step_index = 0
					player2_progress.dish_index = 3
					player2_progress.step_index = 0
			
			var next_dish = game_data.possible_dishes[current_dish_index]
			var next_dish_name = get_dish_name(next_dish)
			
			
			if current_dish_index == 1:
				next_dish_name = "tomato_salad"
			elif current_dish_index == 2:
				next_dish_name = "boba"
			elif current_dish_index == 3:
				next_dish_name = "fried_chicken"
			
			print("Forced dish name: ", next_dish_name)
			
			if dish_steps.has(next_dish_name):
				print("Found steps for dish: ", next_dish_name)
				var first_step = dish_steps[next_dish_name][0]
				print("First step appliance: ", first_step.appliance)
			else:
				print("No steps found for dish: ", next_dish_name)
			
			# Generate a new order with the next unserved dish
			var next_dish_for_order = null
			for item in game_data.possible_dishes:
				if not served_items.has(item):
					next_dish_for_order = item
					break
			
			if next_dish_for_order:
				# Update the table's possible_dishes array to only include the next dish
				table.possible_dishes.clear()
				table.possible_dishes.append(next_dish_for_order)
				
				# Get the main scene to spawn a new customer
				var main_scene = player.get_parent()
				if main_scene:
					# Wait a short moment before spawning the next customer
					await get_tree().create_timer(1.0).timeout
					# Spawn a new customer for the table
					main_scene.spawn_customer_for_table(table)
			
			# Clear transition flag after all updates
			is_step_transitioning = false
			
			# Print state after changes to verify
			print_detailed_tutorial_state()

func start_movement_tutorial():
	current_stage = TutorialStage.MOVEMENT
	if is_player2:
		create_key_icons(["up", "left", "down", "right"])
	else:
		create_key_icons(["w", "a", "s", "d"])

func create_key_icons(keys):
	# Clear any existing icons
	clear_all_icons()
	
	
	# Create new icons
	for key in keys:
		if key == "e":
			print("Creating E key icon...")
			# Create a simple sprite for the E key
			e_key_sprite = Sprite2D.new()
			e_key_sprite.texture = e_key_texture
			e_key_sprite.scale = Vector2(0.3, 0.3)
			e_key_sprite.z_index = 100
			
			# Add to the map
			var map = player.tileMap
			if map:
				map.add_child(e_key_sprite)
				print("E key icon added to map")
				
				# Set initial position for lettuce station
				var lettuce_tile_pos = Vector2(-1, -11)
				var lettuce_local_pos = player.tileMap.map_to_local(lettuce_tile_pos)
				e_key_sprite.position = lettuce_local_pos + Vector2(0, -15)
				print("E key position set to: ", e_key_sprite.position)
			else:
				print("ERROR: Could not find Map node!")
				get_tree().root.add_child(e_key_sprite)
				print("E key icon added to root scene (fallback)")
		else:
			# Create movement key icons using the key icon scene
			var key_icon = key_icon_scene.instantiate()
			key_icon.name = key.to_upper() + "KeyIcon"
			key_icon.key_name = key
			key_icon.is_player2 = is_player2
			add_child(key_icon)
			key_icon.position = icon_positions[key]
			key_icon.scale = key_scales[key]
			key_icon.z_index = 100
			created_icons[key] = key_icon
		
		print("Created ", key, " key")

func clear_all_icons():
	# Clear movement key icons
	for key in created_icons.keys():
		if created_icons[key] != null:
			created_icons[key].queue_free()
	created_icons.clear()
	
	# Clear E key sprite
	if e_key_sprite != null:
		e_key_sprite.queue_free()
		e_key_sprite = null

# Check if all movement keys have been pressed
func check_movement_progress():
	# Check if all movement keys have been pressed for either player
	var all_pressed = true
	var keys_pressed_count = 0
	
	# Check both players' movement keys
	var keys_to_check = ["w", "a", "s", "d", "up", "left", "down", "right"]
	
	for key in keys_to_check:
		if created_icons.has(key) and created_icons[key] != null:
			if created_icons[key].has_been_pressed:
				keys_pressed_count += 1
			else:
				all_pressed = false
	
	# If all movement keys pressed, move to next stage
	if all_pressed and current_stage == TutorialStage.MOVEMENT:
		print("All movement keys pressed! Moving to next stage...")
		start_appliance_interaction_tutorial()

func start_appliance_interaction_tutorial():
	print("Starting appliance tutorial")
	
	# Clear previous icons first
	clear_all_icons()
	
	# Create E key icon for appliance interaction
	create_key_icons(["e"])
	
	# Reset dish and step indices
	current_dish_index = 0
	current_step_index = 0
	
	# current stage to first appliance interaction
	current_stage = TutorialStage.LETTUCE_INTERACTION
	
	# Get the game data
	var game_data = get_node("/root/GameData")
	if not game_data or not game_data.possible_dishes:
		print("No game data or possible dishes found")
		return
	
	# Get the first dish
	var first_dish = game_data.possible_dishes[0]
	if not first_dish:
		print("No first dish found")
		return
		
	print("First dish: ", first_dish)
	
	# Convert the dish texture to a string identifier
	var dish_name = ""
	if first_dish is AtlasTexture:
		# Map texture to dish name by comparing resource paths
		var first_dish_path = first_dish.resource_path
		print("First dish path: ", first_dish_path)
		
		if first_dish_path == "res://textures/FoodSprites/tilemap_pack_49.tres":
			dish_name = "lettuce_salad"
		elif first_dish_path == "res://textures/FoodSprites/tilemap_pack_50.tres":
			dish_name = "tomato_salad"
		elif first_dish_path == "res://textures/FoodSprites/tilemap_pack_31.tres":
			dish_name = "boba"
		elif first_dish_path == "res://textures/FoodSprites/rawChicken.tres":
			dish_name = "fried_chicken"
		elif first_dish_path == "res://textures/FoodSprites/tilemap_pack_40.tres":
			dish_name = "lettuce_salad"  # This is the bowl_lettuce texture
		else:
			print("Unknown dish texture path: ", first_dish_path)
	else:
		dish_name = first_dish
	
	print("Mapped dish name: ", dish_name)
	
	# Get the first step for this dish
	if dish_steps.has(dish_name):
		var steps = dish_steps[dish_name]
		if steps.size() > 0:
			var first_step = steps[0]
			print("First step: ", first_step)
			
			# Update E key position for the first step
			if appliance_positions.has(first_step.appliance):
				if e_key_sprite != null:
					e_key_sprite.position = appliance_positions[first_step.appliance] + Vector2(0, -15)
					print("E key moved to: ", first_step.appliance)
					print("New position: ", e_key_sprite.position)
				else:
					print("E key sprite is null!")
			else:
				print("Appliance position not found for: ", first_step.appliance)
		else:
			print("No steps found for dish: ", dish_name)
	else:
		print("No steps defined for dish: ", dish_name)
	
	# Spawn first customer
	spawn_first_customer()

func _process(delta):
	if player and visible:
		if current_stage == TutorialStage.MOVEMENT:
			global_position = player.global_position
			check_movement_progress()
		else:
			var current_step = get_current_step()
			if current_step and appliance_positions.has(current_step.appliance):
				if e_key_sprite != null:
					e_key_sprite.visible = true
					# Only update position if we're not in the middle of a step transition
					# and this is the most progressed player
					var most_progressed = get_most_progressed_player()
					if not is_step_transitioning and \
					   ((most_progressed == "player1" and not is_player2) or \
						(most_progressed == "player2" and is_player2)):
						# Only print current step when it changes to reduce output
						if current_step_last_printed != current_step.action:
							print("Current step: ", current_step.appliance, " - ", current_step.action)
							current_step_last_printed = current_step.action
						e_key_sprite.position = appliance_positions[current_step.appliance] + Vector2(0, -15)
					check_step_completion(current_step)

# Get the current step from dish_steps
func get_current_step():
	var game_data = get_node("/root/GameData")
	if not game_data or not game_data.possible_dishes:
		return null
	
	if current_dish_index >= game_data.possible_dishes.size():
		print("DEBUG: current_dish_index out of bounds: ", current_dish_index)
		return null
	
	var current_dish = game_data.possible_dishes[current_dish_index]
	
	# Convert the dish texture to a string identifier
	var dish_name = get_dish_name(current_dish)
	
	if dish_steps.has(dish_name):
		var steps = dish_steps[dish_name]
		if current_step_index < steps.size():
			var step = steps[current_step_index]
			return step
		else:
			print("DEBUG: step_index out of bounds: ", current_step_index, " for dish: ", dish_name)
	else:
		print("DEBUG: no steps for dish: ", dish_name)
		
		# Fallback for tomato salad if we're on dish index 1
		if current_dish_index == 1:
			print("DEBUG: Applying tomato_salad fallback")
			if dish_steps.has("tomato_salad") and current_step_index < dish_steps["tomato_salad"].size():
				var step = dish_steps["tomato_salad"][current_step_index]
				return step
	
	return null

# Check if the current step is completed
func check_step_completion(step):
	if current_stage == TutorialStage.MOVEMENT:
		var all_pressed = true
		var keys_pressed_count = 0
		
		var keys_to_check = ["w", "a", "s", "d", "up", "left", "down", "right"]
		
		for key in keys_to_check:
			if created_icons.has(key) and created_icons[key] != null:
				if created_icons[key].has_been_pressed:
					keys_pressed_count += 1
				else:
					all_pressed = false
		
		if all_pressed:
			start_appliance_interaction_tutorial()
	else:
		var completed = false
		var completing_player = null
		
		# Check both players' ingredients
		if player:
			var ingredient = player.held_ingredient
			if ingredient and check_ingredient_state(ingredient, step):
				completed = true
				completing_player = "player1"
				print("Player 1 completed step: ", step.action)
		
		if not completed and player2:
			var ingredient = player2.held_ingredient
			if ingredient and check_ingredient_state(ingredient, step):
				completed = true
				completing_player = "player2"
				print("Player 2 completed step: ", step.action)
		
		if completed:
			# Update progress for the completing player
			if completing_player == "player1":
				player1_progress.dish_index = current_dish_index
				player1_progress.step_index = current_step_index + 1  # +1 because we're completing this step
				print("Updated player1_progress: dish=", player1_progress.dish_index, ", step=", player1_progress.step_index)
			else:
				player2_progress.dish_index = current_dish_index
				player2_progress.step_index = current_step_index + 1  # +1 because we're completing this step
				print("Updated player2_progress: dish=", player2_progress.dish_index, ", step=", player2_progress.step_index)
			
			# Only move to next step if this is the most progressed player
			var most_progressed = get_most_progressed_player()
			if (completing_player == "player1" and most_progressed == "player1") or \
			   (completing_player == "player2" and most_progressed == "player2"):
				print("Moving to next step after completing: ", step.action)
				
				# Check if this is the last step of the current dish
				var game_data = get_node("/root/GameData")
				if game_data and game_data.possible_dishes:
					var current_dish = game_data.possible_dishes[current_dish_index]
					var dish_name = get_dish_name(current_dish)
					
					if dish_steps.has(dish_name):
						var steps = dish_steps[dish_name]
						if current_step_index >= steps.size() - 1:
							print("This is the last step of the current dish. Moving to next dish.")
							# This is the last step, move to next dish
							current_dish_index += 1
							current_step_index = 0
							
							# If we've gone through all dishes, finish the tutorial
							if current_dish_index >= game_data.possible_dishes.size():
								finish_tutorial()
								return
							
							# Get the next dish's name and move E key to first step
							move_to_next_dish()
						else:
							# Not the last step, just move to next step in current dish
							move_to_next_step()
				else:
					# If game_data or possible_dishes is missing, just try to move to next step
					move_to_next_step()
				
				# Special handling for bowl actions - force update E key position to table
				if step.action == "bowl_lettuce" or step.action == "bowl_tomato":
					if e_key_sprite != null and appliance_positions.has("table"):
						e_key_sprite.position = appliance_positions["table"] + Vector2(0, -15)
						print("Forced E key to table position after bowl action")
						print("New position: ", e_key_sprite.position)
				
				# If we just completed a serve action, spawn the next customer
				if step.action == "serve":
					print("*** SERVE ACTION DETECTED! ***")
					print_detailed_tutorial_state()
					
					# Force move to the next dish's first step
					if game_data and game_data.possible_dishes:
						if current_dish_index + 1 < game_data.possible_dishes.size():
							# Move to the next dish
							current_dish_index += 1
							current_step_index = 0
							
							print("After serving dish, moving to dish index: ", current_dish_index)
							
							# SPECIAL CASE handling for each dish transition
							if current_dish_index == 1:  # Moving to tomato salad (dish 2)
								print("*** TRANSITIONING TO TOMATO SALAD ***")
								if e_key_sprite != null and appliance_positions.has("tomato"):
									e_key_sprite.position = appliance_positions["tomato"] + Vector2(0, -15)
									print("FORCED E key to tomato station at: ", e_key_sprite.position)
									# Update player progress explicitly
									player1_progress.dish_index = current_dish_index
									player1_progress.step_index = 0
									player2_progress.dish_index = current_dish_index
									player2_progress.step_index = 0
							elif current_dish_index == 2:  # Moving to boba (dish 3)
								print("*** TRANSITIONING TO BOBA ***")
								var cup_position = appliance_positions["cup"] + Vector2(0, -15)
								if e_key_sprite != null and appliance_positions.has("cup"):
									e_key_sprite.position = cup_position
									print("FORCED E key to cup station at: ", e_key_sprite.position)
									
									# Force update player progress
									player1_progress.dish_index = 2
									player1_progress.step_index = 0
									player2_progress.dish_index = 2
									player2_progress.step_index = 0
									
									# Force dish_name to be 'boba'
									var next_dish = game_data.possible_dishes[current_dish_index]
									var fallback_dish_name = "boba"
									
									print("Cup position: ", cup_position)
									print("After forcing boba transition - Current dish index: ", current_dish_index)
									print("Current step index: ", current_step_index)
								else:
									print("ERROR: Cup appliance position not found or E key is null!")
							elif current_dish_index == 3:  # Moving to fried chicken (dish 4)
								print("*** TRANSITIONING TO FRIED CHICKEN ***")
								if e_key_sprite != null and appliance_positions.has("chicken"):
									e_key_sprite.position = appliance_positions["chicken"] + Vector2(0, -15)
									print("FORCED E key to chicken station at: ", e_key_sprite.position)
									# Update player progress explicitly
									player1_progress.dish_index = current_dish_index
									player1_progress.step_index = 0
									player2_progress.dish_index = current_dish_index
									player2_progress.step_index = 0
							else:
								# Get the next dish's first step
								var next_dish = game_data.possible_dishes[current_dish_index]
								var next_dish_name = get_dish_name(next_dish)
								
								if dish_steps.has(next_dish_name) and dish_steps[next_dish_name].size() > 0:
									var first_step = dish_steps[next_dish_name][0]
									if e_key_sprite != null and appliance_positions.has(first_step.appliance):
										e_key_sprite.position = appliance_positions[first_step.appliance] + Vector2(0, -15)
										print("SERVE ACTION: Moved E key to next dish's first step: ", first_step.appliance)
										print("New position: ", e_key_sprite.position)
							
					# Now spawn the next customer
					spawn_first_customer()

# Helper function to check ingredient state
func check_ingredient_state(ingredient, step):
	if ingredient == null:
		return false
		
	if not ingredient.has_node("Sprite2D"):
		return false
		
	var ingredient_texture = ingredient.get_node("Sprite2D").texture
	
	match step.action:
		"pick_up_lettuce":
			var expected_texture = preload("res://textures/FoodSprites/tilemap_pack_49.tres")
			return ingredient_texture == expected_texture
			
		"pick_up_tomato":
			var expected_texture = preload("res://textures/FoodSprites/tilemap_pack_50.tres")
			return ingredient_texture == expected_texture
			
		"pick_up_chicken":
			var expected_texture = preload("res://textures/FoodSprites/rawChicken.tres")
			return ingredient_texture == expected_texture
			
		"pick_up_cup":
			var expected_texture = preload("res://textures/FoodSprites/tilemap_pack_31.tres")
			return ingredient_texture == expected_texture
			
		"chop_lettuce":
			var expected_texture = preload("res://textures/FoodSprites/tilemap_pack_48.tres")
			return ingredient_texture == expected_texture
			
		"chop_tomato":
			var expected_texture = preload("res://textures/FoodSprites/tilemap_pack_51.tres")
			return ingredient_texture == expected_texture
			
		"bowl_lettuce":
			var expected_texture = preload("res://textures/FoodSprites/tilemap_pack_40.tres")
			# Only print this when ingredient changes to reduce spam
			if not last_bowl_check_texture or last_bowl_check_texture != ingredient_texture.resource_path:
				print("Checking for bowl_lettuce, comparing textures:")
				print("Actual texture: ", ingredient_texture.resource_path)
				print("Expected texture: ", expected_texture.resource_path)
				last_bowl_check_texture = ingredient_texture.resource_path
			var result = ingredient_texture == expected_texture
			return result
			
		"bowl_tomato":
			var expected_texture = preload("res://textures/FoodSprites/tilemap_pack_42.tres")
			return ingredient_texture == expected_texture
			
		"plate_chicken":
			var expected_texture = preload("res://textures/FoodSprites/tilemap_pack_24.tres")
			return ingredient_texture == expected_texture
			
		"getTea":
			var expected_texture = preload("res://textures/FoodSprites/tilemap_pack_32.tres")
			return ingredient_texture == expected_texture
			
		"getTapioca":
			var expected_texture = preload("res://textures/FoodSprites/tilemap_pack_34.tres")
			return ingredient_texture == expected_texture
			
		"lid":
			var expected_texture = preload("res://textures/FoodSprites/tilemap_pack_30.tres")
			return ingredient_texture == expected_texture
			
		"fry":
			var expected_texture = preload("res://textures/FoodSprites/tilemap_pack_10.tres")
			return ingredient_texture == expected_texture
			
		"serve":
			# Only allow serve action if an interact button was pressed
			if not (Input.is_action_just_pressed("player1_interact") or Input.is_action_just_pressed("player2_interact")):
				# Don't spam this message
				if Engine.get_frames_drawn() % 60 == 0:  # Only print once per second
					print("No interact button pressed for serve action")
				return false
				
			# Check for player position - must be near a table
			var player_pos = null
			if player and ingredient.get_parent() == player:
				player_pos = player.global_position
			elif player2 and ingredient.get_parent() == player2:
				player_pos = player2.global_position
				
			if not player_pos:
				print("Player position not found or ingredient not held by player")
				return false
				
			# Check if player is near a table
			var near_table = false
			var main_scene = ingredient.get_parent().get_parent()
			if main_scene and main_scene.has_node("Tables"):
				var tables = main_scene.get_node("Tables")
				for table in tables.get_children():
					if table and table.global_position.distance_to(player_pos) < 100:
						near_table = true
						break
						
			if not near_table:
				print("Player not near any table")
				return false
			
			# Only now check if the ingredient matches the order
			if main_scene:
				for table in main_scene.table_customers.keys():
					if not main_scene.table_customers[table].is_empty():
						var table_node = table
						if table_node and table_node.has_method("serve"):
							# Check if the ingredient's texture matches any of the table's current dishes
							for dish in table_node.current_dishes:
								if ingredient_texture == dish:
									print("Found match for serve action!")
									return true
			print("No match found for serve action")
			return false
	return false

# Helper function to get dish name from texture
func get_dish_name(dish):
	if dish is AtlasTexture:
		var dish_path = dish.resource_path
		# Only print dish path if it's not a known path
		if dish_path != "res://textures/FoodSprites/tilemap_pack_49.tres" and \
		   dish_path != "res://textures/FoodSprites/tilemap_pack_50.tres" and \
		   dish_path != "res://textures/FoodSprites/tilemap_pack_31.tres" and \
		   dish_path != "res://textures/FoodSprites/rawChicken.tres" and \
		   dish_path != "res://textures/FoodSprites/tilemap_pack_40.tres":
			print("DEBUG: get_dish_name - Unusual dish path: " + dish_path)
		
		if dish_path == "res://textures/FoodSprites/tilemap_pack_49.tres":
			return "lettuce_salad"
		elif dish_path == "res://textures/FoodSprites/tilemap_pack_50.tres":
			return "tomato_salad"
		elif dish_path == "res://textures/FoodSprites/tilemap_pack_31.tres":
			return "boba"
		elif dish_path == "res://textures/FoodSprites/rawChicken.tres":
			return "fried_chicken"
		elif dish_path == "res://textures/FoodSprites/tilemap_pack_40.tres":
			return "lettuce_salad"  # This is the bowl_lettuce texture
		# Add missing texture paths that might be causing the issue
		elif "tomato" in dish_path.to_lower():
			return "tomato_salad"
		else:
			# If we can't identify the dish, print its path for debugging
			print("DEBUG: Unknown dish texture path in get_dish_name: ", dish_path)
			# Default fallback - assume it's the second dish (tomato salad)
			if current_dish_index == 1:
				return "tomato_salad"
			elif current_dish_index == 2:
				return "boba"
			elif current_dish_index == 3:
				return "fried_chicken"
	return "lettuce_salad"  # Default fallback

# New function to handle transition to next dish
func move_to_next_dish():
	is_step_transitioning = true
	
	var game_data = get_node("/root/GameData")
	if not game_data or current_dish_index >= game_data.possible_dishes.size():
		is_step_transitioning = false
		return
	
	print("move_to_next_dish called, moving to dish index: ", current_dish_index)
	print_detailed_tutorial_state()
	
	# HARDCODE the transitions based on dish index to ensure reliability
	if current_dish_index == 1:  # Moving to tomato salad (dish 2)
		print("*** MOVE_TO_NEXT_DISH - TRANSITIONING TO TOMATO SALAD ***")
		if e_key_sprite != null and appliance_positions.has("tomato"):
			e_key_sprite.position = appliance_positions["tomato"] + Vector2(0, -15)
			print("FORCED E key to tomato station at: ", e_key_sprite.position)
			
			# Always force dish indices
			player1_progress.dish_index = 1
			player1_progress.step_index = 0
			player2_progress.dish_index = 1
			player2_progress.step_index = 0
			
			is_step_transitioning = false
			return
	elif current_dish_index == 2:  # Moving to boba (dish 3)
		print("*** MOVE_TO_NEXT_DISH - TRANSITIONING TO BOBA ***")
		if e_key_sprite != null and appliance_positions.has("cup"):
			# Use absolute position to ensure consistency
			var cup_position = appliance_positions["cup"] + Vector2(0, -15)
			e_key_sprite.position = cup_position
			print("FORCED E key to cup station at: ", e_key_sprite.position)
			
			# Always force dish indices to ensure consistency
			player1_progress.dish_index = 2
			player1_progress.step_index = 0
			player2_progress.dish_index = 2
			player2_progress.step_index = 0
			
			# Force current_dish_index/step_index again to be extra sure
			current_dish_index = 2
			current_step_index = 0
			
			print("Cup position: ", cup_position)
			print("After forcing boba transition: dish_index=", current_dish_index, ", step_index=", current_step_index)
			
			is_step_transitioning = false
			print_detailed_tutorial_state()
			return
	elif current_dish_index == 3:  # Moving to fried chicken (dish 4)
		print("*** MOVE_TO_NEXT_DISH - TRANSITIONING TO FRIED CHICKEN ***")
		if e_key_sprite != null and appliance_positions.has("chicken"):
			e_key_sprite.position = appliance_positions["chicken"] + Vector2(0, -15)
			print("FORCED E key to chicken station at: ", e_key_sprite.position)
			
			# Always force dish indices
			player1_progress.dish_index = 3
			player1_progress.step_index = 0
			player2_progress.dish_index = 3
			player2_progress.step_index = 0
			
			is_step_transitioning = false
			return
	
	# Standard handling if not a special case - we should never reach here
	print("WARNING: Fallback dish transition logic used - this is unexpected!")
	
	var next_dish = game_data.possible_dishes[current_dish_index]
	
	# Force the dish name based on index to ensure consistency
	var dish_name = ""
	if current_dish_index == 1:
		dish_name = "tomato_salad"
	elif current_dish_index == 2:
		dish_name = "boba"
	elif current_dish_index == 3:
		dish_name = "fried_chicken"
	else:
		dish_name = get_dish_name(next_dish)
	
	print("Forced dish name: ", dish_name)
	
	if dish_steps.has(dish_name):
		var next_steps = dish_steps[dish_name]
		if next_steps.size() > 0:
			var first_step = next_steps[0]
			if appliance_positions.has(first_step.appliance):
				if e_key_sprite != null:
					e_key_sprite.position = appliance_positions[first_step.appliance] + Vector2(0, -15)
					print("E key moved to next dish's first step: ", first_step.appliance)
					print("New position: ", e_key_sprite.position)
					
					# Update player progress
					player1_progress.dish_index = current_dish_index
					player1_progress.step_index = 0
					player2_progress.dish_index = current_dish_index
					player2_progress.step_index = 0
				else:
					print("E key sprite is null!")
			else:
				print("Appliance position not found for: ", first_step.appliance)
		else:
			print("No steps found for next dish: ", dish_name)
	else:
		print("No steps defined for next dish: ", dish_name)
	
	is_step_transitioning = false

# Move to the next step in the current dish
func move_to_next_step():
	is_step_transitioning = true
	current_step_index += 1
	var game_data = get_node("/root/GameData")
	if not game_data or not game_data.possible_dishes:
		is_step_transitioning = false
		return
	
	var current_dish = game_data.possible_dishes[current_dish_index]
	var dish_name = get_dish_name(current_dish)
	
	if dish_steps.has(dish_name):
		var steps = dish_steps[dish_name]
		
		# Check if we have more steps in the current dish
		if current_step_index < steps.size():
			# Update E key position for current step
			var next_step = steps[current_step_index]
			if appliance_positions.has(next_step.appliance):
				if e_key_sprite != null:
					e_key_sprite.position = appliance_positions[next_step.appliance] + Vector2(0, -15)
					print("E key moved to next step in current dish: ", next_step.appliance)
					print("New position: ", e_key_sprite.position)
				else:
					print("E key sprite is null!")
			else:
				print("Appliance position not found for: ", next_step.appliance)
		else:
			# This shouldn't happen now that we use move_to_next_dish for dish transitions
			print("WARNING: Reached end of steps for current dish in move_to_next_step!")
	else:
		print("No steps defined for current dish: ", dish_name)
	
	is_step_transitioning = false

func finish_tutorial():
	print("Tutorial complete!")
	visible = false
	clear_all_icons()

# Update the print_appliance_positions function
func print_appliance_positions():
	print("\n--- CURRENT APPLIANCE POSITIONS ---")
	for key in appliance_positions.keys():
		print(key + ": ", appliance_positions[key])
	print("-------------------------------\n")

# Add this helper function to determine the most progressed player
func get_most_progressed_player():
	# Compare dish indices first
	if player1_progress.dish_index > player2_progress.dish_index:
		return "player1"
	elif player2_progress.dish_index > player1_progress.dish_index:
		return "player2"
	
	# If dish indices are equal, compare step indices
	if player1_progress.step_index > player2_progress.step_index:
		return "player1"
	elif player2_progress.step_index > player1_progress.step_index:
		return "player2"
	
	# If both are equal, default to player1
	return "player1"

# Add this function to get detailed diagnostics when needed
func print_detailed_tutorial_state():
	print("\n--- DETAILED TUTORIAL STATE ---")
	print("Current dish index: ", current_dish_index)
	print("Current step index: ", current_step_index)
	
	var game_data = get_node("/root/GameData")
	if game_data and current_dish_index < game_data.possible_dishes.size():
		var current_dish = game_data.possible_dishes[current_dish_index]
		print("Current dish object: ", current_dish)
		if current_dish is AtlasTexture:
			print("Current dish texture path: ", current_dish.resource_path)
		
		var dish_name = get_dish_name(current_dish)
		print("Mapped dish name: ", dish_name)
		
		if dish_steps.has(dish_name):
			if current_step_index < dish_steps[dish_name].size():
				var current_step = dish_steps[dish_name][current_step_index]
				print("Current step: ", current_step.appliance, " - ", current_step.action)
			else:
				print("Current step index out of bounds for dish steps")
		else:
			print("No steps defined for current dish name")
	
	print("Player 1 progress: dish=", player1_progress.dish_index, ", step=", player1_progress.step_index)
	print("Player 2 progress: dish=", player2_progress.dish_index, ", step=", player2_progress.step_index)
	
	print("E key position: ", e_key_sprite.position if e_key_sprite else "null")
	print("Step transitioning flag: ", is_step_transitioning)
	print("------------------------------\n")
