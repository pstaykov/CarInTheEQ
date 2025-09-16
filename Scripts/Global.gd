extends Node

var current_level = {
	"audio_path": "",
	"json_path": ""
}

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

var master_volume: float = 1.0

var unlocked_songs = {}

var disc_count = 0

var casette_count = 0

var SpaceUnlocked = false

var SpaceRings: int = 0

func unlock_song(song_id: String) -> void:
	if song_id not in unlocked_songs:
		unlocked_songs[song_id] = songs[song_id]
		print("Unlocked song: ", song_id)
	else:
		print("Song already unlocked: ", song_id)
