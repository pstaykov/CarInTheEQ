extends Node3D

@export var brake_force: float = 100.0
var car: VehicleBody3D
var spaceship: CharacterBody3D
var menu_opened := false

func _ready():
	var cars = get_tree().get_nodes_in_group("car")
	var spaceship = get_tree().get_first_node_in_group("player")
	if cars.size() > 0:
		car = cars[0]
	else:
		push_error("No car found in group 'car'")


func _on_trigger_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("car") and not menu_opened:
		print("Car entered")
		# Apply brakes
		car.engine_force = 0
		car.brake = brake_force
		# Wait until the car slows down
		await get_tree().create_timer(1.5).timeout
		car.linear_velocity = Vector3.ZERO
		car.engine_force = 0
		car.brake = brake_force * 5
		get_tree().paused = true
		_open_store_menu()
		
	if body.is_in_group("player") and not menu_opened:
		print("Spaceship entered")
		get_tree().paused = true
		await get_tree().create_timer(1.5).timeout
		_open_space_store_menu()
	
func _open_store_menu():
	print("Menu opened")
	menu_opened = true

	# Show store menu (use group instead of hard path)
	var uis = get_tree().get_nodes_in_group("store_ui")
	var ui = uis[0]
	ui.visible = true

func _open_space_store_menu():
	menu_opened = true
	var ui = get_tree().get_first_node_in_group("SpaceStore")
	ui.visible = true
	
