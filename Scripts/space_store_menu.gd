extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$VBoxContainer/BackToMain.pressed.connect(_on_MainMenu_button_pressed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_MainMenu_button_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/SongSelect.tscn")
