# CuttingBoard.gd
extends "res://scripts/Appliance.gd"

var cutting_time = 1.0  # seconds
var processing_item = null  # We'll use this to store the current item being processed.

func interact(item):
	if is_in_use:
		return null  # Appliance is busy.
	
	# Check if the item can be cut.
	if item == "Tomato":
		is_in_use = true
		processing_item = item  # Store the item for later use.
		
		var timer = Timer.new()
		timer.wait_time = cutting_time
		timer.one_shot = true
		add_child(timer)
		timer.connect("timeout", Callable(self, "_on_cutting_finished"))
		timer.start()
		
		return null  # No immediate result.
	else:
		return item

func _on_cutting_finished():
	is_in_use = false
	var chopped_item = processing_item + "_Chopped"
	processing_item = null
	emit_signal("appliance_finished", chopped_item)
