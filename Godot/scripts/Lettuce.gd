extends Area2D

@onready var packaging_timer = $PackagingTimer
@onready var packaging_bar = $PackagingBar

# Ingredient states
enum State { WHOLE, CHOPPED, PACKAGED }
var state = State.WHOLE

# Sprites for each state (set these in the editor)
@export var whole_texture: Texture
@export var chopped_texture: Texture
@export var packaged_texture: Texture

@onready var sprite = $Sprite2D  # Reference to sprite

@export var ingredient_name: String = "LETTUCE"
var is_held: bool = false
var is_chopped: bool = false
var is_packaged: bool = false

var chop_progress = 0
var chop_req = 6  # Number of presses needed

# Called when the ingredient spawns
func _ready():
	packaging_bar.value = 0
	packaging_timer.timeout.connect(_on_packaging_timer_timeout)  # Connect only once
<<<<<<< Updated upstream:Godot/scripts/ingredient.gd
	print(ingredient_name, " spawned!")
=======
>>>>>>> Stashed changes:Godot/scripts/Lettuce.gd
	update_sprite()  # Set initial sprite
func _process(delta):
	if packaging_timer.time_left > 0:
		var progress = 100 * (1 - (packaging_timer.time_left / packaging_timer.wait_time))
		packaging_bar.value = progress
	

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

# Chop the ingredient
func chop():
	if is_chopped == true:
		return
	if state == State.WHOLE:
		var player = get_parent()  # Get the player (assumes the ingredient is a child of the player)
		if player.has_method("get_facing_direction"):  # Ensure player has the method
			var facing_tile = player.tileMap.map_to_local(
				player.get_facing_direction() + player.tileMap.local_to_map(player.global_position)
			)
			global_position = facing_tile  # Move ingredient to the chopping board position
			reparent(player.tileMap)  # Attach to TileMap instead of player
			packaging_bar.visible = true  # Show progress bar

	# Increment chop progress
	chop_progress += 1
	packaging_bar.value = (chop_progress / chop_req) * 100  # Update progress bar

	print("Chop progress:", chop_progress, "/", chop_req)

	if chop_progress >= chop_req:
		# Finish chopping
		state = State.CHOPPED
		is_chopped = true
		packaging_bar.visible = false  # Hide progress bar
		update_sprite()
		print("Chopping complete!")
		print("Chopped ingredient:", ingredient_name)

func package():
	if state == State.CHOPPED:
		print("Packaging started...")
		packaging_bar.value = 0  # Reset progress
		packaging_bar.visible = true  # Show progress bar
		packaging_timer.start()  # Start the timer
		packaging_timer.timeout.connect(_on_packaging_timer_timeout)  # Connect the signal
func _on_packaging_timer_timeout():
	state = State.PACKAGED
	packaging_bar.visible = false  # Hide bar when packaging is done
	update_sprite()
	print("Packaged ingredient:", ingredient_name)
	var player = get_parent()  # Assuming the player is a direct parent
	player.is_busy = false  # Re-enable player movement
	
func update_sprite():
	match state:
		State.WHOLE:
			sprite.texture = whole_texture
		State.CHOPPED:
			sprite.texture = chopped_texture
		State.PACKAGED:
			sprite.texture = packaged_texture
