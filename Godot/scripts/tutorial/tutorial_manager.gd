extends Node2D

# Preload the key icon scene
var key_icon_scene = preload("res://scenes/tutorial/key_icon.tscn")

# Reference to the player
var player: Node = null

# Icon positions relative to the player (closer to the player now)
var icon_positions = {
	"w": Vector2(0, -50),  # Above the player
	"a": Vector2(-40, 0),  # Left of player
	"s": Vector2(0, 40),   # Below player
	"d": Vector2(40, 0),   # Right of player
	"e": Vector2(0, -15)   # E key position (much closer to appliance)
}

# Icon scales
var key_scales = {
	"w": Vector2(0.6, 0.6),  # Smaller WASD keys
	"a": Vector2(0.6, 0.6),
	"s": Vector2(0.6, 0.6),
	"d": Vector2(0.6, 0.6),
	"e": Vector2(0.3, 0.3)   # E key scale (half the size of WASD keys)
}

# Tutorial stages
enum TutorialStage {
	MOVEMENT,
	LETTUCE_INTERACTION,
	CHOPPING_INTERACTION,
	PACKAGING_INTERACTION,
	TABLE_INTERACTION,
	STORE_INTERACTION,
	TRASH_INTERACTION  # New stage for trash interaction
}

var current_stage = TutorialStage.MOVEMENT
var movement_keys_pressed = {
	"w": false,
	"a": false,
	"s": false,
	"d": false
}

# Keep track of which key icons have been created
var created_icons = {}

# Dictionary to store appliance positions
var appliance_positions = {
	TutorialStage.LETTUCE_INTERACTION: Vector2(0, 0),  # Will be updated during initialization
	TutorialStage.CHOPPING_INTERACTION: Vector2(0, 0),  # Will be updated during initialization
	TutorialStage.PACKAGING_INTERACTION: Vector2(0, 0),  # Will be updated during initialization
	TutorialStage.TABLE_INTERACTION: Vector2(0, 0),  # Will be updated during initialization
	TutorialStage.STORE_INTERACTION: Vector2(0, 0),  # Will be updated during initialization
	TutorialStage.TRASH_INTERACTION: Vector2(0, 0)  # Will be updated during initialization
}

# Flag to prevent multiple transitions
var is_transitioning = false

# Flag to track which cycle we're in
var is_second_cycle = false

func _ready():
	# Display is initially disabled until the player reference is set
	visible = false

# Called by main script to setup the tutorial manager
func initialize(player_node):
	player = player_node
	visible = true
	
	# Use hardcoded positions for all appliances
	appliance_positions = {
		TutorialStage.LETTUCE_INTERACTION: Vector2(48, 16),   # Lettuce station
		TutorialStage.CHOPPING_INTERACTION: Vector2(80, 16),  # Chopping board
		TutorialStage.PACKAGING_INTERACTION: Vector2(112, 16), # Packaging station
		TutorialStage.TABLE_INTERACTION: Vector2(48, 112),      # Default table position
		TutorialStage.STORE_INTERACTION: Vector2(176, -16),      # Store position
		TutorialStage.TRASH_INTERACTION: Vector2(144, 16)       # Trash tile (one tile right of packaging)
	}
	
	# Find actual table position
	find_table_position()
	
	# Print positions for debugging
	print_appliance_positions()
	
	# Start with movement tutorial
	start_movement_tutorial()

func start_movement_tutorial():
	current_stage = TutorialStage.MOVEMENT
	create_key_icons(["w", "a", "s", "d"])

func start_appliance_interaction_tutorial():
	print("Starting appliance tutorial from previous stage: ", current_stage)
	
	# Reset the transitioning flag
	is_transitioning = false
	
	# Clear previous icons first
	clear_all_icons()
	
	# Update stage - but only if it's within valid range
	if current_stage == TutorialStage.MOVEMENT:
		current_stage = TutorialStage.LETTUCE_INTERACTION
	elif current_stage < TutorialStage.STORE_INTERACTION:
		current_stage += 1
	else:
		print("ERROR: Tried to advance beyond store stage")
		return
	
	print("Now starting tutorial stage: ", current_stage)
	
	# Create E key icon for appliance interaction
	create_key_icons(["e"])
	
	if current_stage > TutorialStage.STORE_INTERACTION:
		# Tutorial completed
		print("Moving to completion")
		finish_tutorial()

func finish_tutorial():
	print("Tutorial complete!")
	visible = false
	clear_all_icons()

