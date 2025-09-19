extends Node3D

# === EXPORTS ===
@export var decorations: Array[PackedScene] = [
	preload("res://Decorations/palm.tscn")
]
@export var road_width: float = 10.0
@export var spacing: float = 10.0
@export var offset_z: float = 5.0

# sun
@export var sun_scene: PackedScene = preload("res://Decorations/Sun.tscn")
var sun: Node3D = null

# store
@export var store_scene: PackedScene = preload("res://Decorations/Store.tscn")
var store_spawned := false

# music disks and cassette
@export var disk_scene: PackedScene = preload("res://Decorations/MusicDisc.tscn")
@export var casette_scene: PackedScene = preload("res://Scenes/casette.tscn")
@export var disks_per_gap: int = 3
var casette_spawned = false

# === CONFIG ===
@export var freq_bins: int = 64
@export var height_scale: float = 100.0       # magnitude
@export var ground_y: float = -1.0           # Y = baseline (height axis)

@export var row_spacing: float = 1.2         # Z step between rows (time axis)
@export var step_time: float = 0.08
@export var max_rows: int = 200

@export var gap_size: int = 3
@export var max_disks: int = 10

# === RUNTIME ===
var current_row: int = 0
var z_offset: float = 10.0                   # Z position of current row
var tunnel_pos: int = 35
var row_counter: int = 0
var timer: Timer

# store pairs [mesh_instance, values]
var active_mesh_rows: Array = []
var active_disks: Array[Node3D] = []

var global_floor: CollisionShape3D

# --- Spectrum ---
var spectrum: AudioEffectSpectrumAnalyzerInstance
var player: AudioStreamPlayer3D


func _ready() -> void:
	# Spectrum on "Music" bus (ensure your AudioStreamPlayer3D routes to Music)
	var idx = AudioServer.get_bus_index("Music")
	var eff = AudioServer.get_bus_effect(idx, 0) as AudioEffectSpectrumAnalyzer
	if eff:
		spectrum = AudioServer.get_bus_effect_instance(idx, 0) as AudioEffectSpectrumAnalyzerInstance
	else:
		push_error("No SpectrumAnalyzer effect found on Music bus!")
	
	_create_global_floor()

	timer = Timer.new()
	timer.wait_time = step_time
	timer.one_shot = false
	add_child(timer)
	timer.timeout.connect(_on_tick)
	timer.start()

	var audio_path: String = Global.current_level["audio_path"]
	if audio_path != "" and FileAccess.file_exists(audio_path):
		var car: Node = get_tree().root.get_node("Main/Car")
		if car and car.has_node("AudioStreamPlayer3D"):
			player = car.get_node("AudioStreamPlayer3D")
			player.stream = load(audio_path)
			player.play()
	else:
		push_warning("No audio file for: %s" % audio_path)


func _create_global_floor():
	var floor_body := StaticBody3D.new()
	add_child(floor_body)

	global_floor = CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	# super wide X, thin Y, spans visible Z
	floor_shape.size = Vector3(9999.0, 0.2, max_rows * row_spacing)
	global_floor.shape = floor_shape
	floor_body.add_child(global_floor)
	floor_body.transform.origin = Vector3(0, ground_y - 0.1, 0)


func _update_global_floor():
	if not global_floor:
		return
	var shape := global_floor.shape as BoxShape3D
	shape.size.z = max_rows * row_spacing

	# center under current visible rows
	var start_z = z_offset
	var end_z = z_offset + (max_rows * row_spacing)
	var center_z = (start_z + end_z) * 0.5
	global_floor.transform.origin.z = center_z


func _on_tick() -> void:
	if spectrum == null:
		return

	# stop when music ends
	if player and not player.playing:
		timer.stop()
		print("Music finished – stopping level.")
		if not store_spawned and store_scene:
			var store = store_scene.instantiate()
			add_child(store)
			store.transform.origin = Vector3(0, ground_y, z_offset - row_spacing)
			store_spawned = true
		return

	# collect spectrum up to 4000 Hz
	var values: Array[float] = []
	var min_hz = 20.0
	var max_hz = 4000.0
	for i in range(freq_bins):
		var f0 = lerp(min_hz, max_hz, float(i) / float(freq_bins))
		var f1 = lerp(min_hz, max_hz, float(i + 1) / float(freq_bins))
		var mag = spectrum.get_magnitude_for_frequency_range(f0, f1).length()
		values.append(mag)

	# previous row values (for full cell fill)
	var prev_values: Array = []
	if active_mesh_rows.size() > 0:
		prev_values = active_mesh_rows.back()[1]

	var row_mesh_instance = _spawn_mesh_row(values, prev_values)
	if row_mesh_instance:
		active_mesh_rows.append([row_mesh_instance, values])
		if active_mesh_rows.size() > max_rows:
			var old = active_mesh_rows.pop_front()
			if is_instance_valid(old[0]):
				old[0].queue_free()

	current_row += 1
	z_offset -= row_spacing
	_update_global_floor()


