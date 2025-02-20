extends Node2D

@onready var ingredients_container = $Ingredients

var ingredient_scenes = {
	"Lettuce": preload("res://scenes/Lettuce.tscn"),
}