func clear_all_icons():
	for key in created_icons.keys():
		if created_icons[key] != null:
			created_icons[key].queue_free()
	created_icons.clear()

func create_key_icons(keys):
	# Clear any existing icons
	clear_all_icons()
	
	print("Creating keys: ", keys)
	
	# Create new icons
	for key in keys:
		if icon_positions.has(key):
			var key_icon = key_icon_scene.instantiate()
			key_icon.name = key.to_upper() + "KeyIcon"  # Give it a distinct name
			key_icon.key_name = key
			
			# Add to our node
			add_child(key_icon)
			
			# Set position relative to tutorial manager
			key_icon.position = icon_positions[key]
			
			# Apply scale
			if key_scales.has(key):
				key_icon.scale = key_scales[key]
			
			# Set Z-index to ensure visibility
			key_icon.z_index = 100
			
			# Store reference
			created_icons[key] = key_icon
			
			print("Created ", key, " key at position: ", key_icon.position)

func _process(delta):
	if player and visible:
		if current_stage == TutorialStage.MOVEMENT:
			# Only follow player during movement tutorial
			global_position = player.global_position
			
			# Check movement progress
			check_movement_progress()
		else:
			# Move to appropriate appliance position for the current stage
			global_position = appliance_positions[current_stage]
			
			# Update E key position relative to appliance
			if created_icons.has("e") and created_icons["e"] != null:
				created_icons["e"].position = icon_positions["e"]
			
			# Print what the player is holding every 30 frames (about every half second)
			if Engine.get_frames_drawn() % 30 == 0:
				print_player_held_item()
				
				# Check if player has picked up lettuce and move to chopping stage
				if current_stage == TutorialStage.LETTUCE_INTERACTION:
					var ingredient = player.held_ingredient
					if ingredient and ingredient.ingredient_name == "LETTUCE":
						print("Player picked up lettuce, moving to chopping stage")
						current_stage = TutorialStage.CHOPPING_INTERACTION
						global_position = appliance_positions[current_stage]
				
				# Check if lettuce is chopped and move to appropriate next stage
				if current_stage == TutorialStage.CHOPPING_INTERACTION:
					var ingredient = player.held_ingredient
					if ingredient and ingredient.ingredient_name == "LETTUCE" and ingredient.state == ingredient.State.CHOPPED:
						if is_second_cycle:
							print("Lettuce is chopped, moving to trash stage")
							current_stage = TutorialStage.TRASH_INTERACTION
						else:
							print("Lettuce is chopped, moving to packaging stage")
							current_stage = TutorialStage.PACKAGING_INTERACTION
						global_position = appliance_positions[current_stage]
				
				# Check if lettuce is thrown in trash (second cycle)
				if current_stage == TutorialStage.TRASH_INTERACTION:
					var ingredient = player.held_ingredient
					if not ingredient:  # If player is not holding anything (threw it away)
						print("Lettuce thrown away, tutorial complete!")
						finish_tutorial()
				
				# Check if lettuce is packaged and move to table stage (first cycle)
				if current_stage == TutorialStage.PACKAGING_INTERACTION:
					var ingredient = player.held_ingredient
					if ingredient and ingredient.ingredient_name == "LETTUCE" and ingredient.state == ingredient.State.PACKAGED:
						print("Lettuce is packaged, moving to table stage")
						current_stage = TutorialStage.TABLE_INTERACTION
						global_position = appliance_positions[current_stage]
				
				# Check if order is served and move to store stage (first cycle)
				if current_stage == TutorialStage.TABLE_INTERACTION:
					# Check if there are no customers at any table
					var main_scene = player.get_parent()
					var all_tables_empty = true
					for table in main_scene.table_customers.keys():
						if not main_scene.table_customers[table].is_empty():
							all_tables_empty = false
							break
					
					if all_tables_empty:
						print("Order served, moving to store stage")
						current_stage = TutorialStage.STORE_INTERACTION
						global_position = appliance_positions[current_stage]
				
				# Check if chop upgrade has been purchased (either by money = 0 or chop speed = 5)
				if current_stage == TutorialStage.STORE_INTERACTION:
					var money_label = get_tree().get_root().get_node("Node2D/UI/moneyCounter/MoneyLabel")
					if money_label and money_label.money == 0:
						print("Money is 0, chop upgrade purchased, starting second cycle")
						is_second_cycle = true
						current_stage = TutorialStage.LETTUCE_INTERACTION
						global_position = appliance_positions[current_stage]
					elif player.has_method("get_chop_speed") and player.get_chop_speed() == 5:
						print("Chop speed is 5, chop upgrade purchased, starting second cycle")
						is_second_cycle = true
						current_stage = TutorialStage.LETTUCE_INTERACTION
						global_position = appliance_positions[current_stage]

