extends Node3D

@export var move_speed: float = 30.0   # units per second
@export var spin_speed: float = 1.0    # radians per second

var _rng := RandomNumberGenerator.new()
var _move_dir: Vector3
var _spin_axis: Vector3

func _ready() -> void:
	_rng.randomize()

	# Pick a random direction to drift
	_move_dir = Vector3(
		_rng.randf_range(-1, 1),
		_rng.randf_range(-1, 1),
		_rng.randf_range(-1, 1)
	).normalized()

	# Pick a random spin axis
	_spin_axis = Vector3(
		_rng.randf_range(-1, 1),
		_rng.randf_range(-1, 1),
		_rng.randf_range(-1, 1)
	).normalized()

	# Randomize speed a bit
	move_speed *= _rng.randf_range(0.5, 1.5)
	spin_speed *= _rng.randf_range(0.5, 2.0)

func _process(delta: float) -> void:
	# Drift
	global_position += _move_dir * move_speed * delta
	# Spin
	rotate(_spin_axis, spin_speed * delta)
