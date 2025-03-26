extends Area2D

@onready var LettuceTimer = $LettuceTimer
@onready var LettuceBar = $LettuceBar

# Ingredient states
enum State { WHOLE, CHOPPED, PACKAGED,}
var state = State.WHOLE

# Sprites for each state (set these in the editor)
@export var whole_texture: Texture
@export var chopped_texture: Texture
@export var packaged_texture: Texture

@onready var sprite = $Sprite2D  # Reference to sprite
@onready var heldItemTexture = null  # Will be set when picked up
var player = null  # Current player holding or interacting
var initial_player = null  # Player who placed the lettuce
var last_chopping_player = null  # Track who last chopped the lettuce

@export var ingredient_name: String = "LETTUCE"
var is_held: bool = false
var is_chopped: bool = false
var is_packaged: bool = false

# Add variables for chopping progress
var chop_progress = 0
var chop_required = 6  # Base number of interactions needed
var on_chopping_board = false

# Called when the ingredient spawns
func _ready():
	LettuceBar.value = 0
	update_sprite()
	
	# Add this ingredient to the "ingredients" group for easy reference
	add_to_group("ingredients")

func _process(_delta):
	if LettuceTimer.time_left > 0:
		var progress = 100 * (1 - (LettuceTimer.time_left / LettuceTimer.wait_time))
		LettuceBar.value = progress

func get_current_player():
	# If we're on the chopping board, return the player that's currently interacting
	if on_chopping_board:
		# Find any player who can interact with the lettuce
		var players = get_tree().get_nodes_in_group("players")
		for potential_player in players:
			# Check if this player is facing the lettuce and has empty hands
			if potential_player.is_facing_position(global_position) and potential_player.held_ingredient == null:
				print("Found player ", potential_player.player_number, " interacting")
				return potential_player
		return null
	
	# If we have a valid player reference, use it
	if is_instance_valid(player):
		return player
	
	# Otherwise, try to find our player through the scene tree
	var parent = get_parent()
	if parent and parent.name == "Chef":
		var potential_player = parent.get_parent()
		if potential_player is CharacterBody2D:
			player = potential_player
			return player
	return null

func get_held_item_display():
	var current_player = get_current_player()
	if current_player:
		# Get the appropriate held item display based on player number
		var display_name = "heldItemDisplay" if current_player.player_number == 1 else "heldItemDisplay2"
		var main_scene = get_tree().get_root().get_node("Node2D")
		if main_scene:
			var display = main_scene.get_node_or_null("UI/" + display_name + "/heldItemTexture")
			if display:
				print("Found held item display for player ", current_player.player_number)
				return display
			else:
				print("Could not find held item display: UI/" + display_name + "/heldItemTexture")
		else:
			print("Could not find main scene Node2D")
	return null

# Pick up the ingredient
func pick_up():
	is_held = true
	# Get reference to the player that picked up this ingredient
	await ready
	
	# Now we can safely get the player reference and held item display
	player = get_current_player()
	if player:
		# Update chop required based on player's chop speed
		chop_required = max(1, player.CHOP_SPEED)
		print("Lettuce picked up by player ", player.player_number)
		# Get the appropriate held item display
		heldItemTexture = get_held_item_display()
		if heldItemTexture:
			update_sprite()
		else:
			print("Warning: Could not find held item display for player ", player.player_number)

# Drop the ingredient
func drop():
	if is_held:
		is_held = false
		print(ingredient_name, " dropped!")
		if heldItemTexture:
			heldItemTexture.clear_box_sprite()
		# Clear player reference when dropped
		player = null
		heldItemTexture = null

