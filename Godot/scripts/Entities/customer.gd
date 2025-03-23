extends CharacterBody2D

const SPEED = 100.0
const ARRIVAL_THRESHOLD = 4.0
const WAYPOINT_DISTANCE = 32.0

@onready var main = $".."
@onready var tilemap = $"../TileMapLayer"

var current_state = State.IDLE
var target_table: Node = null
var waypoints: Array[Vector2] = []
var current_waypoint_index = 0
var has_reached_destination = false

# three possible states of customer
enum State {
	IDLE,
	MOVING,
	ARRIVED
}

func _ready():
	position = Vector2i(176, 252)

func _physics_process(_delta: float) -> void:
	match current_state:
		# stop being useless and find purpose
		State.IDLE:
			if target_table and not has_reached_destination:
				create_path()
				current_state = State.MOVING
		
		# move towards next waypoint in path
		State.MOVING:
			if current_waypoint_index < waypoints.size():
				var target_pos = waypoints[current_waypoint_index]
				var direction = (target_pos - position).normalized()
				velocity = direction * SPEED
				move_and_slide()
				
				if position.distance_to(target_pos) < ARRIVAL_THRESHOLD:
					current_waypoint_index += 1
					if current_waypoint_index >= waypoints.size():
						has_reached_destination = true
						current_state = State.ARRIVED
						# customer claims table
						if target_table:
							target_table.set_customer(self)
							target_table.generate_random_order()
			else:
				has_reached_destination = true
				current_state = State.ARRIVED
		
		# stop moving when arrived
		State.ARRIVED:
			velocity = Vector2.ZERO

# finding best path to destination (a table)
func create_path() -> void:
	if not target_table:
		return
		
	waypoints.clear()
	var start_pos = position
	var end_pos = target_table.position-Vector2(0,-16)
	
	# starting waypoint
	waypoints.append(start_pos)
	
	# create waypoint on x axis
	var current_pos = start_pos
	while abs(current_pos.x - end_pos.x) > WAYPOINT_DISTANCE:
		current_pos.x += WAYPOINT_DISTANCE * sign(end_pos.x - current_pos.x)
		waypoints.append(current_pos)
	
	# create waypoint on y axis (at destination)
	while abs(current_pos.y - end_pos.y) > WAYPOINT_DISTANCE:
		current_pos.y += WAYPOINT_DISTANCE * sign(end_pos.y - current_pos.y)
		waypoints.append(current_pos)
	
	# final destination if not too close to the last waypoint
	if waypoints.size() == 0 or waypoints[-1].distance_to(end_pos) > WAYPOINT_DISTANCE:
		waypoints.append(end_pos)
	
	current_waypoint_index = 0
	has_reached_destination = false

func set_target_table(table: Node) -> void:
	target_table = table
	has_reached_destination = false

func _exit_tree():
	if target_table and main:
		main.remove_customer_from_table(self, target_table)
