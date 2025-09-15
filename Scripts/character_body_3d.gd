extends CharacterBody3D

@export var max_speed: float = 60.0
@export var acceleration: float = 30.0

# Steering & movement
@export var turn_speed: float = 14.0
@export var strafe_speed: float = 25.0
@export var vertical_speed: float = 1.0

# Craft tilt behaviour
@export var craft_pitch_amount: float = 0.15
@export var craft_yaw_tilt_amount: float = 0.2

# Assign the camera node from the scene (NOT as a child of ship)
@export var cam: Camera3D

var current_speed: float = 0.0

func _physics_process(delta: float) -> void:
	# Accelerate forward
	current_speed = clamp(current_speed + acceleration * delta, 0, max_speed)

	# Input
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("turn_right"):
		input_dir.x -= 1
	if Input.is_action_pressed("turn_left"):
		input_dir.x += 1
	if Input.is_action_pressed("accelerate"):
		input_dir.y -= 1
	if Input.is_action_pressed("brake"):
		input_dir.y += 1

	# Smooth local movement
	var local_velocity = Vector3(
		lerp(velocity.x, input_dir.x * strafe_speed, turn_speed * delta),
		lerp(velocity.y, input_dir.y * vertical_speed, turn_speed * delta),
		current_speed
	)

	# Apply movement
	velocity = transform.basis * local_velocity
	move_and_slide()

	# --- Craft tilt only (camera won’t inherit this) ---
	var craft_target_pitch = -input_dir.y * craft_pitch_amount
	rotation.x = lerp_angle(rotation.x, craft_target_pitch, 6.0 * delta)

	var craft_target_roll = -input_dir.x * craft_yaw_tilt_amount
	rotation.z = lerp_angle(rotation.z, craft_target_roll, 6.0 * delta)

	# --- Camera follow ---
	if cam:
		# Stick camera to ship’s global position
		cam.global_position = global_position
		# Keep the camera rotation independent (you can set it in the editor)
