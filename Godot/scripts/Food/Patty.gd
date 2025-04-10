extends Node2D

enum State { RAW, COOKED, PLATE}
var state = State.RAW

@export var raw_texture = Texture
@export var cooked_texture = Texture

@onready var pattyTimer = $pattyTimer
@onready var pattyBar = $pattyBar
@onready var sprite = $Sprite2D
@onready var heldItemTexture = null  # Will be set when picked up
var player = null
var is_held = null
var on_fryer = false

func _ready():
	pattyBar.value = 0
	pattyTimer.timeout.connect(_on_pattyTimer_timeout)  # Connect only once
	update_sprite()

func _process(_delta):
	if pattyTimer.time_left > 0:
		pattyBar.value = 100 * (1 - (pattyTimer.time_left / pattyTimer.wait_time))

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

func grill():
	var heldItemTexture = get_held_item_display()
	if state == State.RAW:
		if not on_fryer:
			player = get_current_player()
			
			visible = true
			var facing_direction = player.get_facing_direction()
			var current_tile: Vector2i = player.tileMap.local_to_map(player.global_position)
			var target_tile: Vector2i = current_tile + facing_direction
			var fryer_position = player.tileMap.map_to_local(target_tile)

			var current_parent = get_parent()
			if current_parent:
				current_parent.remove_child(self)
				player.get_parent().add_child(self)
				player.drop_ingredient()

			global_position = fryer_position - Vector2(0,12)
			is_held = false
			on_fryer = true
			pattyBar.value = 0
			pattyBar.visible = true
			pattyTimer.wait_time = max(1.0, 2.0)
			pattyTimer.start()
	elif state == State.COOKED:
		player = get_current_player()
		if is_instance_valid(player):
			player.held_ingredient = self
			
			var current_parent = get_parent()
			if current_parent:
				current_parent.remove_child(self)
			
			var chef_node = player.get_node("Chef")
			if chef_node:
				chef_node.add_child(self)
				visible=false
				is_held = true
				position = Vector2(0, 16)
				heldItemTexture.update_box_sprite(sprite.texture, state)
				
				heldItemTexture = get_held_item_display()
				if heldItemTexture:
					update_sprite()

func _on_pattyTimer_timeout() -> void:
	pattyTimer.stop()
	pattyBar.visible = false
	state = State.COOKED
	pattyBar.visible = false
	update_sprite()

func update_sprite():
	match state:
		State.RAW:
			sprite.texture = raw_texture
		State.COOKED:
			sprite.texture = cooked_texture
