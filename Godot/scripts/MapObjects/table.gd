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
@onready var player = $"../../player"
@onready var main = $".."

const ORDER_TIME = 30.0 

var current_dishes: Array[Texture] = []
var has_order: bool = false
var current_customer: Node = null
var is_boss_table: bool = false
var completed_orders: int = 0

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
		
	print("Generating random order...")
	
	# Clear previous orders
	current_dishes.clear()
	completed_orders = 0
	
	# Generate orders based on whether this is a boss table
	if is_boss_table:
		# Generate 3 random orders for boss
		for i in range(3):
			current_dishes.append(possible_dishes[randi() % possible_dishes.size()])
		dish_sprite.texture = current_dishes[0]  # Show first order
	else:
		# Generate single order for regular customer
		current_dishes.append(possible_dishes[randi() % possible_dishes.size()])
		dish_sprite.texture = current_dishes[0]
	
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
		print("day ", currentDay, ": order time is ", newOrderTime, " secs")
	
	has_order = true
	print("order created")
	# Emit the signal when a new order is generated
	order_generated.emit()

func clear_order():
	# Hide the bubble and progress bar
	$OrderBubble.visible = false
	if orderProgressBar:
		orderProgressBar.visible = false
	
	current_dishes.clear()
	has_order = false
	completed_orders = 0

func set_customer(customer: Node) -> void:
	current_customer = customer
	# Check if this is a boss customer
	is_boss_table = customer.name.begins_with("BossCustomer")

func serve(ingredient_name):
	var dish_texture = null
	
	# Map ingredient names to their corresponding dish textures
	match ingredient_name.to_lower():
		"lettuce":
			dish_texture = possible_dishes[0]
		_:
			return
	
	# Check if we have an order, the player is holding something, and it's packaged
	if not has_order or player.held_ingredient == null:
		return
		
	# Ensure the ingredient is in its packaged state
	if player.held_ingredient.state != player.held_ingredient.State.PACKAGED:
		print("Cannot serve unpackaged ingredient!")
		return
	
	# Check if the served dish matches any of the current orders
	var order_index = current_dishes.find(dish_texture)
	if order_index != -1:
		# Handle successful serving
		player.held_ingredient.drop()
		player.held_ingredient.queue_free()  # Remove from player
		player.held_ingredient = null
		
		# Remove the completed order
		current_dishes.remove_at(order_index)
		completed_orders += 1
		
		# Update money based on whether it's a boss order
		if is_boss_table:
			moneyLabel.update_money(10)  # More money for boss orders
		else:
			moneyLabel.update_money(5)
		
		dayLabel.order_done()
		
		# Update the displayed order
		if current_dishes.size() > 0:
			dish_sprite.texture = current_dishes[0]
		else:
			# All orders completed
			clear_order()
			# Remove the customer after successful serve
			if current_customer:
				current_customer.queue_free()
				current_customer = null
	else:
		print("Wrong dish served!")