func _spawn_mesh_row(values: Array, prev_values: Array) -> MeshInstance3D:
	# X = frequency, Y = height, Z = time (row)
	var left_x := -(freq_bins * 1.0) * 0.5

	# Build one ArrayMesh with two surfaces:
	#  - Surface 0: TRIANGLES (solid black fill, cull disabled)
	#  - Surface 1: LINES (emissive purple outlines)
	var am := ArrayMesh.new()

	# ---------- Surface 0: black fill (full grid + skirts) ----------
	var st_tri := SurfaceTool.new()
	st_tri.begin(Mesh.PRIMITIVE_TRIANGLES)
	var black_col = Color(0, 0, 0, 1)

	var z_cur := z_offset
	var have_prev := prev_values.size() == values.size()
	var z_prev := z_cur + row_spacing

	# A) FULL TOP SURFACE BETWEEN ROWS (no holes): for each cell (i, i+1) × (prev, current)
	if have_prev:
		for i in range(values.size() - 1):
			# heights
			var y_cur_i    = ground_y + values[i] * height_scale
			var y_cur_ip1  = ground_y + values[i + 1] * height_scale
			var y_prev_i   = ground_y + prev_values[i] * height_scale
			var y_prev_ip1 = ground_y + prev_values[i + 1] * height_scale

			# positions
			var x_i   = left_x + i
			var x_ip1 = left_x + i + 1

			# four corners of the cell (top surface)
			var v00 = Vector3(x_i,   y_cur_i,    z_cur)  # current row, i
			var v10 = Vector3(x_ip1, y_cur_ip1,  z_cur)  # current row, i+1
			var v01 = Vector3(x_i,   y_prev_i,   z_prev) # prev row, i
			var v11 = Vector3(x_ip1, y_prev_ip1, z_prev) # prev row, i+1

			# two triangles to cover the cell completely
			st_tri.set_color(black_col)
			st_tri.add_vertex(v00)
			st_tri.add_vertex(v10)
			st_tri.add_vertex(v01)

			st_tri.set_color(black_col)
			st_tri.add_vertex(v10)
			st_tri.add_vertex(v11)
			st_tri.add_vertex(v01)
	else:
		# first row: add a strip (current row → ground) so front is closed
		for i in range(values.size() - 1):
			var x0 = left_x + i
			var x1 = left_x + i + 1
			var y0 = ground_y + values[i] * height_scale
			var y1 = ground_y + values[i + 1] * height_scale

			var v0 = Vector3(x0, y0, z_cur)
			var v1 = Vector3(x1, y1, z_cur)
			var v2 = Vector3(x0, ground_y, z_cur)
			var v3 = Vector3(x1, ground_y, z_cur)

			st_tri.set_color(black_col)
			st_tri.add_vertex(v0)
			st_tri.add_vertex(v1)
			st_tri.add_vertex(v2)

			st_tri.set_color(black_col)
			st_tri.add_vertex(v1)
			st_tri.add_vertex(v3)
			st_tri.add_vertex(v2)

	# B) FRONT SKIRT (always): current row top → ground (closes front edge)
	for i in range(values.size() - 1):
		var x0f = left_x + i
		var x1f = left_x + i + 1
		var y0f = ground_y + values[i] * height_scale
		var y1f = ground_y + values[i + 1] * height_scale

		var a0 = Vector3(x0f, y0f, z_cur)
		var a1 = Vector3(x1f, y1f, z_cur)
		var b0 = Vector3(x0f, ground_y, z_cur)
		var b1 = Vector3(x1f, ground_y, z_cur)

		st_tri.set_color(black_col)
		st_tri.add_vertex(a0)
		st_tri.add_vertex(a1)
		st_tri.add_vertex(b0)

		st_tri.set_color(black_col)
		st_tri.add_vertex(a1)
		st_tri.add_vertex(b1)
		st_tri.add_vertex(b0)

	# C) SIDE SKIRTS (left & right): edges → ground across the Z span (prev to current)
	if have_prev:
		# Left edge (i = 0)
		var xl = left_x
		var yl_cur = ground_y + values[0] * height_scale
		var yl_prev = ground_y + prev_values[0] * height_scale

		var l00 = Vector3(xl, yl_cur,  z_cur)
		var l01 = Vector3(xl, yl_prev, z_prev)
		var l10 = Vector3(xl, ground_y, z_cur)
		var l11 = Vector3(xl, ground_y, z_prev)

		st_tri.set_color(black_col)
		st_tri.add_vertex(l00)
		st_tri.add_vertex(l01)
		st_tri.add_vertex(l10)

		st_tri.set_color(black_col)
		st_tri.add_vertex(l01)
		st_tri.add_vertex(l11)
		st_tri.add_vertex(l10)

		# Right edge (i = freq_bins - 1)
		var xr = left_x + (values.size() - 1)
		var yr_cur = ground_y + values[values.size() - 1] * height_scale
		var yr_prev = ground_y + prev_values[prev_values.size() - 1] * height_scale

		var r00 = Vector3(xr, yr_cur,  z_cur)
		var r01 = Vector3(xr, yr_prev, z_prev)
		var r10 = Vector3(xr, ground_y, z_cur)
		var r11 = Vector3(xr, ground_y, z_prev)

		st_tri.set_color(black_col)
		st_tri.add_vertex(r00)
		st_tri.add_vertex(r01)
		st_tri.add_vertex(r10)

		st_tri.set_color(black_col)
		st_tri.add_vertex(r01)
		st_tri.add_vertex(r11)
		st_tri.add_vertex(r10)

	st_tri.commit(am)

	# ---------- Surface 1: purple grid lines (X within row, Z between rows) ----------
	var st_lines = SurfaceTool.new()
	st_lines.begin(Mesh.PRIMITIVE_LINES)

	# X-axis lines (current row top edge)
	for i in range(values.size() - 1):
		var x0 = left_x + i
		var x1 = left_x + i + 1
		var y0 = ground_y + values[i] * height_scale
		var y1 = ground_y + values[i + 1] * height_scale
		var z  = z_cur
		st_lines.add_vertex(Vector3(x0, y0, z))
		st_lines.add_vertex(Vector3(x1, y1, z))

	# Z-axis lines (to previous row)
	if have_prev:
		for i in range(values.size()):
			var x = left_x + i
			var y_now  = ground_y + values[i] * height_scale
			var y_prev = ground_y + prev_values[i] * height_scale
			st_lines.add_vertex(Vector3(x, y_now,  z_cur))
			st_lines.add_vertex(Vector3(x, y_prev, z_prev))

	st_lines.commit(am)

	# Instance + per-surface materials
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = am

	# Surface 0 (fill): solid black, unshaded, cull disabled (visible from any angle)
	var fill_mat := StandardMaterial3D.new()
	fill_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fill_mat.albedo_color = Color(0, 0, 0, 1)
	fill_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh_instance.set_surface_override_material(0, fill_mat)

	# Surface 1 (lines): emissive purple
	var line_mat := StandardMaterial3D.new()
	line_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	line_mat.emission_enabled = true
	line_mat.emission = Color(0.8, 0.2, 1.0, 1.0)
	line_mat.emission_energy_multiplier = 1.5
	mesh_instance.set_surface_override_material(1, line_mat)

	add_child(mesh_instance)

	# Decorations etc (unchanged)
	row_counter += 1
	if row_counter % 20 == 0 and not decorations.is_empty():
		var palm_left : Node3D = decorations.pick_random().instantiate()
		palm_left.transform.origin = Vector3(left_x, ground_y, z_offset)
		mesh_instance.add_child(palm_left)

	if sun == null and sun_scene:
		sun = sun_scene.instantiate()
		add_child(sun)
		sun.scale = Vector3(30, 30, 1)
	if sun:
		var sun_x = 0
		var sun_y = ground_y + sun.scale.y * 0.4
		var sun_z = z_offset - row_spacing * 500
		sun.transform.origin = Vector3(sun_x, sun_y, sun_z)

	if current_row % 30 == 0:
		for i in range(disks_per_gap):
			var disk = disk_scene.instantiate()
			mesh_instance.add_child(disk)
			active_disks.append(disk)
			if active_disks.size() > max_disks:
				var old_disk = active_disks.pop_front()
				if is_instance_valid(old_disk):
					old_disk.queue_free()
			disk.transform.origin = Vector3(randf_range(-5,5), ground_y + 1.5, z_offset + (i * 2))

	if not casette_spawned and current_row > 100:
		var casette = casette_scene.instantiate()
		mesh_instance.add_child(casette)
		casette.transform.origin = Vector3(0, ground_y + 1.5, z_offset - 10)
		casette_spawned = true

	return mesh_instance
