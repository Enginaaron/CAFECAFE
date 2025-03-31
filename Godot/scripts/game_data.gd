extends Node

# Game configuration
var player_count: int = 1  # Default to 1 player
var tutorial_mode: bool = false  # Flag for tutorial mode

# Default player stats
var default_stats = {
	"MOVE_SPEED": 200,
	"CHOP_SPEED": 6,
	"PACKAGE_SPEED": 5,
	"FRY_TIME": 15,
	"TAPIOCA_SCOOP": 5,
	"TEA_SPEED": 5,
	"GRILL_SPEED": 15
}

# Player stats
var player1_stats = {
	"MOVE_SPEED": 200,
	"CHOP_SPEED": 6,
	"PACKAGE_SPEED": 5,
	"FRY_TIME": 15,
	"TAPIOCA_SCOOP": 5,
	"TEA_SPEED": 5,
	"GRILL_SPEED": 15
}

var player2_stats = {
	"MOVE_SPEED": 200,
	"CHOP_SPEED": 6,
	"PACKAGE_SPEED": 5,
	"FRY_TIME": 15,
	"TAPIOCA_SCOOP": 5,
	"TEA_SPEED": 5,
	"GRILL_SPEED": 15
}

func reset_game():
	player_count = 1
	tutorial_mode = false
	player1_stats = default_stats.duplicate()
	player2_stats = default_stats.duplicate()

func get_player_stats(player_number: int) -> Dictionary:
	if player_number == 1:
		return player1_stats
	else:
		return player2_stats 
