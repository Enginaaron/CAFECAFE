extends Node2D

signal order_generated

@export var possible_dishes: Array[Texture]

@onready var bubble_sprite = $OrderBubble/BubbleSprite
@onready var dish_sprite   = $OrderBubble/DishSprite
@onready var orderTimer = $OrderTimer
@onready var orderProgressBar = $OrderBubble/OrderProgressBar if has_node("OrderBubble/OrderProgressBar") else null
@onready var moneyLabel = get_node("../../UI/moneyCounter/MoneyLabel")
@onready var dayLabel = get_node("../../UI/dayCounter/dayLabel")
@onready var lifeBar = get_node("../../UI/lifeBar")
@onready var tilemap = get_node("../../TileMapLayer")

const ORDER_TIME = 60

var current_dishes: Array[Texture] = []
var has_order: bool = false
var current_customer: Node = null
var is_boss_table: bool = false

# Get the active player that's interacting with this table
func get_active_player() -> Node:
	# Get all players in the scene
	var players = get_tree().get_nodes_in_group("players")
	
	# Get the table's tile position
	var table_tile = tilemap.local_to_map(global_position)
	
	# Find the player that's facing this table
	for player in players:
		var player_tile = tilemap.local_to_map(player.global_position)
		var facing_tile = player_tile + player.get_facing_direction()
		
		# Check if the player is facing this table
		if facing_tile == table_tile:
			return player
	
	return null

func _ready():
	# Initialize timer
	if orderTimer:
		orderTimer.wait_time = ORDER_TIME
		orderTimer.timeout.connect(_on_orderTimer_timeout)
	
	# Set up progress bar - make it match the packaging bar style
	if not orderProgressBar:
		# Create the progress bar if it doesn't exist
		orderProgressBar = ProgressBar.new()
		orderProgressBar.name = "OrderProgressBar"
		orderProgressBar.min_value = 0
		orderProgressBar.max_value = 100
		orderProgressBar.value = 0
		orderProgressBar.custom_minimum_size = Vector2(24, 10)
		orderProgressBar.position -= Vector2(12,24)
		orderProgressBar.visible = false
		$OrderBubble.add_child(orderProgressBar)
	
	# Hide order bubble initially
	$OrderBubble.visible = false

func _process(_delta):
	# Update progress bar exactly like in the ingredient scripts
	if has_order and orderTimer.time_left > 0:
		var progress = 100 * (1 - (orderTimer.time_left / orderTimer.wait_time))
		orderProgressBar.value = progress

func _on_orderTimer_timeout():
	# Order timed out
	if has_order:
		clear_order()
		# Remove the customer if they exist
		if current_customer:
			current_customer.queue_free()
			current_customer = null
		# Deduct a life
		if lifeBar:
			lifeBar.lose_life()

func generate_random_order():
	if has_order:
		return
		
	# Pick a random dish
	if possible_dishes.size() == 0:
		print("ERROR: No dishes in possible_dishes array")
		return
	
	# Clear previous orders and remove existing dish sprites
	current_dishes.clear()
	
	# Get the wrapper node
	var wrapper = $OrderBubble/Wrapper
	if not wrapper:
		print("ERROR: Wrapper node not found!")
		return
	
	# Clear existing sprites
	for child in wrapper.get_children():
		child.queue_free()
	
	# Generate orders based on whether this is a boss table
	if is_boss_table:
		# Generate 3 random orders for boss
		for i in range(3):
			current_dishes.append(possible_dishes[randi() % possible_dishes.size()])
	else:
		# Generate single order for regular customer
		current_dishes.append(possible_dishes[randi() % possible_dishes.size()])
	
	# Calculate sprite size based on wrapper size and number of orders
	var sprite_size = min(wrapper.size.x / current_dishes.size(), wrapper.size.y)
	
	# Create a new DishSprite for each order
	for i in range(current_dishes.size()):
		var new_dish_sprite = Sprite2D.new()
		new_dish_sprite.name = "DishSprite" + str(i)
		new_dish_sprite.texture = current_dishes[i]
		
		# Scale the sprite to fit within the calculated size
		var scale_factor = 0.8*(sprite_size) / max(new_dish_sprite.texture.get_width(), new_dish_sprite.texture.get_height())
		new_dish_sprite.scale = Vector2(scale_factor, scale_factor)
		
		# Position the sprite horizontally within the wrapper
		var x_pos = (wrapper.size.x / current_dishes.size()) * i + (wrapper.size.x / current_dishes.size() / 2)
		new_dish_sprite.position = Vector2(x_pos, wrapper.size.y / 1.75)
		
		wrapper.add_child(new_dish_sprite)
	
	# Show the bubble
	$OrderBubble.visible = true
	
	# Check if we're in tutorial mode
	var game_data = get_node("/root/GameData")
	if game_data and game_data.tutorial_mode:
		# In tutorial mode, don't show timer or progress bar
		print("Tutorial mode - no timer for order")
		if orderProgressBar:
			orderProgressBar.visible = false
		has_order = true
		order_generated.emit()
		return
	
	# Reset and show progress bar for non-tutorial mode
	if orderProgressBar:
		orderProgressBar.value = 0
		orderProgressBar.visible = true
	
	# Calculate order time based on day
	var currentDay = dayLabel.dayCount
	var dayFactor = pow(0.98, currentDay - 1)  # 2% reduction per day
	var newOrderTime = ORDER_TIME * dayFactor
	
	# Start timer
	if orderTimer:
		orderTimer.wait_time = newOrderTime
		orderTimer.start()
	
	has_order = true
	# Emit the signal when a new order is generated
	order_generated.emit()

func clear_order():
	# Hide the bubble and progress bar
	$OrderBubble.visible = false
	if orderProgressBar:
		orderProgressBar.visible = false
	
	current_dishes.clear()
	has_order = false

func set_customer(customer: Node) -> void:
	current_customer = customer
	# Check if this is a boss customer
	is_boss_table = customer.name.begins_with("BossCustomer")

func serve(ingredient_name):
	# Get the active player
	var player = get_active_player()
	if not player:
		print("No player at table!")
		return
	
	# Check if we have an order and the player is holding something
	if not has_order or player.held_ingredient == null:
		return
	
	# Get the held ingredient's sprite texture
	var held_ingredient_texture = player.held_ingredient.sprite.texture
	
	# Check against all dish sprites in the Wrapper
	var match_found = false
	var wrapper = $OrderBubble/Wrapper
	if wrapper:
		for child in wrapper.get_children():
			if child.name.begins_with("DishSprite"):
				if held_ingredient_texture == child.texture:
					match_found = true
					# Remove the matched sprite
					child.queue_free()
					# Remove the corresponding texture from current_dishes
					current_dishes.erase(child.texture)
					# Clear the player's held item
					player.drop_ingredient()
					break
	
	if match_found:
		print("Yes - Ingredient matches one of the orders!")
		# Check if all orders are completed
		if current_dishes.is_empty():
			print("All orders completed!")
			dayLabel.order_done()
			# Update money - more for boss orders
			if moneyLabel:
				var reward = 10 if is_boss_table else 5
				moneyLabel.update_money(reward)
			# Remove customer
			if current_customer:
				# Get the main scene to properly remove the customer
				var main_scene = get_node("/root/Node2D")
				if main_scene:
					main_scene.remove_customer_from_table(current_customer, self)
				current_customer.queue_free()
				current_customer = null
			# Clear the order
			clear_order()
	else:
		print("No - Ingredient does not match any orders")
