extends Node

enum State { BUN, PATTY, LETTUCE, PATTYLETTUCE }
var state = State.BUN

@export var bun_texture = Texture
@export var patty_texture = Texture
@export var lettuce_texture = Texture
@export var pattylettuce_texture = Texture
@export var possible_textures: Array[Texture]

@onready var sprite = $Sprite2D
@onready var heldItemTexture = null  # Will be set when picked up

var player = null
var is_held = null

func _ready():
	update_sprite()

func get_current_player():
	# If we're being held, return the player that's holding us
	if is_held and is_instance_valid(player):
		return player
	
	# Try to find a player that's facing us and has empty hands
	var players = get_tree().get_nodes_in_group("players")
	for potential_player in players:
		if potential_player.is_facing_position(self.global_position) and potential_player.held_ingredient == null:
			print(potential_player.held_ingredient)
			print("Found player ", potential_player.player_number, " interacting")
			return potential_player
	
	# If we're in a chef node, try to find the player through the scene tree
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

func burgerTransform(ingredient: Node):
	var successful = false
	var ingredient_scene = ingredient.scene_file_path
	
	# Update the burger's sprite based on the ingredient scene and state
	match ingredient_scene:
		"res://scenes/food/Lettuce.tscn":
			match ingredient.state:
				ingredient.State.CHOPPED:
					if sprite.texture == possible_textures[3]: 
						sprite.texture = possible_textures[0]
						state = State.LETTUCE
						successful = true
					elif sprite.texture == possible_textures[1]:
						sprite.texture = possible_textures[2]
						state = State.PATTYLETTUCE
						successful = true
				_: return
			successful = true

		"res://scenes/food/Patty.tscn":
			match ingredient.state:
				ingredient.State.COOKED:
					if sprite.texture == possible_textures[3]:
						sprite.texture = possible_textures[1]
						state = State.PATTY
						successful = true
					elif sprite.texture == possible_textures[0]:
						sprite.texture = possible_textures[2]
						state = State.PATTYLETTUCE
						successful = true
				_: return
			successful = true

		"res://scenes/food/Plate.tscn":
			match ingredient.state:
				ingredient.State.EMPTY:
					if sprite.texture == possible_textures[1]:
						sprite.texture = possible_textures[6]
						successful = true
					elif sprite.texture == possible_textures[2]:
						sprite.texture = possible_textures[7]
						successful = true
				_: return
	
	if successful:
		# Update the held item display if we have one
		if heldItemTexture:
			update_sprite()
		
		# Try to drop the ingredient from the player
		if ingredient.player:
			ingredient.player.drop_ingredient()
		else:
			# If no direct player reference, search for the player holding the ingredient
			var players = get_tree().get_nodes_in_group("players")
			for player in players:
				if player.held_ingredient == ingredient:
					player.drop_ingredient()
					break

func update_sprite():
	match state:
		State.BUN:
			sprite.texture = bun_texture
		State.PATTY:
			sprite.texture = patty_texture
		State.LETTUCE:
			sprite.texture = lettuce_texture
		State.PATTYLETTUCE:
			sprite.texture = pattylettuce_texture
	var heldItemTexture = get_held_item_display()
	if heldItemTexture:
		heldItemTexture.update_box_sprite(sprite.texture, state)
