extends Control

func _ready():
	# Connect buttons to functions
	$"VBoxContainer/Start game".pressed.connect(_on_start_button_pressed)
	$VBoxContainer/Options.pressed.connect(_on_options_button_pressed)
	$VBoxContainer/Quit.pressed.connect(_on_quit_button_pressed)

func _on_start_button_pressed():
	get_tree().change_scene_to_file("res://main.tscn")

func _on_options_button_pressed():
	# You can make a new Options scene later
	print("Options clicked!")

func _on_quit_button_pressed():
	get_tree().quit()
