extends Node3D

# === CONFIG ===
@export var bar_width: float = 10.0
@export var row_spacing: float = 11.0
@export var height_scale: float = 100.0
@export var ground_y: float = 0.0
@export var step_time: float = 0.8
@export var gap_size: int = 3

# === RUNTIME ===
var frames: Array = []
var bands: int = 0
var current_row: int = 0
var z_offset: float = 0.0
var tunnel_pos: int = 20
var timer: Timer

func _ready() -> void:
	randomize()
	_load_json(Global.current_level["json_path"])
	if frames.is_empty():
		push_error("❌ No frames in JSON: %s" % Global.current_level["json_path"])
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
			print("🎵 Playing %s on car" % audio_path)
		else:
			push_warning("⚠ Car or AudioStreamPlayer3D not found in scene!")
	else:
		push_warning("⚠ No audio found for: %s" % audio_path)


func _load_json(path: String) -> void:
	if path == "" or not FileAccess.file_exists(path):
		return
	var f := FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	frames = data.get("frames", [])
	bands = data.get("bands", 0)
	if bands == 0 and frames.size() > 0:
		bands = frames[0].size()
	print("✅ Loaded %d frames, %d bands" % [frames.size(), bands])


func _on_tick() -> void:
	if current_row >= frames.size():
		timer.stop()
		print("✅ Finished spawning spectrum")
		return

	_spawn_row(frames[current_row])
	current_row += 1
	z_offset -= row_spacing


func _spawn_row(values: Array) -> void:
	var left_x := -(bands * bar_width) * 0.5

	# --- Tunnel shifting (max ±1, 25% chance) ---
	if randi() % 100 < 25:
		tunnel_pos += randi_range(-1, 1)
		tunnel_pos = clamp(tunnel_pos, 1, bands - gap_size - 1)

	# --- Spawn bars ---
	for i in range(bands):
		if i >= tunnel_pos and i < tunnel_pos + gap_size:
			continue

		var h: float = float(values[i]) * height_scale
		h = max(h, 1.0)

		var bar := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(bar_width, 1.0, row_spacing)
		bar.mesh = mesh

		# material
		var mat := StandardMaterial3D.new()
		var t: float = clamp(h / (height_scale * 0.8), 0.0, 1.0)
		var low := Color(0.2, 0.4, 1.0, 0.95)
		var high := Color(0.8, 0.2, 1.0, 0.95)
		var col := low.lerp(high, t)
		mat.albedo_color = col
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.emission_enabled = true
		mat.emission = col
		mat.emission_energy_multiplier = 1.2
		bar.material_override = mat

		bar.transform.origin = Vector3(
			left_x + i * bar_width,
			ground_y + h * 0.5,
			z_offset
		)
		bar.scale = Vector3(1.0, h, 1.0)

		add_child(bar)

	# --- Pink floor strip under the tunnel ---
	var floor := MeshInstance3D.new()
	var plane := BoxMesh.new()
	plane.size = Vector3(gap_size * bar_width, 0.2, row_spacing)
	floor.mesh = plane

	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(1.0, 0.2, 0.6, 0.9)
	floor_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	floor.material_override = floor_mat

	var gap_x = left_x + tunnel_pos * bar_width + (gap_size * bar_width * 0.5)
	floor.transform.origin = Vector3(
		gap_x - bar_width * 0.5,
		ground_y - 0.1,
		z_offset
	)

	add_child(floor)
