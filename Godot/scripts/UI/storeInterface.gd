extends CanvasLayer

@export var option_card_scene: PackedScene  # Assign your ItemCard.tscn here
@onready var moneyLabel = get_tree().get_root().get_node("Node2D/UI/moneyCounter/MoneyLabel")

# Dictionary with keys "sprite", "cost", and "stat_bonus"
var all_items = [
	{ "sprite": preload("res://textures/boots.png"), "cost": 2, "stat_bonus": {"moveSpeed": 50} },
	{ "sprite": preload("res://textures/mittens.png"), "cost": 8, "stat_bonus": {"packageSpeed": -.75} },
	{ "sprite": preload("res://textures/knife.png"), "cost": 5, "stat_bonus": {"chopSpeed": -1} },
	# Remember to add more items later
]

var stock = [] 
var has_purchased = false

@onready var cards_container = $CardsContainer

func _ready():
	refresh_stock()

func refresh_stock():
	stock.clear()
	has_purchased = false
	# Clear any previous cards
	for n in cards_container.get_children():
		cards_container.remove_child(n)  
		n.queue_free() 
	
	# Check if we're in tutorial mode
	var game_data = get_node("/root/GameData")
	if game_data and game_data.tutorial_mode:
		# In tutorial mode, only show the chopping card
		var chop_item = { "sprite": preload("res://textures/knife.png"), "cost": 5, "stat_bonus": {"chopSpeed": -1} }
		stock.append(chop_item)
	else:
		# Normal mode: randomly pick three items
		var items_pool = all_items.duplicate()
		items_pool.shuffle()
		stock = items_pool.slice(0, 3)
	
	# Create item cards for each stock item
	for item in stock:
		var card = option_card_scene.instantiate()
		card.setup_card(item.sprite, item.cost, item.stat_bonus)
		card.connect("item_selected", Callable(self, "_on_item_selected"))
		cards_container.add_child(card)

func get_active_player() -> Node:
	# Get all players in the scene
	var players = get_tree().get_nodes_in_group("players")
	
	# Find the player that's near the store
	for player in players:
		# Check if the player is facing a store tile
		var facing_tile = player.tileMap.local_to_map(player.global_position) + player.get_facing_direction()
		var tile_data = player.tileMap.get_cell_tile_data(facing_tile)
		if tile_data and tile_data.get_custom_data("store"):
			return player
	
	return null

func _on_item_selected(cost, stat_bonus):
	if has_purchased:
		return  # Only allow one purchase per shop visit
	
	var active_player = get_active_player()
	if not active_player:
		print("No player found at store!")
		return
	
	# Purchase logic
	if moneyLabel.money >= cost:
		moneyLabel.update_money(-cost)
		active_player.apply_bonus(stat_bonus)
		has_purchased = true
		_disable_remaining_cards()
		
		# Check if we're in tutorial mode and this was the chop upgrade
		var game_data = get_node("/root/GameData")
		if game_data and game_data.tutorial_mode and stat_bonus.has("chopSpeed"):
			# Get tutorial manager and notify it of the purchase
			var tutorial_manager = get_node("/root/Node2D/tutorial_manager")
			if tutorial_manager:
				tutorial_manager.on_chop_upgrade_purchased()
		
		self.hide()
	else:
		# Optionally, show a "Not enough money" message
		print("Not enough money to purchase that item.")

func _disable_remaining_cards():
	for card in cards_container.get_children():
		card.set_disabled(true)
