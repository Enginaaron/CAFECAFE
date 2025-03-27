extends Control

@onready var button = $Button


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/start_page.tscn") 
