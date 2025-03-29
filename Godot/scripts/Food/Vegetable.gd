extends Node2D

@onready var VeggieTimer = $VeggieTimer
@onready var VeggieBar = $VeggieBar
@onready var sprite = $Sprite2D

# Ingredient states
enum State { WHOLE, CHOPPED, PACKAGED }
var state = State.WHOLE

# Sprites for each state
@export var whole_texture: Texture
@export var chopped_texture: Texture
@export var packaged_texture: Texture

var player = null
var is_held: bool = false
var is_chopped: bool = false
var chop_progress = 0
var chop_required = 6  # Base number of interactions needed
var on_chopping_board = false

func _ready():
	VeggieBar.value = 0
	VeggieTimer.timeout.connect(_on_VeggieTimer_timeout)
	update_sprite()
	add_to_group("ingredients")

func _process(_delta):
	if VeggieTimer.time_left > 0:
		VeggieBar.value = 100 * (1 - (VeggieTimer.time_left / VeggieTimer.wait_time))

func get_current_player() -> Node:
	if on_chopping_board:
		var players = get_tree().get_nodes_in_group("players")
		for potential_player in players:
			if potential_player.is_facing_position(global_position) and potential_player.held_ingredient == null:
				return potential_player
		return null
	
	if is_instance_valid(player):
		return player
	
	var parent = get_parent()
	if parent and parent.name == "Chef":
		var potential_player = parent.get_parent()
		if potential_player is CharacterBody2D:
			player = potential_player
			return player
	return null

func get_held_item_display():
	var current_player = get_current_player()
	if not current_player:
		return null
		
	var display_name = "heldItemDisplay" if current_player.player_number == 1 else "heldItemDisplay2"
	var main_scene = get_node("/root/Node2D")
	if not main_scene:
		return null
		
	return main_scene.get_node_or_null("UI/" + display_name + "/heldItemTexture")

func pick_up():
	is_held = true
	await ready
	
	player = get_current_player()
	if player:
		chop_required = max(1, player.CHOP_SPEED)
		var heldItemTexture = get_held_item_display()
		if heldItemTexture:
			update_sprite()

func drop():
	if is_held:
		is_held = false
		var heldItemTexture = get_held_item_display()
		if heldItemTexture:
			heldItemTexture.clear_box_sprite()
		player = null

func chop():
	player = get_current_player()
	if not player:
		return
		
	if state == State.WHOLE:
		if not on_chopping_board:
			player = player  # Store the player who placed the Veggie
			
			var facing_direction = player.get_facing_direction()
			var current_tile: Vector2i = player.tileMap.local_to_map(player.global_position)
			var target_tile: Vector2i = current_tile + facing_direction
			var chopping_board_position = player.tileMap.map_to_local(target_tile)

			var current_parent = get_parent()
			if current_parent:
				current_parent.remove_child(self)
				player.get_parent().add_child(self)

			global_position = chopping_board_position
			is_held = false
			on_chopping_board = true
			
			VeggieBar.visible = true
			VeggieBar.value = 0
			chop_progress = 0
			
			if is_instance_valid(player):
				player.held_ingredient = null
			return
		
		if is_instance_valid(player) and player.held_ingredient != null:
			return
			
		chop_required = max(1, player.CHOP_SPEED)
		chop_progress += 1
		VeggieBar.value = (chop_progress / float(chop_required)) * 100
		
		if chop_progress >= chop_required:
			state = State.CHOPPED
			is_chopped = true
			on_chopping_board = false
			VeggieBar.visible = false
			
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

func bowl():
	player = get_current_player()
	if not player:
		return
		
	if state == State.CHOPPED:
		VeggieBar.value = 0
		VeggieBar.visible = true
		
		var basetime = player.PACKAGE_SPEED
		VeggieTimer.wait_time = max(1.0, basetime)
		VeggieTimer.start()

func _on_VeggieTimer_timeout():
	player = get_current_player()
	if is_instance_valid(player):
		state = State.PACKAGED
		VeggieBar.visible = false
		update_sprite()
		player.is_busy = false

func update_sprite():
	match state:
		State.WHOLE:
			sprite.texture = whole_texture
		State.CHOPPED:
			sprite.texture = chopped_texture
		State.PACKAGED:
			sprite.texture = packaged_texture
			
	var heldItemTexture = get_held_item_display()
	if heldItemTexture:
		heldItemTexture.update_box_sprite(sprite.texture, state)