# Check if player is at a specific stage location
func is_player_at_stage_location(stage):
	if not player or not appliance_positions.has(stage):
		return false
		
	# Get the target position for the specified stage
	var target_position = appliance_positions[stage]
	
	# Calculate distance between player and target
	var distance = player.global_position.distance_to(target_position)
	
	# Consider the player at the location if they're within a certain range
	var proximity_threshold = 35.0  # Adjust this value based on your game's scale
	var at_location = distance < proximity_threshold
	
	return at_location

# Check if all movement keys have been pressed
func check_movement_progress():
	# Don't check if we're already transitioning
	if is_transitioning:
		return
		
	# Check if all movement keys have been pressed
	var all_pressed = true
	var keys_pressed_count = 0
	
	for key in ["w", "a", "s", "d"]:
		if created_icons.has(key) and created_icons[key] != null:
			if created_icons[key].has_been_pressed:
				keys_pressed_count += 1
			else:
				all_pressed = false
	
	# Debug output
	if OS.is_debug_build() and Engine.get_frames_drawn() % 60 == 0:  # Print once per second approximately
		print("Movement keys pressed: ", keys_pressed_count, "/4, All pressed: ", all_pressed)
	
	# If all movement keys pressed, move to next stage
	if all_pressed and current_stage == TutorialStage.MOVEMENT and not is_transitioning:
		print("All movement keys pressed! Moving to next stage...")
		
		# Set flag to prevent multiple transitions
		is_transitioning = true
		
		# Direct call after delay
		get_tree().create_timer(1.0).timeout.connect(func(): 
			start_appliance_interaction_tutorial()
		)

# Remove all the appliance detection functions and keep only the print function
func print_appliance_positions():
	print("\n--- CURRENT APPLIANCE POSITIONS ---")
	print("Lettuce station: ", appliance_positions[TutorialStage.LETTUCE_INTERACTION])
	print("Chopping board: ", appliance_positions[TutorialStage.CHOPPING_INTERACTION])
	print("Trash: ", appliance_positions[TutorialStage.TRASH_INTERACTION])
	print("Packaging station: ", appliance_positions[TutorialStage.PACKAGING_INTERACTION])
	print("Table: ", appliance_positions[TutorialStage.TABLE_INTERACTION])
	print("Store: ", appliance_positions[TutorialStage.STORE_INTERACTION])
	print("-------------------------------\n")

# Only look for table position as that's more reliable to find
func find_table_position():
	var main = get_tree().current_scene
	if main:
		var tables_node = main.get_node("Tables") if main.has_node("Tables") else null
		if tables_node and tables_node.get_child_count() > 0:
			appliance_positions[TutorialStage.TABLE_INTERACTION] = tables_node.get_child(0).global_position
			print("Found table at: ", appliance_positions[TutorialStage.TABLE_INTERACTION])

# Function to print what the player is holding
func print_player_held_item():
	if player:
		# Try to get the held item from the player
		var held_item = "Nothing"
		
		# Check the player's held_ingredient property
		if player.has_method("get_held_ingredient"):
			var ingredient = player.get_held_ingredient()
			if ingredient:
				held_item = ingredient.ingredient_name
				if ingredient.has_method("get_state"):
					held_item += " (" + str(ingredient.get_state()) + ")"
		else:
			# Try to access the property directly
			var ingredient = player.held_ingredient
			if ingredient:
				held_item = ingredient.ingredient_name
				if ingredient.has_method("get_state"):
					held_item += " (" + str(ingredient.get_state()) + ")"
		
# Find store position in the scene
func find_store_position():
	print("\nLooking for store position...")
	
	# Look for store node in the scene
	var store_node = player.get_parent().get_node_or_null("Store")
	if store_node:
		print("Found store node at position: ", store_node.global_position)
		appliance_positions[TutorialStage.STORE_INTERACTION] = store_node.global_position
		return true
	
	print("WARNING: Could not find store node!")
	return false

func on_chop_upgrade_purchased():
	print("Chop upgrade purchased, moving to lettuce stage")
	current_stage = TutorialStage.LETTUCE_INTERACTION
