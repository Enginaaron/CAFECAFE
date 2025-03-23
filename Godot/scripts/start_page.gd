extends Control

func _ready():
	# Connect the start button's pressed signal to our start_game function
	$StartButton.pressed.connect(start_game)

func start_game():
	# Change to the main game scene
	get_tree().change_scene_to_file("res://scenes/main.tscn") 
