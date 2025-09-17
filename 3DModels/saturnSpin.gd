extends Node3D  

# Rotation speed in degrees per second
@export var rotation_speed: float = -50.0

func _process(delta: float) -> void:
	rotate_y(deg_to_rad(rotation_speed) * delta)
