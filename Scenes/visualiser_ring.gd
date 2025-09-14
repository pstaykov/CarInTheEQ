extends Node3D

@export var point_count: int = 128
@export var base_radius: float = 5.0
@export var magnitude_boost: float = 5.0
@export var wave_material: Material
@export var ring_scene: PackedScene
@export var ring_count: int = 50
@export var spacing: float = 5.0
@export var curve_strength: float = 3.0


var _values: Array[float] = []
var _spectrum: AudioEffectSpectrumAnalyzerInstance
var _mesh_instance: MeshInstance3D
var _mesh: ImmediateMesh

func _ready() -> void:
	_mesh_instance = $WaveMesh as MeshInstance3D
	_mesh = ImmediateMesh.new()
	_mesh_instance.mesh = _mesh
	_mesh_instance.material_override = wave_material
	_values.resize(point_count)
	_setup_spectrum()
	

func _setup_spectrum() -> void:
	var bus_index: int = AudioServer.get_bus_index("Music")
	if bus_index == -1:
		push_warning("Music bus not found.")
		return

	var effect: AudioEffectInstance = AudioServer.get_bus_effect_instance(bus_index, 0)
	var spectrum_effect: AudioEffectSpectrumAnalyzerInstance = effect as AudioEffectSpectrumAnalyzerInstance
	if spectrum_effect == null:
		push_warning("SpectrumAnalyzer not found.")
		return

	_spectrum = spectrum_effect

func _process(delta: float) -> void:
	if _spectrum == null:
		return

	var points: Array[Vector3] = []

	for i in range(point_count):
		var freq: float = 20.0 * pow(1000.0, float(i) / float(point_count))
		var mag: Vector2 = _spectrum.get_magnitude_for_frequency_range(freq, freq + 100.0, AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_AVERAGE)
		var db: float = linear_to_db(max(mag.length(), 1e-6))
		var norm: float = clamp(inverse_lerp(-60.0, 0.0, db), 0.0, 1.0)
		_values[i] = lerpf(_values[i], norm, 0.2)

		var angle: float = (float(i) / float(point_count)) * TAU
		var radius: float = base_radius + _values[i] * magnitude_boost
		var x: float = cos(angle) * radius
		var y: float = sin(angle) * radius
		points.append(Vector3(x, y, 0))

	_mesh.clear_surfaces()
	_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for p in points:
		_mesh.surface_add_vertex(p)
	_mesh.surface_add_vertex(points[0])  # Close the loop
	_mesh.surface_end()
