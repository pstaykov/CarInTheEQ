extends Node3D

@export var move_speed: float = 10.0        # units/sec
@export var spin_speed: float = 1.5         # radians/sec
@export var fade_in_time: float = 1.5       # seconds to fully appear

var _rng := RandomNumberGenerator.new()
var _move_dir: Vector3
var _spin_axis: Vector3
var _fade_timer: float = 0.0
var _materials: Array[StandardMaterial3D] = []

func _ready() -> void:
	_rng.randomize()

	# random drift direction & spin axis
	_move_dir = Vector3(
		_rng.randf_range(-1, 1),
		_rng.randf_range(-1, 1),
		_rng.randf_range(-1, 1)
	).normalized()

	_spin_axis = Vector3(
		_rng.randf_range(-1, 1),
		_rng.randf_range(-1, 1),
		_rng.randf_range(-1, 1)
	).normalized()

	move_speed *= _rng.randf_range(0.6, 1.6)
	spin_speed *= _rng.randf_range(0.6, 2.0)

	# Collect materials and make them start transparent
	_collect_materials(self)
	for mat in _materials:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = 0.0  # fully invisible at spawn

func _process(delta: float) -> void:
	# movement + spin
	global_position += _move_dir * move_speed * delta
	if _spin_axis.length() > 0.001:
		rotate(_spin_axis, spin_speed * delta)

	# fade in
	if _fade_timer < fade_in_time:
		_fade_timer += delta
		var alpha = clamp(_fade_timer / fade_in_time, 0.0, 1.0)
		for mat in _materials:
			var c = mat.albedo_color
			c.a = alpha
			mat.albedo_color = c

		# Once fully visible, force opaque mode
		if _fade_timer >= fade_in_time:
			for mat in _materials:
				mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
				var c = mat.albedo_color
				c.a = 1.0
				mat.albedo_color = c

# --- Helpers ---
func _collect_materials(node: Node) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh:
			for s in range(mi.mesh.get_surface_count()):
				var mat: Material = mi.get_surface_override_material(s)
				if mat == null:
					mat = mi.mesh.surface_get_material(s)
				if mat:
					var dup = mat.duplicate() as StandardMaterial3D
					mi.set_surface_override_material(s, dup)
					_materials.append(dup)

	for child in node.get_children():
		_collect_materials(child)
