extends Label

@onready var store = $"../Store"

func _ready() -> void:
	self.text = "Day 1"

var dayCount: int = 1
var orderCount: int = 0

func update_day() -> void:
	orderCount += 1
	
	if orderCount == 1:
		dayCount += 1
		self.text = "Day " + str(dayCount)
		orderCount = 0
		
		# Safely call update_store
		if store != null:
			store.update_store()
		else:
			store = get_node_or_null("../Store")
			if store != null:
				store.update_store()
