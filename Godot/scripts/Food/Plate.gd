extends Node

enum State { EMPTY }
var state = State.EMPTY

@export var possible_textures: Array[Texture]
@onready var sprite = $Sprite2D
@onready var heldItemTexture = null  # Will be set when picked up

var player = null
var is_held = null

func _ready():
	$Sprite2D.texture = possible_textures[12]

func get_current_player():
	# If we're being held, return the player that's holding us
	if is_held and is_instance_valid(player):
		return player
	
	# First check if we're in a player's chef node
	var parent = get_parent()
	if parent and parent.name == "Chef":
		var potential_player = parent.get_parent()
		if potential_player is CharacterBody2D and potential_player.is_in_group("players"):
			player = potential_player
			return player
	
	# If not in a player's node, look for a player facing us with empty hands
	var players = get_tree().get_nodes_in_group("players")
	for potential_player in players:
		if potential_player.held_ingredient == null and potential_player.is_facing_position(self.global_position):
			player = potential_player
			return player
	
	return null

func get_held_item_display():
	var current_player = get_current_player()
	if current_player:
		# Get the appropriate held item display based on player number
		var display_name = "heldItemDisplay" if current_player.player_number == 1 else "heldItemDisplay2"
		var main_scene = get_node("/root/Node2D")
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

func pick_up():
	print("picked up")
	is_held = true
	# Get reference to the player that picked up this ingredient
	await ready
	
	# Play pickup sound
	AudioManager.play_sound("pickup")
	
	# Now we can safely get the player reference and held item display
	player = get_current_player()
	if player:
		print("plate picked up by player ", player.player_number)
		# Get the appropriate held item display
		heldItemTexture = get_held_item_display()
		if heldItemTexture:
			update_sprite()
		else:
			print("Warning: Could not find held item display for player ", player.player_number)

func drop():
	if is_held:
		is_held = false
		# Store the player number before clearing the reference
		var player_number = player.player_number if player else 1
		player = null
		
		# Play drop sound
		AudioManager.play_sound("drop")
		
		# Get the appropriate held item display based on stored player number
		var display_name = "heldItemDisplay" if player_number == 1 else "heldItemDisplay2"
		var main_scene = get_node("/root/Node2D")
		if main_scene:
			var display = main_scene.get_node_or_null("UI/" + display_name + "/heldItemTexture")
			if display:
				display.clear_box_sprite()

func transform(ingredient: Node):
	var successful = false
	var ingredient_scene = ingredient.scene_file_path
	
	# Update the plate's sprite based on the ingredient scene and state
	print("Transforming with ingredient: ", ingredient_scene)
	match ingredient_scene:
		"res://scenes/food/Chicken.tscn":
			if ingredient.state == ingredient.State.COOKED:
				sprite.texture = possible_textures[10]  # transform to cooked
				successful = true
				
		"res://scenes/food/Burger.tscn":
			print("Burger state: ", ingredient.state)
			match ingredient.state:
				ingredient.State.PATTYLETTUCE:
					if sprite.texture.resource_path == possible_textures[12].resource_path: # if empty plate, transform to plated pattylettuce
						sprite.texture = possible_textures[9]
						successful = true
				ingredient.State.PATTY:
					if sprite.texture.resource_path == possible_textures[12].resource_path: # if empty plate, transform to plated patty
						sprite.texture = possible_textures[8]
						successful = true
				_: return
			successful = true

		"res://scenes/food/Lettuce.tscn":
			match ingredient.state:
				ingredient.State.CHOPPED:
					if sprite.texture.resource_path == possible_textures[6].resource_path: # if plated bun, transform to plated lettuce bun
						sprite.texture = possible_textures[7]
					elif sprite.texture.resource_path == possible_textures[8].resource_path: # if plated patty bun, transform to plated lettuce patty bun
						sprite.texture = possible_textures[9]
					else: return
				_: return
			successful = true

		"res://scenes/food/Patty.tscn":
			match ingredient.state:
				ingredient.State.COOKED:
					if sprite.texture.resource_path == possible_textures[6].resource_path: # if plated bun, transform to plated patty bun
						sprite.texture = possible_textures[8]
					elif sprite.texture.resource_path == possible_textures[7].resource_path: # if plated lettuce bun, transform to plated lettuce patty bun
						sprite.texture = possible_textures[9]
					else: return
				_: return
			successful = true

	
	if successful:
		# Play transform sound
		AudioManager.play_sound("transform")
		
		if ingredient.player:
			ingredient.player.drop_ingredient()
		else:
			# If the ingredient doesn't have a player reference, try to get it from the scene
			var players = get_tree().get_nodes_in_group("players")
			for player in players:
				if player.held_ingredient == ingredient:
					player.drop_ingredient()
					break
	else:
		# Play error sound
		AudioManager.play_sound("error")
		print("Failed to transform: ", "player exists: ", ingredient.player != null, ", successful: ", successful)

func update_sprite():
	if State.EMPTY:
		sprite.texture = possible_textures[12]
