extends Node2D

@export var storeInterface: CanvasLayer

var toggleStatus = ""

func toggle_store():
	print("toggle store")
	if toggleStatus == "":
		storeInterface.show()
		toggleStatus = null
	elif toggleStatus == null:
		# Open the shop: add it to a dedicated UI CanvasLayer (assumes a global UI node exists)
		storeInterface.hide()
		toggleStatus = ""
