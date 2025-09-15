extends Area3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_process(true)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	rotate_y(0.2 * delta)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("car"):
		queue_free()
