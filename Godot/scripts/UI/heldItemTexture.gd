extends TextureRect

func update_box_sprite(new_item: Texture, state):
	texture = new_item
	match state:
		0: self.modulate = Color(1,1,1)
		1: self.modulate = Color(1,0,0)
		2: self.modulate = Color(0,0,1)

func clear_box_sprite():
	texture = null
	
	
