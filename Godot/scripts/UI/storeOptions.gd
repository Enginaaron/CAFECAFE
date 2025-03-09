extends Control

@export var store: Node2D

func get_upgrade(newItem: Texture):
	for child in get_children(): 
		if "optionSprite" in child.name:
			child.Texture = newItem

func _on_day_label_day_change():
	print("asdf")
	get_upgrade(store.possible_upgrades[randi() % store.possible_upgrades.size()])
	s
