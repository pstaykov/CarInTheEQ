extends Control

func _ready():
	# Connect buttons to functions
	$"VBoxContainer/Start game".pressed.connect(_on_start_button_pressed)
	$VBoxContainer/Options.pressed.connect(_on_options_button_pressed)
	$VBoxContainer/Quit.pressed.connect(_on_quit_button_pressed)

func _on_start_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/SongSelect.tscn")

func _on_options_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/Options.tscn")

func _on_quit_button_pressed():
	get_tree().quit()
