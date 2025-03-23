extends Node2D

@onready var ingredients_container = $Ingredients
@onready var tilemap = $TileMapLayer
@onready var dayLabel = $UI/dayCounter/dayLabel

var ingredient_scenes = {
	"Lettuce": preload("res://scenes/Lettuce.tscn"),
}

var customer_scene = preload("res://scenes/customer.tscn")
var boss_customer_scene = preload("res://scenes/bossCustomer.tscn")

var table_customers = {} # dictionary tracking table and its customer
var spawn_timer: Timer = null
const SPAWN_INTERVAL = 2.0  # time between customer spawns in seconds
var bossDays = [5, 10, 15, 20] # bosses spawn on these days
var has_spawned_boss = false # track if boss has been spawned for current day

func _ready():
	init_tables()
	print("table count = ", table_customers.size())
	
	spawn_timer = Timer.new()
	spawn_timer.one_shot = true
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	
	dayLabel.update_day()

# finds tables in scene
func init_tables():
	for child in get_children():
		if child.name.begins_with("Tables"):
			for table in child.get_children():
				table_customers[table] = []
				table.order_generated.connect(_on_table_order_generated.bind(table))
				print("table init successful at ", table.position)

func get_table_at_tile(tile_pos: Vector2i) -> Node:
	# checks for tables in scene
	for table in table_customers.keys():
		var table_tile = tilemap.local_to_map(table.position)
		if table_tile == tile_pos:
			return table
	return null

func spawn_customers_for_empty_tables():
	var empty_tables = get_empty_tables()
	if empty_tables.is_empty():
		print("No empty tables to spawn customers for")
		return
	spawn_customer_for_table(empty_tables[0])

func spawn_customer_for_table(table: Node):
	var customer
	# Only spawn boss if it's a boss day and we haven't spawned one yet
	if dayLabel.dayCount in bossDays and not has_spawned_boss:
		customer = boss_customer_scene.instantiate()
		print("Spawning boss customer!")
		has_spawned_boss = true
	else:
		customer = customer_scene.instantiate()
	
	customer.global_position = Vector2i(-112,-48)
	add_child(customer)
	
	# assigning customer to table
	customer.set_target_table(table)
	table_customers[table].append(customer)
	
	var empty_tables = get_empty_tables()
	if not empty_tables.is_empty():
		# spawning schedule
		spawn_timer.wait_time = SPAWN_INTERVAL
		spawn_timer.start()

func _on_spawn_timer_timeout():
	var empty_tables = get_empty_tables()
	if not empty_tables.is_empty():
		spawn_customer_for_table(empty_tables[0])

func get_empty_tables() -> Array:
	var empty_tables: Array = []
	for table in table_customers.keys():
		if table_customers[table].is_empty():
			empty_tables.append(table)
	return empty_tables

@warning_ignore("shadowed_variable_base_class")
func spawn_ingredient(type, position):
	if ingredient_scenes.has(type):
		var ingredient = ingredient_scenes[type].instantiate()
		ingredient.ingredient_type = type
		ingredient.position = position
		ingredients_container.add_child(ingredient)
		print("Spawned:", type, "at", position)

func remove_customer_from_table(customer, table):
	if table_customers.has(table):
		table_customers[table].erase(customer)

func _on_table_order_generated(table: Node):
	print("order generated at ", table.position)

func _on_day_label_day_changed() -> void:
	# Reset boss spawn flag for new day
	has_spawned_boss = false
	
	# clear all customers if they exist
	print("regular customers spawning")
	for table in table_customers.keys():
		for customer in table_customers[table]:
			customer.queue_free()
		table_customers[table].clear()
	spawn_customers_for_empty_tables()
