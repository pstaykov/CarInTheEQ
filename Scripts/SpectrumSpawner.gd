extends Node3D

@export var json_path: String = "res://spectrum.json"
@export var timer_interval: float = 0.8          # 800ms per row (matches ~45 km/h @ 10m per box)
@export var band_width: float = 10.0             # size of each block in X/Z
@export var band_gap: float = 0.0                # no gaps between blocks
@export var row_spacing: float = 10.0            # same as band_width -> seamless rows
@export var height_scale: float = 100.0          # multiply spectrum height
@export var ground_y: float = 0.0                # baseline for blocks
@export var center_x: float = 0.0                # center alignment
@export var start_z: float = -20.0               # where first row spawns
@export var gap_size: int = 3                    # width of the tunnel in bars

var frames: Array = []
var bands: int = 0
var current_row: int = 0
var _timer: Timer
var last_gap_start: int = -1

func _ready() -> void:
	randomize()
	_load_json()
	if frames.is_empty():
		push_error("No frames found in JSON.")
		return
	_start_timer()
	print("SpectrumSpawner: loaded %d frames, bands=%d" % [frames.size(), bands])

func _load_json() -> void:
	var f := FileAccess.open(json_path, FileAccess.READ)
	if f == null:
		push_error("Cannot open JSON: %s" % json_path)
		return
	var text := f.get_as_text()
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("JSON parse failed.")
		return
	frames = data.get("frames", [])
	bands = int(data.get("bands", 0))
	if bands == 0 and frames.size() > 0:
		bands = frames[0].size()

func _start_timer() -> void:
	_timer = Timer.new()
	_timer.wait_time = timer_interval
	_timer.autostart = true
	_timer.one_shot = false
	add_child(_timer)
	_timer.timeout.connect(_on_tick)

func _on_tick() -> void:
	if current_row >= frames.size():
		_timer.stop()
		return
	_spawn_row(frames[current_row], current_row)
	current_row += 1

func _spawn_row(values: Array, row_index: int) -> void:
	var total_width := bands * band_width
	var left_x := center_x - total_width * 0.5
	var z := start_z - row_index * row_spacing

	# --- tunnel gap selection ---
	var gap_start: int
	if last_gap_start == -1:
		gap_start = 20  # first row always at band 20
	else:
		var offset_options = [-1, 0, 0, 0, 0, 1]  # smoother, only +/-1 at most
		var offset = offset_options[randi() % offset_options.size()]
		gap_start = clamp(last_gap_start + offset, 0, bands - gap_size)
	last_gap_start = gap_start

	# --- spawn bars ---
	for i in range(bands):
		if i >= gap_start and i < gap_start + gap_size:
			continue

		var h := float(values[i]) * height_scale
		h = max(h, 1.0)

		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(band_width, 1.0, band_width)
		mi.mesh = bm

		# === Color by magnitude ===
		var mat := StandardMaterial3D.new()
		var t = clamp(h / (height_scale * 0.8), 0.0, 1.0)  # normalize 0..1

		var low_color = Color(0.0, 0.0, 1.0, 0.98)   # blue
		var high_color = Color(0.5, 0.0, 0.5, 0.98)  # purple
		mat.albedo_color = low_color.lerp(high_color, t)

		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.flags_transparent = true
		mat.emission_enabled = true
		mat.emission = mat.albedo_color
		mat.emission_energy = 1.2

		mi.material_override = mat

		mi.transform.origin = Vector3(
			left_x + i * band_width,
			ground_y + h * 0.5,
			z
		)
		mi.scale = Vector3(1.0, h, 1.0)

		add_child(mi)

	# --- add pink floor under the tunnel gap ---
	var floor = MeshInstance3D.new()
	var plane = BoxMesh.new()
	plane.size = Vector3(gap_size * band_width, 0.2, row_spacing)
	floor.mesh = plane

	var floor_mat = StandardMaterial3D.new()
	floor_mat.albedo_color = Color(1.0, 0.2, 0.6, 0.9) # pink, mostly opaque
	floor_mat.unshaded = true
	floor_mat.emission_enabled = true
	floor_mat.emission = floor_mat.albedo_color
	floor_mat.emission_energy = 1.5
	floor.material_override = floor_mat

	var gap_x = left_x + gap_start * band_width + (gap_size * band_width * 0.5)
	floor.transform.origin = Vector3(
		gap_x - band_width * 0.5,
		ground_y - 0.1,
		z
	)
	add_child(floor)
