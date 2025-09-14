extends Control

@onready var volume_slider: HSlider = $VBoxContainer/VolumeSlider
@onready var back_button: Button = $VBoxContainer/back 

func _ready():
	# init slider value
	volume_slider.value = Global.master_volume
	volume_slider.value_changed.connect(_on_volume_changed)

	# connect back button
	back_button.pressed.connect(_on_back_button_pressed)

func _on_volume_changed(value: float) -> void:
	Global.master_volume = value
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Master"),
		linear_to_db(value)
	)

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/game_start.tscn") # adjust if needed
