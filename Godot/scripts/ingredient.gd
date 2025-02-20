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

# Called when the ingredient spawns
func _ready():
	packaging_bar.value = 0
	packaging_timer.timeout.connect(_on_packaging_timer_timeout)  # Connect only once
	print(ingredient_name, " spawned!")
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
	if state == State.WHOLE:
		state = State.CHOPPED
		update_sprite()
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
