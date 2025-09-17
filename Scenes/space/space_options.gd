extends CanvasLayer

@export var spawner_path: NodePath  # drag RingSpawner here

# Spawner controls
@onready var seconds_spin: SpinBox = $Panel/TabContainer/SpawnerSettings/SecondsPerRingSpin
@onready var spacing_spin: SpinBox = $Panel/TabContainer/SpawnerSettings/RingSpacingSpin
@onready var jitter_x_spin: SpinBox = $Panel/TabContainer/SpawnerSettings/JitterXSpin
@onready var jitter_y_spin: SpinBox = $Panel/TabContainer/SpawnerSettings/JitterYSpin
@onready var offset_x_spin: SpinBox = $Panel/TabContainer/SpawnerSettings/MaxOffsetXSpin
@onready var offset_y_spin: SpinBox = $Panel/TabContainer/SpawnerSettings/MaxOffsetYSpin
@onready var apply_button: Button = $Panel/TabContainer/SpawnerSettings/ApplyButton

# Audio controls
@onready var output_device_option: OptionButton = $Panel/TabContainer/AudioSettings/OutputDeviceOption
@onready var volume_slider: HSlider = $Panel/TabContainer/AudioSettings/Volume/HSlider

var spawner

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	spawner = get_node_or_null(spawner_path)

	# Fill spawner controls
	if spawner:
		seconds_spin.value = spawner.seconds_per_ring
		spacing_spin.value = spawner.ring_spacing
		jitter_x_spin.value = spawner.step_jitter_x
		jitter_y_spin.value = spawner.step_jitter_y
		offset_x_spin.value = spawner.max_offset_x
		offset_y_spin.value = spawner.max_offset_y

	apply_button.pressed.connect(_on_apply_pressed)

	# Fill audio device list
	_populate_audio_devices()
	output_device_option.item_selected.connect(_on_audio_device_selected)

	# Setup volume slider
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.01
	volume_slider.value = Global.master_volume
	volume_slider.value_changed.connect(_on_volume_changed)

	# Apply initial volume
	_on_volume_changed(volume_slider.value)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if visible:
			_resume_game()
		else:
			_pause_game()

func _pause_game() -> void:
	visible = true
	get_tree().paused = true

func _resume_game() -> void:
	visible = false
	get_tree().paused = false

# --- Spawner Apply
func _on_apply_pressed() -> void:
	if not spawner:
		return
	spawner.seconds_per_ring = seconds_spin.value
	spawner.ring_spacing = spacing_spin.value
	spawner.step_jitter_x = jitter_x_spin.value
	spawner.step_jitter_y = jitter_y_spin.value
	spawner.max_offset_x = offset_x_spin.value
	spawner.max_offset_y = offset_y_spin.value
	print("Spawner settings updated!")

# --- Audio Devices
func _populate_audio_devices() -> void:
	output_device_option.clear()
	var devices = AudioServer.get_output_device_list()
	for i in range(devices.size()):
		output_device_option.add_item(devices[i])
	# Highlight current device
	var current = AudioServer.get_output_device()
	var idx = devices.find(current)
	if idx != -1:
		output_device_option.select(idx)

func _on_audio_device_selected(index: int) -> void:
	var device_name = output_device_option.get_item_text(index)
	AudioServer.set_output_device(device_name)
	print("Audio output switched to:", device_name)

# --- Volume
func _on_volume_changed(value: float) -> void:
	Global.master_volume = value
	# Music bus is usually called "Master" or "Music" → pick the one you route your audio to
	var bus_idx = AudioServer.get_bus_index("Master")
	if bus_idx >= 0:
		# Convert linear [0..1] to decibels
		var db = linear_to_db(clamp(value, 0.001, 1.0))
		AudioServer.set_bus_volume_db(bus_idx, db)
