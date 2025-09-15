extends Control

func _ready() -> void:
	$VBoxContainer/MainMenu.pressed.connect(_on_MainMenu_button_pressed)
	add_to_group("store_ui")


func _on_MainMenu_button_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/SongSelect.tscn")
