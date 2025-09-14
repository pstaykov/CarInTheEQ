extends CanvasLayer


func _ready():
	$VBoxContainer/Restart.pressed.connect(func(): _on_restart_pressed())
	$VBoxContainer/MainMenu.pressed.connect(func(): _on_main_menu_button_pressed())
	# Pause the game
	get_tree().paused = true

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
	queue_free()
	
func _on_main_menu_button_pressed() -> void:
	queue_free()
	get_tree().change_scene_to_file("res://Scenes/game_start.tscn")
	
	
