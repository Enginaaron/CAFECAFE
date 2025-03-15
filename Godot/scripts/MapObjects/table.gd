extends Node2D
# or extends Area2D if you're using collision

@export var possible_dishes: Array[Texture]

@onready var bubble_sprite = $OrderBubble/BubbleSprite
@onready var dish_sprite   = $OrderBubble/DishSprite
@onready var orderTimer = $OrderTimer
@onready var orderProgressBar = $OrderBubble/OrderProgressBar if has_node("OrderBubble/OrderProgressBar") else null
@onready var moneyLabel = get_node("../UI/moneyCounter/MoneyLabel")
@onready var dayLabel = get_node("../UI/dayCounter/dayLabel")
@onready var player = $"../player"

var customer_scene = preload("res://scenes/customer.tscn")

const ORDER_TIME = 30.0  # Set order time to 30 seconds

var current_dish: Texture = null
var has_order: bool = false

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
		orderProgressBar.custom_minimum_size = Vector2(100, 10)
		orderProgressBar.visible = false
		$OrderBubble.add_child(orderProgressBar)
	
	# Hide order bubble initially
	$OrderBubble.visible = false
	
	# Generate first order
	call_deferred("generate_random_order")

func _process(delta):
	# Update progress bar exactly like in the ingredient scripts
	if has_order and orderTimer.time_left > 0:
		var progress = 100 * (1 - (orderTimer.time_left / orderTimer.wait_time))
		orderProgressBar.value = progress

func _on_orderTimer_timeout():
	# Order timed out
	if has_order:
		print("Order timed out!")
		clear_order()
	
	# Generate a new order
	generate_random_order()
	

func generate_random_order():
	if has_order:
		return
		
	# Pick a random dish
	if possible_dishes.size() == 0:
		print("ERROR: No dishes in possible_dishes array")
		return
		
	print("Generating random order...")
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
		print("Day ", currentDay, ": Order time is ", newOrderTime, " seconds")
	
	has_order = true
	print("New order created")
	spawn_customer()

func spawn_customer():
	customer_scene.instantiate()

func clear_order():
	# Hide the bubble and progress bar
	$OrderBubble.visible = false
	if orderProgressBar:
		orderProgressBar.visible = false
	
	current_dish = null
	has_order = false

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
	
	# Compare the served dish with the ordered dish
	if dish_texture == current_dish:
		# Handle successful serving
		player.held_ingredient.drop()
		player.held_ingredient.queue_free()  # Remove from player
		player.held_ingredient = null
		moneyLabel.update_money(5)
		dayLabel.update_day()
		clear_order()
	else:
		print("Wrong dish served!")