# Chop the ingredient
func chop():
	# First ensure we have a valid player reference
	player = get_current_player()
	if not player:
		print("No valid player reference found!")
		return
		
	if state == State.WHOLE:
		# If not on chopping board yet, place it there
		if not on_chopping_board:
			print("Before detachment: ", is_held, " Parent: ", get_parent())
			
			# Store the initial player who placed the lettuce
			initial_player = player
			print("Player ", initial_player.player_number, " placed lettuce on chopping board")
			
			# Get the player's facing direction
			var facing_direction = player.get_facing_direction()
			
			# Calculate the target position for the chopping board
			var current_tile: Vector2i = player.tileMap.local_to_map(player.global_position)
			var target_tile: Vector2i = current_tile + facing_direction
			var chopping_board_position = player.tileMap.map_to_local(target_tile)

			# Get the current parent and remove from it
			var current_parent = get_parent()
			if current_parent:
				current_parent.remove_child(self)
				# Add to the main scene to keep it in the scene tree
				player.get_parent().add_child(self)

			# Move the lettuce to the chopping board
			global_position = chopping_board_position
			
			is_held = false
			on_chopping_board = true
			
			# Show the progress bar
			LettuceBar.visible = true
			LettuceBar.value = 0
			chop_progress = 0  # Reset progress when placing
			
			# Update player's reference to held ingredient
			if is_instance_valid(player):
				player.held_ingredient = null
			
			print("Lettuce placed on chopping board")
			return
		
		# Verify that player's hands are empty before allowing chopping
		if is_instance_valid(player) and player.held_ingredient != null:
			print("Hands must be empty to chop the lettuce!")
			return
			
		# Update last chopping player and chop required based on current player's speed
		last_chopping_player = player  # This will track who did the most recent chop
		chop_required = max(1, player.CHOP_SPEED)
		print("Player ", player.player_number, " is chopping (Chop Speed: ", player.CHOP_SPEED, ")")
			
		# If already on chopping board, increment chopping progress
		chop_progress += 1
		print("Chopping progress: ", chop_progress, "/", chop_required)
		
		# Update progress bar
		LettuceBar.value = (chop_progress / float(chop_required)) * 100
		
		# Check if chopping is complete
		if chop_progress >= chop_required:
			print("Chopping complete! Last chopping player: ", last_chopping_player.player_number if last_chopping_player else "unknown")
			
			# Chopping is done
			state = State.CHOPPED
			on_chopping_board = false
			LettuceBar.visible = false
			
			# First, update the player reference to the last chopping player (who did the final chop)
			player = last_chopping_player
			
			# Clear any existing held ingredient reference
			if is_instance_valid(initial_player) and initial_player.held_ingredient == self:
				initial_player.held_ingredient = null
			
			# Ensure we're using the last_chopping_player and it's valid
			if is_instance_valid(player):
				print("Attaching to last chopping player: ", player.player_number)
				
				# Set this as the player's held ingredient BEFORE reparenting
				player.held_ingredient = self
				
				# Detach from current parent
				var current_parent = get_parent()
				if current_parent:
					current_parent.remove_child(self)
				
				# Add to the Chef node of the last chopping player
				var chef_node = player.get_node("Chef")
				if chef_node:
					chef_node.add_child(self)
					is_held = true
					position = Vector2(0, 16)
					
					# Update held item display for the correct player
					heldItemTexture = get_held_item_display()
					if heldItemTexture:
						update_sprite()
					else:
						print("Warning: Could not find held item display for player ", player.player_number)
				else:
					print("Error: Could not find Chef node for player ", player.player_number)
			else:
				print("Error: last_chopping_player is not valid!")
			
			print("Chopped ingredient:", ingredient_name)
			print("Lettuce attached to player ", player.player_number if player else "unknown")

func bowl():
	# Ensure we have a valid player reference
	player = get_current_player()
	if not player:
		print("No valid player reference found!")
		return
		
	if state == State.CHOPPED:
		print("Packaging started...")
		state = State.PACKAGED
		LettuceBar.visible = false  # Hide bar when packaging is done
		update_sprite()
		print("Packaged ingredient:", ingredient_name)

func update_sprite():
	match state:
		State.WHOLE:
			sprite.texture = whole_texture
			sprite.modulate = Color(1,1,1)
		State.CHOPPED:
			sprite.texture = chopped_texture
			sprite.modulate = Color(1,0,0)
		State.PACKAGED:
			sprite.texture = packaged_texture
			sprite.modulate = Color(0,0,1)
	if heldItemTexture:
		heldItemTexture.update_box_sprite(sprite.texture, state)
		print("Updated held item display for player ", player.player_number if player else "unknown")
