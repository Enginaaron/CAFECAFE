extends Node2D

enum State { CUP, TEA, TAPIOCA, TAPIOCATEA, LID }
var state = State.CUP

@export var cup_texture = Texture
@export var tea_texture = Texture
@export var tapioca_texture = Texture
@export var tapiocatea_texture = Texture
@export var lid_texture = Texture

@onready var bobaTimer = $bobaTimer
@onready var bobaBar = $bobaBar
@onready var sprite = $Sprite2D  # Reference to sprite
@onready var heldItemTexture = null  # Will be set when picked up
var player = null  # Current player holding or interacting
var initial_player = null  # Player who placed the chicken

var is_held: bool = false

# Add variables for scoop progress
var scoop_progress = 0
var scoop_required = 6  # Base number of interactions needed
var on_tapioca_station = false
var tea_time = 5
var lid_time = 5

# Called when the ingredient spawns
func _ready():
	bobaBar.value = 0
	bobaTimer.timeout.connect(_on_bobaTimer_timeout)  # Connect only once
	update_sprite()

func _process(_delta):
	if bobaTimer.time_left > 0:
		bobaBar.value = 100 * (1 - (bobaTimer.time_left / bobaTimer.wait_time))

func pick_up():
	is_held = true
	# Get reference to the player that picked up this ingredient
	await ready
	
	# Now we can safely get the player reference and held item display
	player = get_current_player()
	if player:
		# Update chop required based on player's chop speed
		scoop_required = max(1, player.TAPIOCA_SCOOP)
		lid_time = player.PACKAGE_SPEED
		tea_time = player.TEA_SPEED
		print("Boba picked up by player ", player.player_number)
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
	if on_tapioca_station:
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
	
func getTea():
	if state == State.CUP or state == State.TAPIOCA:
		bobaBar.value = 0
		bobaBar.visible = true
	else: return
	bobaTimer.wait_time = max(1.0, tea_time)
	bobaTimer.start()
	player.is_busy = true

func _on_bobaTimer_timeout() -> void:
	bobaTimer.stop()
	player = get_current_player()
	if is_instance_valid(player):
		if state == State.CUP:
			state = State.TEA
		elif state == State.TAPIOCA:
			state = State.TAPIOCATEA
		elif state == State.TAPIOCATEA:
			state = State.LID
		bobaBar.visible = false
		update_sprite()
		player.is_busy = false
	
func getTapioca():
	player = get_current_player()
	if not player:
		return
	if state == State.CUP or state == State.TEA:
		if not on_tapioca_station:
			player = player  # Store the player who placed the cup
			
			var facing_direction = player.get_facing_direction()
			var current_tile: Vector2i = player.tileMap.local_to_map(player.global_position)
			var target_tile: Vector2i = current_tile + facing_direction
			var tapioca_position = player.tileMap.map_to_local(target_tile)

			var current_parent = get_parent()
			if current_parent:
				current_parent.remove_child(self)
				player.get_parent().add_child(self)
				player.drop_ingredient()

			global_position = tapioca_position
			is_held = false
			on_tapioca_station = true
			
			bobaBar.value = 0
			bobaBar.visible = true
			scoop_progress = 0
			if is_instance_valid(player):
				player.held_ingredient = null
			return
		if is_instance_valid(player) and player.held_ingredient != null:
			return
		scoop_progress += 1
		bobaBar.value = (scoop_progress / float(scoop_required)) * 100
		
		if scoop_progress >= scoop_required:
			if state == State.CUP:
				state = State.TAPIOCA
			elif state == State.TEA:
				state = State.TAPIOCATEA
			on_tapioca_station = false
			bobaBar.visible = false
			
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
					
					var heldItemTexture = get_held_item_display()
					if heldItemTexture:
						update_sprite()

func lid():
	if state != State.TAPIOCATEA:
		return
	else: 
		bobaBar.value = 0
		bobaBar.visible = true
	bobaTimer.wait_time = max(1.0, 3.0)
	bobaTimer.start()
	player.is_busy = true

func update_sprite():
	match state:
		State.CUP:
			sprite.texture = cup_texture
		State.TEA:
			sprite.texture = tea_texture
		State.TAPIOCA:
			sprite.texture = tapioca_texture
		State.TAPIOCATEA:
			sprite.texture = tapiocatea_texture
		State.LID:
			sprite.texture = lid_texture
	if heldItemTexture:
		heldItemTexture.update_box_sprite(sprite.texture, state)
		print("Updated held item display for player ", player.player_number if player else "unknown")
