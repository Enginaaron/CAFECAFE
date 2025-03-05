extends Label

func _ready() -> void:
	self.text = "Day 0"

var dayCount: int = 0
var orderCount: int = 0

func update_day() -> void:
	orderCount += 1
	if orderCount == 5:
		dayCount += 1
		self.text = "Day " + str(dayCount)
		orderCount = 0
