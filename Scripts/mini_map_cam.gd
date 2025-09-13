extends Camera3D

@export var car_path: NodePath
@export var height: float = 30.0
@export var distance: float = 200.0

var car: Node3D

func _ready():
	car = get_node(car_path)

func _process(delta: float) -> void:
	if car:
		var target_pos = car.global_transform.origin
		global_transform.origin = target_pos + Vector3(0, height, -distance)
