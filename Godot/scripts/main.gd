extends Node2D

@onready var ingredients_container = $Lettuce

var ingredient_scenes = {
	"Lettuce": preload("res://scenes/Lettuce.tscn"),
}

func spawn_ingredient(type, position):
	if ingredient_scenes.has(type):
		var ingredient = ingredient_scenes[type].instantiate()
		ingredient.ingredient_type = type
		ingredient.position = position
		ingredients_container.add_child(ingredient)
		print("Spawned:", type, "at", position)
