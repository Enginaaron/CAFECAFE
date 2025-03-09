extends Node2D

@export var possible_upgrades: Array[Texture]

func _ready():
	# Check if possible_upgrades is properly set
	if possible_upgrades.size() == 0:
		print("WARNING: No possible upgrades set for store!")

func open_store():
	print("open store")
	return
	
func update_store():
	# Check if we have upgrades to offer
	if possible_upgrades.size() == 0:
		return
	
	# Generate random upgrades
	var upgrade1 = possible_upgrades[randi() % possible_upgrades.size()]
	var upgrade2 = possible_upgrades[randi() % possible_upgrades.size()]
	var upgrade3 = possible_upgrades[randi() % possible_upgrades.size()]
	
	return
