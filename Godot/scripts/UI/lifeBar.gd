extends Control

@onready var heartContainer = $HeartContainer
@onready var dayLabel = $"../dayCounter/dayLabel"
var current_lives = 3
var max_lives = 3

func _ready():
	update_hearts()

func lose_life():
	if current_lives > 0:
		current_lives -= 1
		dayLabel.order_done()
		update_hearts()
		if current_lives <= 0:
			# Game over logic here
			print("Game Over!")
			get_tree().reload_current_scene()

func update_hearts():
	for i in range(heartContainer.get_child_count()):
		var heart = heartContainer.get_child(i)
		heart.visible = i < current_lives 

func add_bonus_life():
	# Increase current lives
	current_lives += 1
	# Update the visibility of hearts
	update_hearts()
	print("Added bonus life! Current lives: ", current_lives) 
