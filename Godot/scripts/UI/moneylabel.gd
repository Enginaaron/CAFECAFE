extends Label

var money: int = 5

func _ready():
	self.text = "$"+str(money)

func update_money(amount: int):
	money += amount
	self.text = "$" + str(money)
