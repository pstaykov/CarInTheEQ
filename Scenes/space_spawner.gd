extends Node3D

@export var ship: Node3D
@export var spawn_distance: float = 500.0
@export var despawn_distance: float = 800.0
@export var max_junk: int = 50
@export var spawn_interval: float = 1.0
@export var spread: float = 200.0

var junk_scenes: Array[PackedScene] = [
	preload("res://JunkScenes/1.tscn"),
	preload("res://JunkScenes/2.tscn"),
	preload("res://JunkScenes/3.tscn"),
	preload("res://JunkScenes/4.tscn"),
	preload("res://JunkScenes/5.tscn"),
	preload("res://JunkScenes/6.tscn"),
	preload("res://JunkScenes/7.tscn"),
	preload("res://JunkScenes/8.tscn"),
	preload("res://JunkScenes/9.tscn"),
	preload("res://JunkScenes/10.tscn"),
	preload("res://JunkScenes/11.tscn"),
	preload("res://JunkScenes/12.tscn"),
	preload("res://JunkScenes/13.tscn"),
	preload("res://JunkScenes/14.tscn"),
	preload("res://JunkScenes/15.tscn"),
	preload("res://JunkScenes/16.tscn"),
	preload("res://JunkScenes/17.tscn"),
	preload("res://JunkScenes/18.tscn"),
	preload("res://JunkScenes/19.tscn"),
	preload("res://JunkScenes/20.tscn"),
	preload("res://JunkScenes/21.tscn"),
	preload("res://JunkScenes/22.tscn"),
	preload("res://JunkScenes/23.tscn"),
	preload("res://JunkScenes/24.tscn"),
	preload("res://JunkScenes/25.tscn"),
	preload("res://JunkScenes/26.tscn"),
	preload("res://JunkScenes/27.tscn"),
	preload("res://JunkScenes/28.tscn"),
	preload("res://JunkScenes/29.tscn"),
	preload("res://JunkScenes/30.tscn"),
	preload("res://JunkScenes/31.tscn"),
	preload("res://JunkScenes/32.tscn"),
	preload("res://JunkScenes/33.tscn"),
	preload("res://JunkScenes/34.tscn"),
	preload("res://JunkScenes/35.tscn"),
	preload("res://JunkScenes/36.tscn"),
	preload("res://JunkScenes/37.tscn"),
]


var _rng := RandomNumberGenerator.new()
var _timer := 0.0
var _spawned: Array[Node3D] = []

func _ready() -> void:
	_rng.randomize()

func _physics_process(delta: float) -> void:
	if not ship or junk_scenes.is_empty():
		return

	_timer += delta
	if _timer >= spawn_interval and _spawned.size() < max_junk:
		_timer = 0.0
		_spawn_junk()

	# Despawn old junk
	for i in range(_spawned.size() - 1, -1, -1):
		var j = _spawned[i]
		if not is_instance_valid(j):
			_spawned.remove_at(i)
			continue
		var rel = j.global_position - ship.global_position
		if rel.dot(ship.global_transform.basis.z) > despawn_distance:
			print("Despawning junk at ", j.global_position)
			_spawned.remove_at(i)
			j.queue_free()

func _spawn_junk() -> void:
	if not ship or not ship.is_inside_tree():
		return

	# Pick a random junk scene
	var scene: PackedScene = junk_scenes[_rng.randi_range(0, junk_scenes.size() - 1)]

	# Ship forward (-Z)
	var forward = ship.global_transform.basis.z.normalized()

	# Position in front with spread
	var pos = ship.global_position + forward * spawn_distance
	pos += ship.global_transform.basis.x * _rng.randf_range(-spread, spread)
	pos += ship.global_transform.basis.y * _rng.randf_range(-spread, spread)

	# Create junk
	var junk = scene.instantiate()
	junk.global_position = pos

	# Scale down to ~1%
	if junk is Node3D:
		var scale_factor = _rng.randf_range(1, 1.6)
		junk.scale = Vector3.ONE * scale_factor

	add_child(junk)
	_spawned.append(junk)

	print("Spawned junk: ", scene.resource_path, " at ", pos, " scale ", junk.scale)
