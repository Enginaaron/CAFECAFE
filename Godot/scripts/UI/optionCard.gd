extends Button

signal item_selected(cost, stat_bonus)

var item_cost = 0
var bonus = {}

func setup_card(item_sprite: Texture, cost: int, stat_bonus: Dictionary):
	item_cost = cost
	$optionSprite.texture = item_sprite
	$optionCost.text = "$"+str(cost)
	bonus = stat_bonus
	

func _pressed():
	item_selected.emit(item_cost, bonus)
