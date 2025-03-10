extends Node2D

@export var storeInterface: CanvasLayer

func toggle_store():
	if storeInterface.visible:
		storeInterface.hide()
	else:
		storeInterface.show()
