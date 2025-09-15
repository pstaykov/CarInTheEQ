extends Node

var current_level = {
	"audio_path": "",
	"json_path": ""
}
var master_volume: float = 1.0

var unlocked_songs: Array = []

func unlock_song(song_id: String) -> void:
	if song_id not in unlocked_songs:
		unlocked_songs.append(song_id)
		print("Unlocked song: ", song_id)
	else:
		print("Song already unlocked: ", song_id)
