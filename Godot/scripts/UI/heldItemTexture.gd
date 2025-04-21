extends TextureRect

func update_box_sprite(new_item: Texture, state):
	texture = new_item
	match state:
		0: texture = new_item
		1: texture = new_item
		2: texture = new_item
	AudioManager.play_sound("transform")

func clear_box_sprite():
	texture = null
	
	
