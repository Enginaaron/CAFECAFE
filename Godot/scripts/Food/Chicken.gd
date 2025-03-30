extends Node2D

enum State { RAW, FRIED }
var state = State.RAW

@export var raw_texture = Texture
@export var fried_texture = Texture

@onready var chickenTimer = $chickenTimer
@onready var chickenBar = $chickenBar
@onready var sprite = $Sprite2D
@onready var heldItemTexture = null  # Will be set when picked up
var player = null
var is_held = null
var on_fryer = false

func _ready():
	chickenBar.value = 0
	chickenTimer.timeout.connect(_on_chickenTimer_timeout)  # Connect only once
	update_sprite()

func _process(_delta):
	if chickenTimer.time_left > 0:
		chickenBar.value = 100 * (1 - (chickenTimer.time_left / chickenTimer.wait_time))

func pick_up():
	is_held = true
	# Get reference to the player that picked up this ingredient
	await ready
	
	# Now we can safely get the player reference and held item display
	player = get_current_player()
	if player:
		print("Chicken picked up by player ", player.player_number)
		# Get the appropriate held item display
		heldItemTexture = get_held_item_display()
		if heldItemTexture:
			update_sprite()
		else:
			print("Warning: Could not find held item display for player ", player.player_number)

func drop():
	if is_held:
		is_held = false
		var heldItemTexture = get_held_item_display()
		if heldItemTexture:
			heldItemTexture.clear_box_sprite()
		player = null

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
	# If we're on the tapioca station, return the player that's currently interacting
	if on_fryer:
		# Find any player who can interact with the cup
		var players = get_tree().get_nodes_in_group("players")
		for potential_player in players:
			# Check if this player is facing the cup and has empty hands
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

func fry():
	if state == State.RAW:
		if not on_fryer:
			player = player  # Store the player who placed the cup
			
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
			chickenBar.value = 0
			chickenBar.visible = true
			chickenTimer.wait_time = max(1.0, 15.0)
			chickenTimer.start()
	elif state == State.FRIED:
		player = get_current_player()
		if is_instance_valid(player):
			player.held_ingredient = self
			
			var current_parent = get_parent()
			if current_parent:
				current_parent.remove_child(self)
			
			var chef_node = player.get_node("Chef")
			if chef_node:
				chef_node.add_child(self)
				is_held = true
				position = Vector2(0, 16)
				heldItemTexture.update_box_sprite(sprite.texture, state)
				
				var heldItemTexture = get_held_item_display()
				if heldItemTexture:
					update_sprite()

func _on_chickenTimer_timeout() -> void:
	chickenTimer.stop()
	chickenBar.visible = false
	player = get_current_player()
	state = State.FRIED
	chickenBar.visible = false
	update_sprite()
	
func update_sprite():
	match state:
		State.RAW:
			sprite.texture = raw_texture
		State.FRIED:
			sprite.texture = fried_texture
