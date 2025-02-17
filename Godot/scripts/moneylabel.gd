extends Label

var money: int = 0

# Correct update function
func update_money(amount: int):
	money += amount
	self.text = "$" + str(money)  # Use self.text to update this label
