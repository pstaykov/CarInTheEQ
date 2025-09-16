extends CanvasLayer

@export var popup_scene: PackedScene = preload("res://Decorations/PopupLablel.tscn")

func _ready() -> void:
	add_to_group("popup_manager")

func show_disc_popup():
	_spawn_popup("+1 Disc", Color(0, 1, 0)) # green

func show_casette_popup():
	_spawn_popup("+1 Casette", Color(0, 0.5, 1)) # blue

func _spawn_popup(text_value: String, color: Color):
	var popup = popup_scene.instantiate()
	$Control.add_child(popup)
	
	# Position (adjust depending on your UI resolution)
	popup.position = Vector2(640, 300)
	popup.show_popup(text_value, color)
