extends Label

@onready var sprite = $"../sprite"
@export var coin: Texture

var money: int = 0

func _ready():
	update_money(0)

func update_money(amount: int):
	money += amount
	self.text = str(money)
	sprite.texture = coin
