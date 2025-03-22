extends CharacterBody2D

@onready var main = $".."
@onready var tilemap = $"../TileMapLayer"
@onready var ingredients_container = $"../Ingredients"

var held_ingredient: Ingredient = null
var current_table: Node = null

const SPEED = 100.0
const ARRIVAL_THRESHOLD = 4.0

func _ready():
	# Set initial position
	position = Vector2i(172, 252)
	print("Player ready at position: ", position)

func _physics_process(delta):
	# Get input direction
	var direction = Vector2.ZERO
	direction.x = Input.get_axis("ui_left", "ui_right")
	direction.y = Input.get_axis("ui_up", "ui_down")
	
	# Normalize direction for consistent speed in all directions
	if direction != Vector2.ZERO:
		direction = direction.normalized()
		velocity = direction * SPEED
	else:
		velocity = Vector2.ZERO
	
	# Move the player
	move_and_slide()
	
	# Check for table interaction
	check_table_interaction()
	
	# Handle ingredient pickup/drop
	if Input.is_action_just_pressed("ui_accept"):
		if held_ingredient:
			drop_ingredient()
		else:
			pickup_ingredient()

func check_table_interaction():
	# Get the tile position the player is standing on
	var player_tile = tilemap.local_to_map(position)
	
	# Check for tables in the "tables" group
	for table in get_tree().get_nodes_in_group("tables"):
		var table_tile = tilemap.local_to_map(table.position)
		if table_tile == player_tile:
			current_table = table
			return
	
	current_table = null

func pickup_ingredient():
	# Get the tile position the player is standing on
	var player_tile = tilemap.local_to_map(position)
	
	# Check for ingredients at the player's position
	for ingredient in ingredients_container.get_children():
		var ingredient_tile = tilemap.local_to_map(ingredient.position)
		if ingredient_tile == player_tile:
			held_ingredient = ingredient
			held_ingredient.pickup()
			print("Picked up ingredient at position: ", ingredient.position)
			return

func drop_ingredient():
	if held_ingredient:
		held_ingredient.drop()
		held_ingredient = null
		print("Dropped ingredient")

func serve_ingredient():
	if held_ingredient and current_table:
		current_table.serve(held_ingredient.ingredient_type) 