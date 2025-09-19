extends Node3D

@onready var earth = $Earth
@onready var other_planet = $WaterPlanet

func _ready():
	$Earth/Area3D.input_event.connect(_on_earth_clicked)

func _on_earth_clicked(camera, event, pos, normal, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Earth clicked!")
		get_tree().change_scene_to_file("res://Scenes/SongSelect.tscn") # or your Earth levels scene
