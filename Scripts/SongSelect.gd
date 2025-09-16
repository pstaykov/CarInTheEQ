extends Control

@onready var buttons = {"Tetris": get_tree().get_nodes_in_group("lvl_buttons")[0], "Sonic": get_tree().get_nodes_in_group("lvl_buttons")[1], "AKAI": get_tree().get_nodes_in_group("lvl_buttons")[2], "TriPoloski": get_tree().get_nodes_in_group("lvl_buttons")[3]}

func _ready():
	# Connect buttons (adjust paths to match your scene tree)
	$VBoxContainer/TetrisButton.pressed.connect(func(): _on_song_selected("Tetris"))
	$VBoxContainer/SonicButton.pressed.connect(func(): _on_song_selected("Sonic"))
	$VBoxContainer/PacManButton.pressed.connect(func(): _on_song_selected("PacMan"))
	$VBoxContainer/AKAIButton.pressed.connect(func(): _on_song_selected("AKAI"))
	$VBoxContainer/TriPoloskiButton.pressed.connect(func(): _on_song_selected("TriPoloski"))
	$VBoxContainer/Back.pressed.connect(func(): _on_back_button_pressed())
	$VBoxContainer/SpaceLevel.pressed.connect(func(): _on_SpaceLevel_button_pressed())
	
	if Global.SpaceUnlocked:
		$VBoxContainer/SpaceLevel.visible = true
	
	for i in buttons.keys():
		if i in Global.unlocked_songs.keys():
			buttons[i].visible = true
		else:
			buttons[i].visible = false


func _on_song_selected(song_name: String) -> void:
	if not Global.songs.has(song_name):
		push_error("❌ Song not found: %s" % song_name)
		return

	# Explicitly typed dictionary
	var game_data: Dictionary = {
		"audio_path": Global.songs[song_name]["audio"],
		"json_path": Global.songs[song_name]["json"]
	}

	Global.current_level = game_data

	get_tree().change_scene_to_file("res://Scenes/main.tscn")

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/game_start.tscn")
	

func _on_SpaceLevel_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/space.tscn")
