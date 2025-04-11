extends Sprite2D

@export var key_name: String = "w"  # The key that this icon represents
@export var is_player2: bool = false  # Whether this icon belongs to player 2
var has_been_pressed: bool = false
var action_name: String = ""
var just_created: bool = true
var detection_delay: float = 0.5  # Short delay before enabling key detection
var test_pressed_timer: float = 0.0

func _ready():
	print("Initializing key icon: ", key_name, " for player ", 2 if is_player2 else 1)
	
	# Set the texture for this key icon
	var texture_path
	if key_name in ["up", "down", "left", "right"]:
		texture_path = "res://textures/UISprites/" + key_name + "-arrow-key-64.png"
	else:
		texture_path = "res://textures/UISprites/icons8-" + key_name + "-key-50.png"
		
	var loaded_texture = load(texture_path)
	if loaded_texture:
		texture = loaded_texture
		print("Texture loaded for ", key_name)
	else:
		print("ERROR: Failed to load texture for key ", key_name, " at path: ", texture_path)
	
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
		"up":
			action_name = "up"
		"left":
			action_name = "left"
		"down":
			action_name = "down"
		"right":
			action_name = "right"
	
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
	
	# For E key, let the tutorial manager handle visibility and position
	if key_name == "e":
		return
	
	# For movement keys, handle visibility and key detection
	if not has_been_pressed:
		visible = true
		modulate.a = 1.0
		
		if action_name != "" and not just_created:
			# Check using both input action and direct key code, but only for the correct player's keys
			var is_key_pressed = false
			if is_player2:
				# Player 2 uses arrow keys
				is_key_pressed = Input.is_key_pressed(get_key_scancode(key_name))
			else:
				# Player 1 uses WASD
				is_key_pressed = Input.is_action_just_pressed(action_name) or Input.is_key_pressed(get_key_scancode(key_name))
			
			if is_key_pressed:
				print("Key pressed: ", key_name, " by player ", 2 if is_player2 else 1)
				has_been_pressed = true
				
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
		"up":
			return KEY_UP
		"left":
			return KEY_LEFT
		"down":
			return KEY_DOWN
		"right":
			return KEY_RIGHT
		_:
			return 0  # Default return for unknown keys 
