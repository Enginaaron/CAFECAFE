extends Control

# Store the number of players as an autoload/singleton so it's accessible throughout the game
var player_count = 0

func _ready():
	# Connect the buttons' pressed signals to our functions
	$OnePlayerButton.pressed.connect(start_single_player)
	$TwoPlayersButton.pressed.connect(start_two_players)

func start_single_player():
	player_count = 1
	start_game()

func start_two_players():
	player_count = 2
	start_game()

func start_game():
	# Store the player count in an autoload/singleton
	var game_data = get_node("/root/GameData")
	if game_data:
		game_data.player_count = player_count
	
	# Change to the main game scene
	get_tree().change_scene_to_file("res://scenes/main.tscn") 
