extends Node3D

signal ring_passed

@export var point_count: int = 128
@export var base_radius: float = 5.0
@export var magnitude_boost: float = 15.0
@export var low_cut_hz: float = 200.0
@export var high_cut_hz: float = 12000.0

@export var low_color: Color = Color(0.2, 0.2, 1.0)
@export var high_color: Color = Color(1.0, 0.2, 0.2)
@export var db_min: float = -80.0
@export var db_max: float = -20.0
@export var color_gamma: float = 1.2
@export var smooth: float = 0.2

@export var collision_radius: float = 15.0
@export var collision_height: float = 2.0
@export var show_collision_mesh: bool = true

@onready var _mesh_instance: MeshInstance3D = $WaveMesh
@onready var _area: Area3D = $Area3D
@onready var _collision_shape: CollisionShape3D = $Area3D/CollisionShape3D
@onready var _debug_mesh_instance: MeshInstance3D = $Area3D/MeshInstance3D

var _values: PackedFloat32Array = []
var _spectrum: AudioEffectSpectrumAnalyzerInstance
var _mesh: ImmediateMesh

func _ready() -> void:
	# --- Visualiser mesh ---
	_mesh = ImmediateMesh.new()
	_mesh_instance.mesh = _mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	_mesh_instance.material_override = mat

	# init values
	_values.resize(max(1, point_count / 2))
	for i in _values.size():
		_values[i] = 0.0

	_setup_spectrum()

	# --- Collision shape (static cylinder) ---
	var cyl := CylinderShape3D.new()
	cyl.radius = collision_radius
	cyl.height = collision_height
	_collision_shape.shape = cyl

	# --- Debug mesh (same cylinder) ---
	if show_collision_mesh:
		var mesh := CylinderMesh.new()
		mesh.top_radius = collision_radius
		mesh.bottom_radius = collision_radius
		mesh.height = collision_height
		_debug_mesh_instance.mesh = mesh

		var dmat := StandardMaterial3D.new()
		dmat.albedo_color = Color(0, 1, 0, 0.3)  # semi-transparent green
		dmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_debug_mesh_instance.material_override = dmat
	else:
		_debug_mesh_instance.visible = false

	_area.body_entered.connect(_on_body_entered)

func _setup_spectrum() -> void:
	var bus_index = AudioServer.get_bus_index("Music")
	if bus_index == -1:
		push_warning("Music bus not found.")
		return
	var effect = AudioServer.get_bus_effect_instance(bus_index, 0)
	_spectrum = effect as AudioEffectSpectrumAnalyzerInstance
	if not _spectrum:
		push_warning("SpectrumAnalyzer not found on Music bus effect slot 0.")

func _process(delta: float) -> void:
	if not _spectrum:
		return

	var half_points = _values.size()
	if half_points <= 1:
		return

	var right_pts: Array[Vector3] = []
	var right_vals: Array[float] = []

	for i in range(half_points):
		var t: float = float(i) / float(half_points - 1)
		var freq: float = low_cut_hz * pow(high_cut_hz / low_cut_hz, t)
		var mag: Vector2 = _spectrum.get_magnitude_for_frequency_range(
			freq, freq + 100.0, AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_AVERAGE
		)

		var db: float = linear_to_db(max(mag.length(), 1e-6))
		var norm: float = (db - db_min) / max(0.0001, (db_max - db_min))
		norm = clamp(norm, 0.0, 1.0)
		if color_gamma != 1.0:
			norm = pow(norm, color_gamma)

		_values[i] = lerpf(_values[i], norm, smooth)

		var angle: float = lerp(PI/2.0, 3.0*PI/2.0, t)
		var radius: float = base_radius + _values[i] * magnitude_boost
		var x: float = cos(angle) * radius
		var y: float = sin(angle) * radius
		right_pts.append(Vector3(x, y, 0))
		right_vals.append(_values[i])

	var left_pts: Array[Vector3] = []
	var left_vals: Array[float] = []
	for i in range(half_points - 1, -1, -1):
		var p = right_pts[i]
		left_pts.append(Vector3(-p.x, p.y, 0))
		left_vals.append(right_vals[i])

	var points: Array[Vector3] = right_pts + left_pts
	var vals: Array[float] = right_vals + left_vals

	_mesh.clear_surfaces()
	_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for j in range(points.size()):
		var col := low_color.lerp(high_color, vals[j])
		_mesh.surface_set_color(col)
		_mesh.surface_add_vertex(points[j])
	if points.size() > 0:
		var col0 := low_color.lerp(high_color, vals[0])
		_mesh.surface_set_color(col0)
		_mesh.surface_add_vertex(points[0])
	_mesh.surface_end()

func _on_body_entered(body: Node) -> void:
	print("Something entered:", body.name)
	Global.SpaceRings += 1
	print("Ring passed! Total =", Global.SpaceRings)
