extends Area2D

@onready var packaging_timer = $LettuceTimer
@onready var packaging_bar = $LettuceBar

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

# Called when the ingredient spawns
func _ready():
	packaging_bar.value = 0
	packaging_timer.timeout.connect(_on_packaging_timer_timeout)  # Connect only once
	update_sprite()

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
		heldItemTexture.clear_box_sprite()

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
