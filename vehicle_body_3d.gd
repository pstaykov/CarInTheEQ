extends VehicleBody3D

@export var max_engine_force: float = 300.0
@export var max_brake: float = 60.0
@export var max_steer: float = 0.6
@export var steer_speed: float = 5.0

var _steer_target := 0.0

func _ready() -> void:
	global_transform.origin = Vector3(0, 1.2, 0) # start above road

func _physics_process(delta: float) -> void:
	# throttle forward/backward
	var throttle := Input.get_action_strength("accelerate") - Input.get_action_strength("brake")
	engine_force = throttle * max_engine_force

	# braking (when no throttle and pressing brake)
	var braking := 0.0
	if Input.is_action_pressed("brake") and throttle <= 0.0:
		braking = max_brake
	brake = braking

	# steering
	var steer_dir := Input.get_action_strength("turn_left") - Input.get_action_strength("turn_right")
	_steer_target = steer_dir * max_steer
	steering = lerp(steering, _steer_target, steer_speed * delta)
