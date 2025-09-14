extends Area3D

@onready var timer = $Timer
@export var death_screen_scene: PackedScene = preload("res://Scenes/DeathScreen.tscn")

func _on_body_entered(body: Node3D) -> void:
	# Only trigger if the body is the car
	if body.is_in_group("car"):
		timer.start()
		
		# Add smoke effect to the car
		if body.has_method("add_smoke_effect"):
			body.add_smoke_effect()

func _on_timer_timeout() -> void:
	# Show death screen instead of immediately reloading
	if death_screen_scene:
		var death_screen = death_screen_scene.instantiate()
		get_tree().root.add_child(death_screen)
	else:
		# Fallback: reload if no death screen scene is assigned
		get_tree().reload_current_scene()
