extends Node3D

@export var point_count: int = 128
@export var base_radius: float = 5.0
@export var magnitude_boost: float = 15.0
@export var low_cut_hz: float = 200.0
@export var high_cut_hz: float = 12000.0

# --- Color mapping controls ---
@export var low_color: Color = Color(0.2, 0.2, 1.0)   # quiet
@export var high_color: Color = Color(1.0, 0.2, 0.2)  # loud
@export var db_min: float = -80.0    # dB value that maps to low_color (increase magnitude = moves toward high_color)
@export var db_max: float = -20.0    # dB value that maps to high_color (set lower if it still saturates)
@export var color_gamma: float = 1.2 # >1.0 compresses highs a bit; try 1.0–2.0
@export var smooth: float = 0.2      # 0..1 smoothing of magnitudes

var _values: PackedFloat32Array = []  # store smoothed magnitudes for half the ring
var _spectrum: AudioEffectSpectrumAnalyzerInstance
var _mesh_instance: MeshInstance3D
var _mesh: ImmediateMesh

func _ready() -> void:
	_mesh_instance = $WaveMesh as MeshInstance3D
	_mesh = ImmediateMesh.new()
	_mesh_instance.mesh = _mesh

	# Ensure vertex colors are visible (VERY IMPORTANT)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	_mesh_instance.material_override = mat

	_values.resize(max(1, point_count / 2))
	for i in _values.size():
		_values[i] = 0.0

	_setup_spectrum()

func _setup_spectrum() -> void:
	var bus_index: int = AudioServer.get_bus_index("Music")
	if bus_index == -1:
		push_warning("Music bus not found.")
		return
	var effect: AudioEffectInstance = AudioServer.get_bus_effect_instance(bus_index, 0)
	_spectrum = effect as AudioEffectSpectrumAnalyzerInstance
	if _spectrum == null:
		push_warning("SpectrumAnalyzer not found on Music bus effect slot 0.")

func _process(delta: float) -> void:
	if _spectrum == null:
		return

	var half_points := _values.size()
	if half_points <= 1:
		return

	var right_pts: Array[Vector3] = []
	var right_vals: Array[float] = []

	# Build right half, compute mags & colors there
	for i in range(half_points):
		var t: float = float(i) / float(half_points - 1)
		var freq: float = low_cut_hz * pow(high_cut_hz / low_cut_hz, t)

		var mag: Vector2 = _spectrum.get_magnitude_for_frequency_range(
			freq, freq + 100.0, AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_AVERAGE
		)

		# Convert to dB, map to 0..1 using tunable range
		var db: float = linear_to_db(max(mag.length(), 1e-6))
		var norm: float = (db - db_min) / max(0.0001, (db_max - db_min))
		norm = clamp(norm, 0.0, 1.0)

		# Optional gamma to reduce "always high"
		if color_gamma != 1.0:
			norm = pow(norm, color_gamma)

		# Smooth for stability
		_values[i] = lerpf(_values[i], norm, smooth)

		# Geometry
		var angle: float = lerp(PI/2.0, 3.0*PI/2.0, t)
		var radius: float = base_radius + _values[i] * magnitude_boost
		var x: float = cos(angle) * radius
		var y: float = sin(angle) * radius

		right_pts.append(Vector3(x, y, 0))
		right_vals.append(_values[i])

	# Mirror to left side (copy values so color matches)
	var left_pts: Array[Vector3] = []
	var left_vals: Array[float] = []
	for i in range(half_points - 1, -1, -1):
		var p = right_pts[i]
		left_pts.append(Vector3(-p.x, p.y, 0))
		left_vals.append(right_vals[i])

	var points: Array[Vector3] = right_pts + left_pts
	var vals: Array[float] = right_vals + left_vals

	# Draw
	_mesh.clear_surfaces()
	_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

	for j in range(points.size()):
		var col := low_color.lerp(high_color, vals[j])
		_mesh.surface_set_color(col)
		_mesh.surface_add_vertex(points[j])

	# Close loop
	if points.size() > 0:
		var col0 := low_color.lerp(high_color, vals[0])
		_mesh.surface_set_color(col0)
		_mesh.surface_add_vertex(points[0])

	_mesh.surface_end()
