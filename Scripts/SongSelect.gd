extends Control

# Dictionary of available songs
var songs = {
	"Tetris": {
		"audio": "res://audio/Tetris.mp3",
		"json": "res://audio/Jsons/Tetris.json"
	},
	"Sonic": {
		"audio": "res://audio/Sonic.mp3",
		"json": "res://audio/Jsons/Sonic.json"
	},
	"PacMan": {
		"audio": "res://audio/PacMan.mp3",
		"json": "res://audio/Jsons/PacMan.json"
	},
	"AKAI": {
		"audio": "res://audio/AKAI.mp3",
		"json": "res://audio/Jsons/AKAI.json"
	},
	"TriPoloski": {
		"audio": "res://audio/TriPoloski.mp3",
		"json": "res://audio/Jsons/TriPoloski.json"
	}
}

func _ready():
	# Connect buttons (adjust paths to match your scene tree)
	$VBoxContainer/TetrisButton.pressed.connect(func(): _on_song_selected("Tetris"))
	$VBoxContainer/SonicButton.pressed.connect(func(): _on_song_selected("Sonic"))
	$VBoxContainer/PacManButton.pressed.connect(func(): _on_song_selected("PacMan"))
	$VBoxContainer/AKAIButton.pressed.connect(func(): _on_song_selected("AKAI"))
	$VBoxContainer/TriPoloskiButton.pressed.connect(func(): _on_song_selected("TriPoloski"))
	$VBoxContainer/Back.pressed.connect(func(): _on_back_button_pressed())

func _on_song_selected(song_name: String) -> void:
	if not songs.has(song_name):
		push_error("❌ Song not found: %s" % song_name)
		return

	# Explicitly typed dictionary
	var game_data: Dictionary = {
		"audio_path": songs[song_name]["audio"],
		"json_path": songs[song_name]["json"]
	}

	Global.current_level = game_data

	get_tree().change_scene_to_file("res://Scenes/main.tscn")

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/game_start.tscn")
