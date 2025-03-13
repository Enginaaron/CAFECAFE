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
@onready var heldItemTexture = get_node("/root/Node2D/UI/heldItemDisplay/heldItemTexture")
@onready var player = get_node("/root/Node2D/player")

@export var ingredient_name: String = "LETTUCE"
var is_held: bool = false
var is_chopped: bool = false
var is_packaged: bool = false

# Add variables for chopping progress
var chop_progress = 0
var chop_required = 6  # Number of interactions needed
var on_chopping_board = false

# Called when the ingredient spawns
func _ready():
	LettuceBar.value = 0
	LettuceTimer.timeout.connect(_on_LettuceTimer_timeout)  # Connect only once
	update_sprite()
	
	# Add this ingredient to the "ingredients" group for easy reference
	add_to_group("ingredients")

func _process(delta):
	if LettuceTimer.time_left > 0:
		var progress = 100 * (1 - (LettuceTimer.time_left / LettuceTimer.wait_time))
		LettuceBar.value = progress
	

# Pick up the ingredient
func pick_up():
	if not is_held:
		is_held = true
		print(ingredient_name, " picked up!")

# Drop the ingredient
func drop():
	if is_held:
		is_held = false
		print(ingredient_name, " dropped!")
		heldItemTexture.clear_box_sprite()

# Chop the ingredient
func chop():
	if state == State.WHOLE:
		# If not on chopping board yet, place it there
		if not on_chopping_board:
			print("Before detachment: ", is_held, " Parent: ", get_parent())
		
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
			
			# Update player's reference to held ingredient
			player.held_ingredient = null
			
			print("Lettuce placed on chopping board")
			return
		
		# If already on chopping board, increment chopping progress
		chop_progress += 1
		print("Chopping progress: ", chop_progress, "/", chop_required)
		
		# Update progress bar
		LettuceBar.value = (chop_progress / float(chop_required)) * 100
		
		# Check if chopping is complete
		if chop_progress >= chop_required:
			# Chopping is done
			state = State.CHOPPED
			on_chopping_board = false
			LettuceBar.visible = false
			
			# Return to the chef/player
			var parent = get_parent()
			if parent:
				parent.remove_child(self)
			
			player.held_ingredient = self
			player.get_node("Chef").add_child(self)
			is_held = true
			position = Vector2(0, 16)  # Set LOCAL position relative to Chef, 16 pixels lower
			
			update_sprite()
			print("Chopped ingredient:", ingredient_name)
			print("Lettuce returned to player")

func package():
	if state == State.CHOPPED:
		print("Packaging started...")
		LettuceBar.value = 0  # Reset progress
		LettuceBar.visible = true  # Show progress bar
		LettuceTimer.start()  # Start the timer
		LettuceTimer.timeout.connect(_on_LettuceTimer_timeout)  # Connect the signal
func _on_LettuceTimer_timeout():
	state = State.PACKAGED
	LettuceBar.visible = false  # Hide bar when packaging is done
	update_sprite()
	print("Packaged ingredient:", ingredient_name)
	player.is_busy = false  # Re-enable player movement

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
	heldItemTexture.update_box_sprite(sprite.texture, state)
