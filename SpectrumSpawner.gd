extends Node3D

@export var json_path: String = "res://spectrum.json"
@export var timer_interval: float = 0.2         # 200 ms, matches your JSON step_ms
@export var row_spacing: float = 4.0            # distance between rows along -Z
@export var band_width: float = 0.5             # X/Z footprint of each box
@export var band_gap: float = 0.1               # gap between boxes along X
@export var height_scale: float = 10.0          # multiply the magnitude to get visible height
@export var ground_y: float = 0.0               # where boxes “sit”
@export var center_x: float = 0.0               # center line across X
@export var start_z: float = -5.0               # where first row is placed (in front of camera/car)

var frames: Array = []
var bands: int = 0
var current_row: int = 0
var _timer: Timer

func _ready() -> void:
	_load_json()
	if frames.is_empty():
		push_error("No frames found in JSON. Check json_path or file content.")
		return
	_start_timer()
	print("SpectrumSpawner: loaded %d frames, bands=%d" % [frames.size(), bands])

func _load_json() -> void:
	var f := FileAccess.open(json_path, FileAccess.READ)
	if f == null:
		push_error("Cannot open JSON path: %s" % json_path)
		return
	var text := f.get_as_text()
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("JSON parse failed for %s" % json_path)
		return
	frames = data.get("frames", [])
	bands = int(data.get("bands", 0))
	if bands == 0 and frames.size() > 0:
		bands = frames[0].size()  # fallback if not provided

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
		print("SpectrumSpawner: done spawning rows.")
		return
	_spawn_row(frames[current_row], current_row)
	current_row += 1

func _spawn_row(values: Array, row_index: int) -> void:
	# Compute the left edge so the row is centered around center_x
	var total_width := bands * (band_width + band_gap) - band_gap
	var left_x := center_x - total_width * 0.5
	var z := start_z - row_index * row_spacing

	for i in range(bands):
		var h := float(values[i]) * height_scale
		h = max(h, 0.02)  # avoid zero-height
		# Create a box
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(band_width, 1.0, band_width)  # Base unit height = 1, we scale Y
		mi.mesh = bm

		# Simple material with a hue gradient across bands
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color.from_hsv(float(i) / max(1, bands), 0.7, 0.9)
		mi.material_override = mat

		# Place it: raise by h*0.5 so it sits on ground_y
		mi.transform.origin = Vector3(left_x + i * (band_width + band_gap),
									  ground_y + h * 0.5,
									  z)
		mi.scale = Vector3(1.0, h, 1.0)
		add_child(mi)
