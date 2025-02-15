extends Node2D

# Declare any variables or constants here
var ingredient_name: String = ""
var is_chopped: bool = false

# Class to represent an ingredient
class Ingredient:
	var name: String
	var type: String
	var is_cut: bool

	func _init(name: String, type: String):
		self.name = name
		self.type = type
		self.is_cut = false

	func cut():
		is_cut = true
		return name + "_Chopped"

# Function to create a new ingredient
func create_ingredient(name: String, type: String) -> Ingredient:
	return Ingredient.new(name, type)

# Function to interact with an ingredient
func interact_with_ingredient(ingredient: Ingredient):
	if ingredient.is_cut:
		print(ingredient.name + " is already chopped.")
	else:
		var chopped_name = ingredient.cut()
		print("You have chopped the " + ingredient.name + ". It is now " + chopped_name + ".")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass  # Replace with function body.
