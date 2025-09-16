# SpaceJunk.gd (Godot 4)
extends Node3D

# --- Movement / spin ---
@export var move_speed: float = 10.0        # units/sec
@export var spin_speed: float = 1.5         # radians/sec

# --- Distance fade (per-object, keeps sky clear) ---
@export var fade_start: float = 250.0       # start fading at this distance
@export var fade_end: float = 600.0         # fully invisible at this distance

var _rng := RandomNumberGenerator.new()
var _move_dir: Vector3
var _spin_axis: Vector3

func _ready() -> void:
	_rng.randomize()

	# random drift direction & spin axis
	_move_dir = Vector3(_rng.randf_range(-1,1), _rng.randf_range(-1,1), _rng.randf_range(-1,1)).normalized()
	_spin_axis = Vector3(_rng.randf_range(-1,1), _rng.randf_range(-1,1), _rng.randf_range(-1,1)).normalized()
	move_speed *= _rng.randf_range(0.6, 1.6)
	spin_speed *= _rng.randf_range(0.6, 2.0)

	# apply distance fade to all MeshInstance3D children (and self if it is one)
	_apply_distance_fade(self)

func _process(delta: float) -> void:
	global_position += _move_dir * move_speed * delta
	if _spin_axis.length() > 0.001:
		rotate(_spin_axis, spin_speed * delta)

func _apply_distance_fade(node: Node) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		# handle all surfaces
		var surf_count := mi.mesh.get_surface_count() if mi.mesh else 0
		for s in range(surf_count):
			# prefer overriding so we don't edit shared import materials
			var mat: Material = mi.get_surface_override_material(s)
			if mat == null:
				mat = mi.mesh.surface_get_material(s)
			var new_mat: StandardMaterial3D = null
			if mat is StandardMaterial3D:
				new_mat = (mat as StandardMaterial3D).duplicate() # make unique
			else:
				new_mat = StandardMaterial3D.new()

			# enable transparency + distance fade
			new_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			new_mat.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_ALPHA
			new_mat.distance_fade_min_distance = fade_start
			new_mat.distance_fade_max_distance = fade_end

			mi.set_surface_override_material(s, new_mat)

	# recurse
	for child in node.get_children():
		_apply_distance_fade(child)
