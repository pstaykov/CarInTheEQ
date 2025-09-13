extends VehicleBody3D

# === CONFIG ===
@export var max_engine_force: float = 1500.0
@export var max_brake: float = 60.0
@export var max_steer: float = 0.4     # radians (~34°) at low speed
@export var steer_speed: float = 2.0   # how fast steering follows input
@export var max_speed: float = 15.0    # m/s → 50 km/h
@export var cameras: Array[Camera3D]   # assign in Inspector

# === RUNTIME ===
var _steer_target := 0.0
var current_index := 0

# reference to UI label (adjust path if needed)
@onready var speed_label: Label = get_tree().root.get_node("Main/SpeedLabel/SpeedLabel")

func _ready() -> void:
	global_transform.origin = Vector3(0, 1.2, 0) # spawn above road


func _physics_process(delta: float) -> void:
	# --- throttle and brake ---
	var throttle := Input.get_action_strength("accelerate") - Input.get_action_strength("brake")
	engine_force = throttle * max_engine_force

	var braking := 0.0
	if Input.is_action_pressed("brake") and throttle <= 0.0:
		braking = max_brake
	brake = braking

	# --- steering with limiter ---
	var steer_dir := Input.get_action_strength("turn_left") - Input.get_action_strength("turn_right")
	var speed := linear_velocity.length()

	# steering shrinks at high speed
	var steer_limit_low = max_steer
	var steer_limit_high = max_steer * 0.15    # only 15% of full lock at top speed
	var speed_limit = 40.0                     # above this, use min steering
	var allowed_steer = lerp(steer_limit_low, steer_limit_high, clamp(speed / speed_limit, 0, 1))

	_steer_target = steer_dir * allowed_steer
	steering = lerp(steering, _steer_target, steer_speed * delta)

	# --- speed limiter ---
	if speed > max_speed:
		linear_velocity = linear_velocity.normalized() * max_speed

	# --- update tachometer text ---
	var speed_kmh = speed * 3.6
	if speed_label:
		speed_label.text = "Speed: %d km/h" % speed_kmh
		

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("switch_camera"):
		_switch_camera()


func _switch_camera() -> void:
	if cameras.is_empty():
		return

	# disable current cam
	cameras[current_index].current = false

	# cycle to next
	current_index = (current_index + 1) % cameras.size()

	# enable new cam
	cameras[current_index].current = true
