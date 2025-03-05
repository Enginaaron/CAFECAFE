extends Label

func _ready():
	self.text = "$0"

var money: int = 0

# Correct update function
func update_money(amount: int):
	money += amount
	self.text = "$" + str(money)
