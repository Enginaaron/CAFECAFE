extends Node2D

# This script handles the logic for ingredients in the game.

class_name Ingredient

# Properties of the ingredient
var name: String
var type: String
var is_chopped: bool = false

# Constructor to initialize the ingredient
func _init(name: String, type: String):
    self.name = name
    self.type = type

# Function to chop the ingredient
func chop():
    if not is_chopped:
        is_chopped = true
        print(name + " has been chopped.")
    else:
        print(name + " is already chopped.")

# Function to cook the ingredient
func cook():
    if is_chopped:
        print(name + " is being cooked.")
    else:
        print(name + " needs to be chopped before cooking.")

# Function to get the ingredient's status
func get_status() -> String:
    return name + " - " + (is_chopped ? "Chopped" : "Not Chopped")