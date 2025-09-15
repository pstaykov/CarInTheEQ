extends Camera3D

@export var ship: Node3D
@export var follow_smooth: float = 6.0
@export var offset: Vector3 = Vector3(0, 0, -5)

func _physics_process(delta: float) -> void:
	if ship:
		# --- Position follow ---
		var target_pos = ship.global_transform.origin + ship.global_transform.basis * offset
		global_position = global_position.lerp(target_pos, follow_smooth * delta)

		# --- Orientation follow (yaw only, ignore pitch) ---
		var ship_basis = ship.global_transform.basis
		var forward = -ship_basis.z
		forward.y = 0
		forward = forward.normalized()

		var up = Vector3.UP
		var right = up.cross(forward).normalized()
		var corrected_basis = Basis(right, up, forward)

		global_transform.basis = global_transform.basis.slerp(corrected_basis, follow_smooth * delta)
