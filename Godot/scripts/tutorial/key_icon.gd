extends Sprite2D

@export var key_name: String = "w"  # The key that this icon represents
var has_been_pressed: bool = false
var action_name: String = ""
var just_created: bool = true
var detection_delay: float = 0.5  # Short delay before enabling key detection
var test_pressed_timer: float = 0.0

func _ready():
	print("Initializing key icon: ", key_name)
	
	# Set the texture for this key icon
	var texture_path = "res://textures/icons8-" + key_name + "-key-50.png"
	var loaded_texture = load(texture_path)
	if loaded_texture:
		texture = loaded_texture
		print("Texture loaded for ", key_name)
	else:
		print("ERROR: Failed to load texture for key ", key_name)
	
	# Map key name to the corresponding action
	match key_name.to_lower():
		"w":
			action_name = "up"
		"a":
			action_name = "left"
		"s":
			action_name = "down"
		"d":
			action_name = "right"
		"e":
			action_name = "interact"
	
	# Make sure the icon is visible initially
	visible = true
	modulate = Color(1, 1, 1, 1)  # Fully opaque
	
	print("Key icon ready: ", key_name, " with action: ", action_name)
	
	# Test show/hide for debugging
	test_pressed_timer = 1.0

func _process(delta):
	# Short delay to prevent immediate detection
	if just_created:
		detection_delay -= delta
		if detection_delay <= 0:
			just_created = false
			print("Key detection enabled for ", key_name)
	
	# Ensure the icon is visible if it hasn't been pressed yet
	# For WASD keys, hide after press, but keep E keys visible until explicitly hidden
	if not has_been_pressed or key_name == "e":
		visible = true
		modulate.a = 1.0
	
	# Only detect keypresses for WASD keys - E key is handled by tutorial manager
	if not has_been_pressed and action_name != "" and not just_created and key_name != "e":
		# Check using both input action and direct key code
		var is_key_pressed = Input.is_action_just_pressed(action_name) or Input.is_key_pressed(get_key_scancode(key_name))
		
		if is_key_pressed:
			print("Key pressed: ", key_name)
			has_been_pressed = true
			
			# Only hide WASD keys immediately after press, E key visibility is managed by tutorial manager
			# Don't hide immediately so the user can see the feedback
			await get_tree().create_timer(0.2).timeout
			visible = false
			
	# Debug display every 2 seconds
	test_pressed_timer -= delta
	if test_pressed_timer <= 0:
		test_pressed_timer = 2.0

# Helper function to convert key name to scancode
func get_key_scancode(key: String) -> int:
	match key.to_lower():
		"w":
			return KEY_W
		"a":
			return KEY_A
		"s":
			return KEY_S
		"d":
			return KEY_D
		"e":
			return KEY_E
		_:
			return 0  # Default return for unknown keys 
