extends Node2D

@export var possible_upgrades: Array[Texture]
@export var option1: Node
@export var option2: Node
@export var option3: Node

var cost = 5


func _ready():
	# Check if possible_upgrades is properly set
	if possible_upgrades.size() == 0:
		print("WARNING: No possible upgrades set for store!")

func open_store():
	print("open store")
	return
<<<<<<< Updated upstream
	
func update_store():
	# Check if we have upgrades to offer
	if possible_upgrades.size() == 0:
		return
	
	# Generate random upgrades
	var upgrade1 = possible_upgrades[randi() % possible_upgrades.size()]
	var upgrade2 = possible_upgrades[randi() % possible_upgrades.size()]
	var upgrade3 = possible_upgrades[randi() % possible_upgrades.size()]
	
=======

func update_store(option):
	option1.get_upgrade(possible_upgrades[randi() % possible_upgrades.size()])
>>>>>>> Stashed changes
	return
