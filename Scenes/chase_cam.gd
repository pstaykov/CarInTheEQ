extends Camera3D

@export var target_path: NodePath          # assign your VehicleBody3D
@export var distance: float = 4.0          # base distance behind car
@export var height: float = 3.0            # camera height above car
@export var tilt_angle: float = 10.0      # static tilt in degrees (negative = down)
@export var follow_speed: float = 5.0      # how fast camera moves
@export var look_at_speed: float = 5.0     # how smooth the rotation follows
@export var speed_influence: float = 0.3   # pull back more at high speed

var target: VehicleBody3D
var look_target: Vector3

func _ready():
	if target_path != NodePath():
		target = get_node(target_path)
	if target:
		look_target = target.global_transform.origin

func _physics_process(delta: float) -> void:
	if not target:
		return

	var car_transform = target.global_transform
	var car_velocity = target.linear_velocity
	var car_speed = car_velocity.length()

	# --- position ---
	var dynamic_distance = distance + car_speed * speed_influence
	var back_dir = -car_transform.basis.z.normalized()
	var desired_pos = car_transform.origin + back_dir * dynamic_distance + Vector3.UP * height

	global_transform.origin = global_transform.origin.lerp(desired_pos, follow_speed * delta)

	# --- rotation ---
	# where we want to look (with smoothing)
	var aim_point = car_transform.origin + Vector3.UP * 1.5
	look_target = look_target.lerp(aim_point, look_at_speed * delta)

	# look forward, but with a static tilt
	var forward = (look_target - global_transform.origin).normalized()
	var desired_basis = Basis().looking_at(forward, Vector3.UP)
	desired_basis = desired_basis.rotated(desired_basis.x, deg_to_rad(tilt_angle))

	# smoothly rotate camera
	global_transform.basis = global_transform.basis.slerp(desired_basis, look_at_speed * delta)
