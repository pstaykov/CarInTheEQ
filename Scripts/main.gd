extends Node3D

@onready var pause_menu = $PauseGame/Panel
func _ready():
	$PauseGame/Panel/VBoxContainer/Continue.pressed.connect(_on_resume_button_pressed)
	$PauseGame/Panel/VBoxContainer/Restart.pressed.connect(_on_restart_button_pressed)
	$PauseGame/Panel/VBoxContainer/MainMenu.pressed.connect(_on_main_menu_button_pressed)
	$PauseGame/Panel/VBoxContainer/Quit.pressed.connect(_on_quit_button_pressed)
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Master"),
		linear_to_db(Global.master_volume)
	)

func _input(event):
	if event.is_action_pressed("ui_cancel"): # usually Esc
		toggle_pause()

func toggle_pause():
	get_tree().paused = not get_tree().paused
	pause_menu.visible = get_tree().paused

func _on_resume_button_pressed():
	toggle_pause()

func _on_restart_button_pressed():
	get_tree().reload_current_scene()

func _on_main_menu_button_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/SongSelect.tscn")

func _on_quit_button_pressed():
	get_tree().quit()
