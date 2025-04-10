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

	var players = get_tree().get_nodes_in_group("players")
	for potential_player in players:
		if potential_player.is_facing_position(self.global_position) and potential_player.held_ingredient == null:
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
	is_held = true
	# Get reference to the player that picked up this ingredient
	await ready
	
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
	match ingredient_scene:
		"res://scenes/food/Chicken.tscn":
			if ingredient.state == ingredient.State.COOKED:
				sprite.texture = possible_textures[10]  # transform to cooked
				successful = true
				
		"res://scenes/food/Burger.tscn":
			match ingredient.state:
				ingredient.State.BUN:
					if sprite.texture == possible_textures[12]: # if plate, transform to plated bun
						sprite.texture = possible_textures[6]
					else: return
				_: return
			successful = true

		"res://scenes/food/Lettuce.tscn":
			match ingredient.state:
				ingredient.State.CHOPPED:
					if sprite.texture == possible_textures[6]: # if plated bun, transform to plated lettuce bun
						sprite.texture = possible_textures[7]
					elif sprite.texture == possible_textures[8]: # if plated patty bun, transform to plated lettuce patty bun
						sprite.texture = possible_textures[9]
					else: return
				_: return
			successful = true

		"res://scenes/food/Patty.tscn":
			match ingredient.state:
				ingredient.State.COOKED:
					if sprite.texture == possible_textures[6]: # if plated bun, transform to plated patty bun
						sprite.texture = possible_textures[8]
					elif sprite.texture == possible_textures[7]: # if plated lettuce bun, transform to plated lettuce patty bun
						sprite.texture = possible_textures[9]
					else: return
				_: return
			successful = true

	
	if ingredient.player and successful:
		ingredient.player.drop_ingredient()
	else:
		print("Failed to transform: ", "player exists: ", ingredient.player != null, ", successful: ", successful)

func update_sprite():
	if State.EMPTY:
		sprite.texture = possible_textures[12]
