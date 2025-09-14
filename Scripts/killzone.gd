extends Area3D

@onready var timer = $Timer

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("car"):
		timer.start()
	

func _on_timer_timeout() -> void:
	get_tree().reload_current_scene()
