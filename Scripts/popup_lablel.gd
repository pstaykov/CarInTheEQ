extends Label

@export var life_time: float = 1.5   # how long popup stays
@export var rise_amount: float = 50  # how much it moves up
@export var fade_time: float = 1.0   # fade duration

func show_popup(text_value: String, color: Color) -> void:
	text = text_value
	modulate = color
	visible = true

	# Create a tween on this node
	var tween = create_tween()
	
	# Animate movement upward
	tween.tween_property(self, "position:y", position.y - rise_amount, life_time)
	
	# Animate fade (alpha)
	tween.parallel().tween_property(self, "modulate:a", 0.0, fade_time).set_delay(life_time - fade_time)

	# Remove the popup after animation
	tween.finished.connect(queue_free)
