extends Control

func _ready() -> void:
	$VBoxContainer/MainMenu.pressed.connect(_on_MainMenu_button_pressed)
	$VBoxContainer/BuyRareSong.pressed.connect(_on_RareSongButton_pressed)
	add_to_group("store_ui")


func _on_MainMenu_button_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/SongSelect.tscn")
	
func _process(delta: float) -> void:
	$VBoxContainer/BuyRareSong.text = "Buy rare song " + Global.disc_count + "/15 " 

func _on_RareSongButton_pressed():
	Global.disc_count -= 15
	Global.unlock_song(Global.songs.keys().pick_random())
