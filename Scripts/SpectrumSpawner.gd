extends Node3D

@export var decorations: Array[PackedScene] = [
	preload("res://Decorations/palm.tscn")
]  # assign Tree, Rock, etc.
@export var road_width: float = 10.0          # half-width from center
@export var spacing: float = 10.0             # distance between decorations
@export var offset_z: float = 5.0             # how far ahead to spawn

# sun
@export var sun_scene: PackedScene = preload("res://Decorations/Sun.tscn")
var sun: Node3D = null

# spawn store
@export var store_scene: PackedScene = preload("res://Decorations/Store.tscn")
var store_spawned := false

# music disks and casetted
@export var disk_scene: PackedScene = preload("res://Decorations/MusicDisc.tscn")
@export var casette_scene: PackedScene = preload("res://Scenes/casette.tscn")
@export var disks_per_gap: int = 3
var casette_spawned = false


# === CONFIG ===
@export var bar_width: float = 3
@export var row_spacing: float = 2.85
@export var height_scale: float = 10.0
@export var ground_y: float = -1.0
@export var step_time: float = 0.2
@export var gap_size: int = 8
@export var max_rows: int = 20
@export var max_disks: int = 10


# === RUNTIME ===
var frames: Array = []
var bands: int = 0
var current_row: int = 0
var z_offset: float = 10.0
var offset_x: float = 30.0  
var tunnel_pos: int = 35
var timer: Timer
var row_counter: int = 0

# --- NEW ---
var active_rows: Array[Node3D] = []
var active_disks: Array[Node3D] = []


func _ready() -> void:
	randomize()
	_load_json(Global.current_level["json_path"])
	if frames.is_empty():
		push_error("No frames in JSON: %s" % Global.current_level["json_path"])
		return

	# --- Timer ---
	timer = Timer.new()
	timer.wait_time = step_time
	timer.one_shot = false
	add_child(timer)
	timer.timeout.connect(_on_tick)
	timer.start()

	# --- Setup audio on car ---
	var audio_path: String = Global.current_level["audio_path"]
	if audio_path != "" and FileAccess.file_exists(audio_path):
		var car: Node = get_tree().root.get_node("Main/Car") # ⚠ adjust if Car node path is different
		if car and car.has_node("AudioStreamPlayer3D"):
			var player: AudioStreamPlayer3D = car.get_node("AudioStreamPlayer3D")
			player.stream = load(audio_path)
			player.play()
			print("Playing %s on car" % audio_path)
		else:
			push_warning("Car or AudioStreamPlayer3D not found in scene!")
	else:
		push_warning("No audio found for: %s" % audio_path)


func _load_json(path: String) -> void:
	if path == "" or not FileAccess.file_exists(path):
		return
	var f := FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	frames = data.get("frames", [])
	bands = data.get("bands", 0)
	if bands == 0 and frames.size() > 0:
		bands = frames[0].size()
	print("Loaded %d frames, %d bands" % [frames.size(), bands])


func _on_tick() -> void:
	if current_row >= frames.size():
		timer.stop()
		print("Finished spawning spectrum")
		# === Resize road collision to match bars ===
		var road_collision: CollisionShape3D = get_tree().root.get_node("Main/road/StaticBody3D/CollisionShape3D")

		if road_collision and road_collision.shape is BoxShape3D:
			var shape := road_collision.shape as BoxShape3D
			var total_length = frames.size() * row_spacing

			# Update Z size of road
			shape.size.z = total_length

			# Move collider so it starts where bars begin
			road_collision.transform.origin.z = -(total_length * 0.5)

			print("Road collider adjusted to length:", total_length)
		if not store_spawned and store_scene:
			var store = store_scene.instantiate()
			add_child(store)

			# Get center of the tunnel (same as floor strip)
			var left_x := -(bands * bar_width) * 0.5
			var gap_x = left_x + tunnel_pos * bar_width + (gap_size * bar_width * 0.5)

			# Position store right at the end of the road
			var store_x = gap_x
			var store_y = ground_y
			var store_z = z_offset - row_spacing  
			store.transform.origin = Vector3(store_x, store_y, store_z)

			store_spawned = true
		return

	# --- Spawn next row ---
	var row = _spawn_row(frames[current_row])
	if row:
		active_rows.append(row)

		# keep only latest max_rows
		if active_rows.size() > max_rows:
			var old = active_rows.pop_front()
			if is_instance_valid(old):
				old.queue_free()

	current_row += 1
	z_offset -= row_spacing


@export var palm_scene: PackedScene = decorations.pick_random()

