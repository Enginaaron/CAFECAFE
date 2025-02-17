extends Area2D
class_name Ingredient  # Defines this script as a class

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

@export var ingredient_name: String = "Lettuce"
var is_held: bool = false
var is_chopped: bool = false
var is_packaged: bool = false

# Called when the ingredient spawns
func _ready():
	packaging_bar.value = 0
	packaging_timer.timeout.connect(_on_packaging_timer_timeout)  # Connect only once
	print(ingredient_name, "spawned!")
	update_sprite()  # Set initial sprite
func _process(delta):
	if packaging_timer.time_left > 0:
		var progress = 100 * (1 - (packaging_timer.time_left / packaging_timer.wait_time))
		packaging_bar.value = progress
	

# Pick up the ingredient
func pick_up():
	if not is_held:
		is_held = true
		print(ingredient_name, "picked up!")

# Drop the ingredient
func drop():
	if is_held:
		is_held = false
		print(ingredient_name, "dropped!")
		
@export var chop_progress := 0
@export var chop_needed := 6  # Press "E" 6 times
var chop_tile_position = null  # Store tile position for chopping
var progress_bar = null  # Progress bar reference

@export var is_chopping := false
func start_chopping():
	# Make sure the ingredient stays on the tile
	if chop_tile_position:
		global_position = get_parent().tileMap.map_to_local(chop_tile_position)
	
	# Create a progress bar if it doesn't exist
	if not progress_bar:
		progress_bar = ProgressBar.new()
		progress_bar.min_value = 0
		progress_bar.max_value = chop_needed
		progress_bar.value = chop_progress
		progress_bar.size = Vector2(50, 10)
		progress_bar.global_position = global_position + Vector2(0, -20)
		get_parent().add_child(progress_bar)
# Chop the ingredient
func chop():
	if state == State.WHOLE:
		# Increase chopping progress
		chop_progress += 1
		progress_bar.value = chop_progress
		print("Chop progress:", chop_progress)

		# Check if chopping is complete
		if chop_progress >= chop_needed:
			is_chopped = true
			print("Chopping complete!")
			state == State.CHOPPED
			progress_bar.queue_free()  # Remove progress bar
			progress_bar = null

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
