extends Node3D

@export var num_bars: int = 16
@export var width: float = 3.0        # total width across the car roof
@export var height_scale: float = 1.0
@export var floor_height: float = 0.2 # minimum bar height
@export var smooth: float = 0.2       # smoothing factor

var _bars: Array[MeshInstance3D] = []
var _values: Array[float] = []
var _spectrum: AudioEffectSpectrumAnalyzerInstance
var _freqs: Array[float] = []

func _ready() -> void:
	# --- setup spectrum analyzer instance ---
	var bus := AudioServer.get_bus_index("Music") # make sure bus is named Music
	if bus == -1:
		push_warning("⚠️ Music bus not found! Add it in the Audio panel.")
		return

	_spectrum = AudioServer.get_bus_effect_instance(bus, 0) as AudioEffectSpectrumAnalyzerInstance
	if not _spectrum:
		push_warning("⚠️ No SpectrumAnalyzer effect on Music bus!")
		return

	# --- logarithmic frequency bands (20Hz–20kHz) ---
	_freqs.clear()
	var f_min := 20.0
	var f_max := 20000.0
	for i in range(num_bars + 1):
		var t := float(i) / float(num_bars)
		var freq := f_min * pow(f_max / f_min, t)
		_freqs.append(freq)

	# --- create bars ---
	_values.resize(num_bars)
	var bar_spacing := width / num_bars
	var start_x := -width * 0.5

	for i in range(num_bars):
		var bar := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(bar_spacing * 0.8, floor_height, 0.2) # box: thinner z
		bar.mesh = mesh

		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 0.6, 1.0)
		mat.emission_enabled = true
		mat.emission = Color(0.2, 0.6, 1.0)
		bar.material_override = mat

		bar.transform.origin = Vector3(start_x + i * bar_spacing, floor_height * 0.5, 0.0)
		add_child(bar)
		_bars.append(bar)
		_values[i] = floor_height


func _process(delta: float) -> void:
	if not _spectrum:
		return

	var rate := AudioServer.get_mix_rate()

	for i in range(num_bars):
		var f1 := _freqs[i]
		var f2 := _freqs[i + 1]
		var mag := _spectrum.get_magnitude_for_frequency_range(
	f1, f2,
	AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_AVERAGE
)

		var lin := mag.length() # 0..1-ish

		# convert to dB for nicer scaling
		var db := linear_to_db(max(lin, 1e-6))
		var norm: float = clamp(inverse_lerp(-60.0, 0.0, db), 0.0, 1.0)

		# smooth
		_values[i] = lerpf(_values[i], norm, smooth)

		# scale height
		var h: float = max(floor_height, _values[i] * height_scale)
		var bar := _bars[i]
		bar.scale.y = h / floor_height

		# stick to roof
		var t := bar.transform
		t.origin.y = h * 0.5
		bar.transform = t

		# update color (low energy = blue, high energy = pink)
		var col := Color(0.2, 0.6, 1.0).lerp(Color(1.0, 0.2, 0.6), _values[i])
		var mat := bar.material_override as StandardMaterial3D
		mat.albedo_color = col
		mat.emission = col
