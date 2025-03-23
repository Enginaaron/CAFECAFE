extends Node2D
# or extends Area2D if you're using collision

signal order_generated

@export var possible_dishes: Array[Texture]

@onready var bubble_sprite = $OrderBubble/BubbleSprite
@onready var dish_sprite   = $OrderBubble/DishSprite
@onready var orderTimer = $OrderTimer
@onready var orderProgressBar = $OrderBubble/OrderProgressBar if has_node("OrderBubble/OrderProgressBar") else null
@onready var moneyLabel = get_node("../../UI/moneyCounter/MoneyLabel")
@onready var dayLabel = get_node("../../UI/dayCounter/dayLabel")
@onready var lifeBar = get_node("../../UI/lifeBar")
@onready var main = $".."

const ORDER_TIME = 30.0  # Set order time to 30 seconds

var current_dish: Texture = null
var has_order: bool = false
var current_customer: Node = null

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
		orderProgressBar.custom_minimum_size = Vector2(50, 10)
		orderProgressBar.position -= Vector2(24, 24)
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
		print("Order timed out!")
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
		
	#print("Generating random order...")
	current_dish = possible_dishes[randi() % possible_dishes.size()]
	dish_sprite.texture = current_dish
	
	# Show the bubble
	$OrderBubble.visible = true
	
	# Reset and show progress bar
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
		#print("day ", currentDay, ": order time is ", newOrderTime, " secs")
	
	has_order = true
	print("order created")
	# Emit the signal when a new order is generated
	order_generated.emit()

func clear_order():
	# Hide the bubble and progress bar
	$OrderBubble.visible = false
	if orderProgressBar:
		orderProgressBar.visible = false
	
	current_dish = null
	has_order = false

func set_customer(customer: Node) -> void:
	current_customer = customer

func get_serving_player() -> Node:
	# Get all players in the scene
	var players = get_tree().get_nodes_in_group("players")
	
	# Find the closest player that is facing this table
	var closest_player = null
	var min_distance = INF
	
	for player in players:
		# Check if the player is facing this table
		var facing_tile = player.tileMap.local_to_map(player.global_position) + player.get_facing_direction()
		var table_tile = player.tileMap.local_to_map(global_position)
		
		if facing_tile == table_tile:
			var distance = player.global_position.distance_to(global_position)
			if distance < min_distance:
				min_distance = distance
				closest_player = player
	
	return closest_player

func serve(ingredient_name):
	var dish_texture = null
	
	# Get the player that's trying to serve
	var serving_player = get_serving_player()
	if not serving_player:
		print("No player found trying to serve!")
		return
	
	# Map ingredient names to their corresponding dish textures
	match ingredient_name.to_lower():
		"lettuce":
			dish_texture = possible_dishes[0]
		_:
			return
	
	# Check if we have an order, the player is holding something, and it's packaged
	if not has_order or serving_player.held_ingredient == null:
		return
		
	# Ensure the ingredient is in its packaged state
	if serving_player.held_ingredient.state != serving_player.held_ingredient.State.PACKAGED:
		print("Cannot serve unpackaged ingredient!")
		return
	
	# Compare the served dish with the ordered dish
	if dish_texture == current_dish:
		# Handle successful serving
		serving_player.held_ingredient.queue_free()  # Remove from scene
		serving_player.held_ingredient = null  # Clear reference
		moneyLabel.update_money(5)
		dayLabel.order_done()
		clear_order()
		# Remove the customer after successful serve
		if current_customer:
			current_customer.queue_free()
			current_customer = null
	else:
		print("Wrong dish served!")
