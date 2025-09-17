extends CanvasLayer

@onready var ring_label: Label = $RingCounter

func update_ring_count(count: int) -> void:
	ring_label.text = "Rings: %d" % count
