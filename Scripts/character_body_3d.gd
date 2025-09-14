extends CharacterBody3D

@export var max_speed: float = 60.0
@export var acceleration: float = 30.0
@export var turn_speed: float = 6.0
@export var strafe_speed: float = 15.0
@export var vertical_speed: float = 15.0
@export var camera_tilt_amount: float = 0.25

@onready var cam: Camera3D = $Camera3D

var current_speed: float = 0.0

func _physics_process(delta: float) -> void:
	# Accelerate forward
	current_speed = clamp(current_speed + acceleration * delta, 0, max_speed)

	# Input: natural horizontal, inverted vertical
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("turn_right"):
		input_dir.x -= 1
	if Input.is_action_pressed("turn_left"):
		input_dir.x += 1
	if Input.is_action_pressed("accelerate"):
		input_dir.y -= 1  
	if Input.is_action_pressed("brake"):
		input_dir.y += 1  

	# Smooth movement
	var local_velocity = Vector3(
		lerp(velocity.x, input_dir.x * strafe_speed, turn_speed * delta),
		lerp(velocity.y, input_dir.y * vertical_speed, turn_speed * delta),
		current_speed  # Forward along +Z
	)

	# Apply movement in global space
	velocity = transform.basis * local_velocity
	move_and_slide()

	# Camera tilt (natural left/right)
	var target_tilt = -input_dir.x * camera_tilt_amount
	cam.rotation.z = lerp(cam.rotation.z, target_tilt, 5.0 * delta)
