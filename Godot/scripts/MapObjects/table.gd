extends Node2D
# or extends Area2D if you're using collision

@export var possible_dishes: Array[Texture]

@onready var bubble_sprite = $OrderBubble/BubbleSprite
@onready var dish_sprite   = $OrderBubble/DishSprite
@onready var orderTimer = $OrderTimer
@onready var moneyLabel = get_node("../UI/moneyCounter/MoneyLabel")
@onready var dayLabel = get_node("../UI/dayCounter/dayLabel")
@onready var player = $"../player"

var current_dish: Texture = null
var has_order: bool = false

func _ready():
	# ensure bubble is invisible on start
	$OrderBubble.visible = false
	
	# initialize timer
	orderTimer.timeout.connect(_on_orderTimer_timeout)
	orderTimer.wait_time = randf_range(5.0,10.0)
	orderTimer.start()

func _on_orderTimer_timeout():
	if not has_order:
		generate_random_order()
	orderTimer.wait_time = randf_range(5,10)
	orderTimer.start()

func generate_random_order():
	if has_order == true:
		return
	# Pick a random dish
	current_dish = possible_dishes[randi() % possible_dishes.size()]
	dish_sprite.texture = current_dish
	
	# Show the bubble
	$OrderBubble.visible = true
	has_order = true

func clear_order():
	# Hide the bubble
	$OrderBubble.visible = false
	current_dish = null
	has_order = false

func serve(ingredient_name):
	var dish_texture
	if ingredient_name == "lettuce":
		dish_texture = possible_dishes[0]
	if dish_texture == current_dish and player.held_ingredient != null: # compare ordered-dish and holding-dish
		print("table served correctly!")
		player.held_ingredient.drop()
		player.held_ingredient.queue_free()  # Remove from player
		player.held_ingredient = null
		moneyLabel.update_money(5)
		dayLabel.update_day()
		clear_order()
		
		# Possibly award money, increment score, etc.
	else:
		print("wrong dish served!")
		# You can decide what happens on wrong serve
