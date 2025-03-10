extends Button  # Or Panel if you want to manage click detection differently

signal item_selected(cost, stat_bonus)

var item_cost = 0
var bonus = {}

func setup_card(item_sprite: Texture, cost: int):
	item_cost = cost
	$optionSprite.texture = item_sprite  # Adjust node path accordingly
	$optionCost.text = str(cost)

func _pressed():
	emit_signal("item_selected", item_cost, bonus)
