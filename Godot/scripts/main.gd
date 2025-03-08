extends Node2D

@onready var ingredients_container = $Ingredients
@onready var tilemap = $TileMapLayer

var table_scene = preload("res://scenes/tables.tscn")

var ingredient_scenes = {
	"Lettuce": preload("res://scenes/Lettuce.tscn"),
}

func _ready():
	print("Main scene ready, initializing tables...")
	get_tables(tilemap)
	print("Tables initialization complete")

func spawn_ingredient(type, position):
	if ingredient_scenes.has(type):
		var ingredient = ingredient_scenes[type].instantiate()
		ingredient.ingredient_type = type
		ingredient.position = position
		ingredients_container.add_child(ingredient)
		print("Spawned:", type, "at", position)

func get_table_at_tile(tile_pos: Vector2i) -> Node:
	# Calculate world position for this tile (center of tile)
	var tile_size = tilemap.tile_set.tile_size
	var target_world_pos = tilemap.map_to_local(tile_pos) + Vector2(tile_size.x / 2, tile_size.y / 2)
	
	# Apply the offset adjustment
	target_world_pos -= Vector2(tile_size.x, 0)
	
	# Check for tables near this position
	for child in get_children():
		if child.scene_file_path == table_scene.resource_path:
			var distance = child.position.distance_to(target_world_pos)
			if distance < 20:
				return child
				
	return null

func get_tables(tilemap: TileMapLayer):
	print("Scanning for serve tiles and creating tables...")
	
	# Clear any existing tables first
	var existing_tables = []
	for child in get_children():
		if child.scene_file_path == table_scene.resource_path:
			existing_tables.append(child)
	
	for table in existing_tables:
		table.queue_free()
	
	# Get the tile size to calculate centering offset
	var tile_size = tilemap.tile_set.tile_size
	
	# Find serve tiles and create a table at each position
	for x in range(tilemap.get_used_rect().position.x, tilemap.get_used_rect().end.x):
		for y in range(tilemap.get_used_rect().position.y, tilemap.get_used_rect().end.y):
			var tile_pos = Vector2i(x,y)
			var tile_data = tilemap.get_cell_tile_data(tile_pos)
			
			if tile_data and tile_data.get_custom_data("serve"):
				print("Found serve tile at position:", tile_pos)
				
				# Create a new table instance at this serve tile
				var new_table = table_scene.instantiate()
				add_child(new_table)
				
				# Position the table at the center of the serve tile with offset correction
				var world_pos = tilemap.map_to_local(tile_pos)
				world_pos += Vector2(tile_size.x / 2, tile_size.y / 2)  # Center on tile
				world_pos -= Vector2(tile_size.x, 0)  # Fix the offset
				
				new_table.position = world_pos
				
				# Generate an order for the table
				new_table.generate_random_order()
				
	print("Table creation complete")
