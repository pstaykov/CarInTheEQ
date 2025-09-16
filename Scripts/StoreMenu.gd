extends Control

func _ready() -> void:
	$VBoxContainer/MainMenu.pressed.connect(_on_MainMenu_button_pressed)
	$VBoxContainer/BuyRareSong.pressed.connect(_on_RareSongButton_pressed)
	$VBoxContainer/UnlockSpace.pressed.connect(_on_UnlockSpaceButton_pressed)
	add_to_group("store_ui")
	update_labels()  # set initial text


func update_labels() -> void:
	$VBoxContainer/BuyRareSong.text = "Buy rare song %d/15" % Global.disc_count
	$VBoxContainer/UnlockSpace.text = "Unlock space %d/5" % Global.casette_count


func _on_MainMenu_button_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/SongSelect.tscn")
	
func _process(delta: float) -> void:
	update_labels() 


func _on_RareSongButton_pressed():
	if Global.disc_count >= 15:
		Global.disc_count -= 15
		Global.unlock_song(Global.songs.keys().pick_random())
		update_labels()  # refresh after purchase


func _on_UnlockSpaceButton_pressed():
	if Global.casette_count >= 5:
		Global.casette_count -= 5
		Global.SpaceUnlocked = true
		update_labels()  # refresh after purchase
