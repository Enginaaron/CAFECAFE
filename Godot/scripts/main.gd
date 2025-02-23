extends Node2D

@onready var ingredients_container = $Ingredients
@onready var tilemap = $TileMapLayer

var table_scene = preload("res://scenes/tables.tscn")

var ingredient_scenes = {
	"Lettuce": preload("res://scenes/Lettuce.tscn"),
}

func _ready():
	place_tables_from_tilemap(tilemap)

func spawn_ingredient(type, position):
	if ingredient_scenes.has(type):
		var ingredient = ingredient_scenes[type].instantiate()
		ingredient.ingredient_type = type
		ingredient.position = position
		ingredients_container.add_child(ingredient)
		print("Spawned:", type, "at", position)

func get_table_at_tile(tile_pos: Vector2i) -> Node:
	# Iterate over all children and find a table at the given tile position
	# Assuming your tables are instances of Table.tscn and have a property "position"
	for child in get_children(): 
		if "Tables" in child.name:
			var table_tile = tilemap.local_to_map(child.position)
			if table_tile == tile_pos:
				return child
	return null

func place_tables_from_tilemap(tilemap: TileMapLayer):
	for x in range(tilemap.get_used_rect().position.x, tilemap.get_used_rect().end.x):
		for y in range(tilemap.get_used_rect().position.y, tilemap.get_used_rect().end.y):
			var tile_data = tilemap.get_cell_tile_data(Vector2i(x,y))
			if tile_data and tile_data.get_custom_data("serve"):
				var new_table = table_scene.instantiate()
				add_child(new_table)
				new_table.position = tilemap.map_to_world(Vector2i(x,y)) + tilemap.cell_size / 2
				# Generate a random order immediately or wait until some event:
				new_table.generate_random_order()
				
