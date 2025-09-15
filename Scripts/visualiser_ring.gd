extends Node3D

@export var point_count: int = 128
@export var base_radius: float = 5.0
@export var magnitude_boost: float = 15.0
@export var low_cut_hz: float = 200.0
@export var high_cut_hz: float = 12000.0

var _values: Array[float] = []
var _spectrum: AudioEffectSpectrumAnalyzerInstance
var _mesh_instance: MeshInstance3D
var _mesh: ImmediateMesh

func _ready() -> void:
	_mesh_instance = $WaveMesh as MeshInstance3D
	_mesh = ImmediateMesh.new()
	_mesh_instance.mesh = _mesh
	_values.resize(point_count)
	_setup_spectrum()

func _setup_spectrum() -> void:
	var bus_index: int = AudioServer.get_bus_index("Music")
	if bus_index == -1:
		push_warning("Music bus not found.")
		return
	var effect: AudioEffectInstance = AudioServer.get_bus_effect_instance(bus_index, 0) 
	_spectrum = effect as AudioEffectSpectrumAnalyzerInstance
	if _spectrum == null:
		push_warning("SpectrumAnalyzer not found.")

func _process(delta: float) -> void:
	if _spectrum == null:
		return

	var half_points: int = point_count / 2
	var right_side: Array[Vector3] = []
	var left_side: Array[Vector3] = []

	for i in range(half_points):
		var t: float = float(i) / float(half_points - 1)
		var freq: float = low_cut_hz * pow(high_cut_hz / low_cut_hz, t)
		var mag: Vector2 = _spectrum.get_magnitude_for_frequency_range(
			freq, freq + 100.0, AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_AVERAGE
		)
		var db: float = linear_to_db(max(mag.length(), 1e-6))
		var norm: float = clamp(inverse_lerp(-60.0, 0.0, db), 0.0, 1.0)
		_values[i] = lerpf(_values[i], norm, 0.2)

		var angle: float = lerp(PI/2, 3*PI/2, t)
		var radius: float = base_radius + _values[i] * magnitude_boost
		var x: float = cos(angle) * radius
		var y: float = sin(angle) * radius
		right_side.append(Vector3(x, y, 0))

	for i in range(half_points - 1, -1, -1):
		var p = right_side[i]
		left_side.append(Vector3(-p.x, p.y, 0))

	var points: Array[Vector3] = right_side + left_side

	_mesh.clear_surfaces()
	_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for p in points:
		_mesh.surface_add_vertex(p)
	if points.size() > 0:
		_mesh.surface_add_vertex(points[0])
	_mesh.surface_end()
