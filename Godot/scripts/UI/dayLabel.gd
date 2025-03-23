extends Label

@onready var sprite = $"../sprite"
@export var sun: Texture

var storeInterface
var main
var orderCount

signal day_changed
var dayCount: int = 0

func _ready() -> void:
	self.text = str(dayCount)
	sprite.texture = sun
	main = get_node("/root/Node2D")
	storeInterface = get_node("/root/Node2D/UI/storeInterface")

func order_done() -> void:
	orderCount -= 1
	if orderCount == 0:
		update_day()

func update_day() -> void:
	dayCount += 1
	self.text = str(dayCount)
	orderCount = main.table_customers.size()
	storeInterface.refresh_stock()
	day_changed.emit()
