extends Label

@export var storeInterface: CanvasLayer
signal day_changed

var dayCount: int = 0
var orderCount: int = 0

func _ready() -> void:
	self.text = "Day "+str(dayCount)
	
func order_done() -> void:
	orderCount += 1
	if orderCount == 4:
		update_day()
		orderCount = 0

func update_day() -> void:
	dayCount += 1
	self.text = "Day " + str(dayCount)
	orderCount = 0
	storeInterface.refresh_stock()
	day_changed.emit()
