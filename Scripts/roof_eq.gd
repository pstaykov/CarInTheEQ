extends Node3D

@export var num_bars: int = 16
@export var width: float = 3.0
@export var height_scale: float = 1.0
@export var floor_height: float = 0.2
@export var smooth: float = 0.2

var _bars: Array[MeshInstance3D] = []
var _values: Array[float] = []
var _spectrum: AudioEffectSpectrumAnalyzerInstance
var _freqs: Array[float] = []

func _ready() -> void:
	var bus: int = AudioServer.get_bus_index("Music")
	if bus == -1:
		push_warning("⚠️ Music bus not found! Add it in the Audio panel.")
		return
	print("✅ Music bus found at index:", bus)

	var effect: AudioEffectInstance = AudioServer.get_bus_effect_instance(bus, 0)
	_spectrum = effect as AudioEffectSpectrumAnalyzerInstance
	if _spectrum == null:
		push_warning("⚠️ No SpectrumAnalyzer effect on Music bus!")
		return
	print("✅ SpectrumAnalyzer found and assigned.")

	var f_min: float = 20.0
	var f_max: float = 20000.0
	for i in range(num_bars + 1):
		var t: float = float(i) / float(num_bars)
		var freq: float = f_min * pow(f_max / f_min, t)
		_freqs.append(freq)

	_values.resize(num_bars)
	var bar_spacing: float = width / num_bars
	var start_x: float = -width * 0.5

	for i in range(num_bars):
		var bar: MeshInstance3D = MeshInstance3D.new()
		var mesh: BoxMesh = BoxMesh.new()
		mesh.size = Vector3(bar_spacing * 0.8, floor_height, 0.2)
		bar.mesh = mesh

		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 0.6, 1.0)
		mat.emission_enabled = true
		mat.emission = Color(0.2, 0.6, 1.0)
		bar.material_override = mat

		bar.transform.origin = Vector3(start_x + i * bar_spacing, floor_height * 0.5, 0.0)
		add_child(bar)
		_bars.append(bar)
		_values[i] = floor_height

	print("✅ EQ bars created:", _bars.size())

func _process(_delta: float) -> void:
	if _spectrum == null:
		return

	for i in range(num_bars):
		var f1: float = _freqs[i]
		var f2: float = _freqs[i + 1]
		var mag: Vector2 = _spectrum.get_magnitude_for_frequency_range(f1, f2, AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_AVERAGE)

		var lin: float = mag.length()
		var db: float = linear_to_db(max(lin, 1e-6))
		var norm: float = clamp(inverse_lerp(-60.0, 0.0, db), 0.0, 1.0)

		_values[i] = lerpf(_values[i], norm, smooth)

		var h: float = max(floor_height, _values[i] * height_scale)
		var bar: MeshInstance3D = _bars[i]
		bar.scale.y = h / floor_height

		var t: Transform3D = bar.transform
		t.origin.y = h * 0.5
		bar.transform = t

		var col: Color = Color(0.2, 0.6, 1.0).lerp(Color(1.0, 0.2, 0.6), _values[i])
		var mat: StandardMaterial3D = bar.material_override as StandardMaterial3D
		mat.albedo_color = col
		mat.emission = col

		# 🔍 Debug output
		print("Bar", i, "Freq:", f1, "-", f2, "Mag:", mag, "Norm:", norm, "Height:", h)