func _spawn_row(values: Array) -> Node3D:
	var row_container := Node3D.new()
	add_child(row_container)

	var left_x := -(bands * bar_width) * 0.5

	# --- Tunnel shifting (max ±1, 25% chance) ---
	if randi() % 100 < 25:
		tunnel_pos += randi_range(-2, 2)
		tunnel_pos = clamp(tunnel_pos, 1, bands - gap_size - 1)

	# --- Spawn bars ---
	for i in range(bands):
		if i >= tunnel_pos and i < tunnel_pos + gap_size:
			continue

		var h: float = float(values[i]) * height_scale
		h = max(h, 1.0)
		
		var body := StaticBody3D.new()
		row_container.add_child(body)

		var bar := MeshInstance3D.new()
		var bar_mesh := BoxMesh.new()
		bar_mesh.size = Vector3(bar_width, 1.0, row_spacing)
		bar.mesh = bar_mesh

		var collision := CollisionShape3D.new()
		var collision_shape := BoxShape3D.new()
		collision_shape.size = bar_mesh.size
		collision.shape = collision_shape

		var killzone: Area3D = preload("res://Scenes/killzone.tscn").instantiate()
		var killzone_collision := CollisionShape3D.new()
		var killzone_shape := BoxShape3D.new()
		killzone_shape.size = bar_mesh.size
		killzone_collision.shape = killzone_shape
		killzone.add_child(killzone_collision)

		body.add_child(bar)
		body.add_child(collision)	
		body.add_child(killzone)

		var bar_mat := StandardMaterial3D.new()
		var t: float = clamp(h / (height_scale * 0.8), 0.0, 1.0)
		var low := Color(0.2, 0.4, 1.0, 0.95)
		var high := Color(0.8, 0.2, 1.0, 0.95)
		var col := low.lerp(high, t)
		bar_mat.albedo_color = col
		bar_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		bar_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		bar_mat.emission_enabled = true
		bar_mat.emission = col
		bar_mat.emission_energy_multiplier = 1.2
		bar.material_override = bar_mat

		body.transform.origin = Vector3(left_x + i * bar_width, ground_y + h * 0.5, z_offset)
		body.scale = Vector3(1.0, h, 1.0)

	# --- Pink floor strip under the tunnel ---
	var floor_container := StaticBody3D.new()
	row_container.add_child(floor_container)

	var floor_mesh_instance := MeshInstance3D.new()
	var floor_plane := BoxMesh.new()
	floor_plane.size = Vector3(gap_size * bar_width, 0.2, row_spacing)
	floor_mesh_instance.mesh = floor_plane

	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color(1.0, 0.2, 0.6, 0.9)
	floor_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	floor_mesh_instance.material_override = floor_material
	floor_container.add_child(floor_mesh_instance)

	# --- Collision for the floor ---
	var floor_collision := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = floor_plane.size 
	floor_collision.shape = floor_shape
	floor_container.add_child(floor_collision)

	var tunnel_gap_x = left_x + tunnel_pos * bar_width + (gap_size * bar_width * 0.5)
	floor_container.transform.origin = Vector3(
		tunnel_gap_x - bar_width * 0.5,
		ground_y - 0.1,
		z_offset
	)

	row_container.add_child(floor_mesh_instance)

	# --- Decorations at road edges (every 4th row) ---
	row_counter += 1
	if row_counter % 4 == 0 and not decorations.is_empty():
		var palm_left : Node3D = decorations.pick_random().instantiate()
		var left_edge_x = left_x + tunnel_pos * bar_width
		palm_left.transform.origin = Vector3(left_edge_x + 2.0, ground_y, z_offset)
		row_container.add_child(palm_left)

		var palm_right : Node3D = decorations.pick_random().instantiate()
		var right_edge_x = left_x + (tunnel_pos + gap_size) * bar_width
		palm_right.transform.origin = Vector3(right_edge_x - 2.0, ground_y, z_offset)
		row_container.add_child(palm_right)
		
	# --- Sun behind the gap ---
	if sun == null and sun_scene:
		sun = sun_scene.instantiate()
		add_child(sun)
		sun.scale = Vector3(30, 30, 1)

	if sun:
		var sun_x = tunnel_gap_x
		var sun_y = ground_y + sun.scale.y * 0.4
		var sun_z = z_offset - row_spacing * 500
		sun.transform.origin = Vector3(sun_x, sun_y, sun_z)
		
	# --- Disks every 15th row ---
	if current_row % 15 == 0:  
		for i in range(disks_per_gap):
			var disk = disk_scene.instantiate()
			row_container.add_child(disk)
			active_disks.append(disk)

			# keep only latest max_disks
			if active_disks.size() > max_disks:
				var old_disk = active_disks.pop_front()
				if is_instance_valid(old_disk):
					old_disk.queue_free()

			var offset_x = randf_range(-gap_size * 0.4, gap_size * 0.4) * bar_width
			var offset_y = ground_y + 1.5
			var offset_z = z_offset + (i * 3.0)
			disk.transform.origin = Vector3(tunnel_gap_x + offset_x, offset_y, offset_z)
			
	# --- Casette (once ~30% into level) ---
	if not casette_spawned and current_row > int(frames.size() * 0.3):
		var casette = casette_scene.instantiate()
		row_container.add_child(casette)

		var casette_x = randf_range(-gap_size * 0.4, gap_size * 0.4) * bar_width
		var casette_y = ground_y + 1.5
		var casette_z = z_offset - row_spacing * 5
		casette.transform.origin = Vector3(tunnel_gap_x + casette_x, casette_y, casette_z)
		casette_spawned = true
		
	return row_container
