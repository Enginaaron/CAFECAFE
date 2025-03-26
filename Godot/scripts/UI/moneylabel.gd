extends Label

var money: int = 20

func _ready():
	self.text = "$"+str(money)

func update_money(amount: int):
	money += amount
	self.text = "$" + str(money)
