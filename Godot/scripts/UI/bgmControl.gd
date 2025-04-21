extends Node
var state = false

func _on_button_pressed() -> void:
	state = AudioManager.toggle_background_music(state)
