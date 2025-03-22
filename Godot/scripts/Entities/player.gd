extends CharacterBody2D

@onready var tileMap = $"../TileMapLayer"
@onready var sprite2D = $Chef
@onready var UI = $"../UI"
@onready var table = $"../Tables"
@onready var main = $".."
@onready var store = $"../Store"
@export var storeInterface: CanvasLayer

var held_ingredient = null
var is_busy = false
var last_direction = Vector2i(0, 0)

# default player stats
var MOVE_SPEED = 200
var CHOP_SPEED = 10
var PACKAGE_SPEED = 5

func _ready():
	# walls (layer 1) and customers (layer 2)
	collision_mask = 3
	self.position = Vector2(16,16)
	
func _physics_process(delta):
	if is_busy or storeInterface.visible:
		velocity = Vector2.ZERO
		return
	
	# input direction
	var direction = Vector2.ZERO
	if Input.is_action_pressed("up"):
		direction.y -= 1
	if Input.is_action_pressed("down"):
		direction.y += 1
	if Input.is_action_pressed("left"):
		direction.x -= 1
	if Input.is_action_pressed("right"):
		direction.x += 1
	
	# normalizing direction for consistent speed
	if direction != Vector2.ZERO:
		direction = direction.normalized()
		last_direction = Vector2i(direction)
		velocity = direction * MOVE_SPEED
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()

func get_facing_direction() -> Vector2i:
	return last_direction

func attempt_interaction():
	if is_busy:
		return

	# get tile player is facing
	var facing_tile: Vector2i = tileMap.local_to_map(global_position) + get_facing_direction()
	
	# check for table interaction
	var table = main.get_table_at_tile(facing_tile)
	if table:
		table.serve("lettuce")
		return

	# check for ingredients on the facing tile
	for node in get_tree().get_nodes_in_group("ingredients"):
		var ingredient_tile = tileMap.local_to_map(node.global_position)
		if ingredient_tile == facing_tile and node.on_chopping_board and node.state == node.State.WHOLE:
			# interact with ingredient on chopping board
			node.chop()
			return

	# check for other interactions
	var tile_data = tileMap.get_cell_tile_data(facing_tile)
	if not tile_data:
		return

	if tile_data.get_custom_data("lettuce"):
		pick_up_ingredient("res://scenes/Lettuce.tscn")
	elif tile_data.get_custom_data("chopping board") and held_ingredient and not held_ingredient.is_chopped:
		held_ingredient.chop()
	elif tile_data.get_custom_data("package") and held_ingredient and held_ingredient.state == held_ingredient.State.CHOPPED:
		is_busy = true
		held_ingredient.package()
	elif tile_data.get_custom_data("store"):
		store.toggle_store()

func pick_up_ingredient(scene_path: String):
	if held_ingredient == null:
		held_ingredient = load(scene_path).instantiate()
		held_ingredient.pick_up()
		$Chef.add_child(held_ingredient)

# interact is [E]
func _input(event):
	if event.is_action_pressed("interact"):
		attempt_interaction()

func apply_bonus(stat_bonus) -> void:
	for stat in stat_bonus.keys():
		if stat == "moveSpeed":
			MOVE_SPEED += stat_bonus["moveSpeed"]
			print("item purchased! movement increased to "+str(MOVE_SPEED))
		elif stat == "packageSpeed":
			PACKAGE_SPEED += stat_bonus["packageSpeed"]
			print("item purchased! packaging speed increased to "+str(PACKAGE_SPEED))
		elif stat == "chopSpeed":
			CHOP_SPEED += stat_bonus["chopSpeed"]
			print("item purchased! chopping speed increased to "+str(CHOP_SPEED))
