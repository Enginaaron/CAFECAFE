extends Node2D

@export var possible_upgrades: Array[Texture]

func open_store():
	print("open store")
	return
	
func update_store():
	var upgrade1 = possible_upgrades[randi() % possible_upgrades.size()]
	var upgrade2 = possible_upgrades[randi() % possible_upgrades.size()]
	var upgrade3 = possible_upgrades[randi() % possible_upgrades.size()]
	print("update store")
	return
