extends "res://scripts/appliance.gd"

var baking_time = 3.0  # seconds

func interact(item):
	if is_in_use:
		return null
	# Check if the item can be baked
	if item == "Dough":
		is_in_use = true
		var timer = Timer.new()
		timer.wait_time = baking_time
		timer.one_shot = true
		add_child(timer)
		timer.connect("timeout", Callable(self, "_on_baking_finished"))
		timer.start()
		return null
	else:
		# If the item can't be baked, just return it
		return item

func _on_baking_finished(item):
	is_in_use = false
	var baked_item = "Bread"
	emit_signal("appliance_finished", baked_item)
