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
	# Get the main node reference
	main = get_node("/root/Node2D")
	# Get the storeInterface reference
	storeInterface = get_node("/root/Node2D/UI/storeInterface")

func order_done() -> void:
	print("nice")
	orderCount -= 1
	if orderCount == 0:
		update_day()

func update_day() -> void:
	dayCount += 1
	self.text = str(dayCount)
	sprite.texture = sun
	orderCount = main.table_customers.size()
	storeInterface.refresh_stock()
	day_changed.emit()
