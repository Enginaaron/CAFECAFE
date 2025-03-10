extends Label

func _ready():
	self.text = "$0"

var money: int = 0

func update_money(amount: int):
	money += amount
	self.text = "$" + str(money)
	
func get_money():
	return money
