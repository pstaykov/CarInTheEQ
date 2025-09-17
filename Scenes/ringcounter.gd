extends CanvasLayer

@onready var ring_label: Label =  $RingCounter

func update_ring_count(count: int) -> void:
	if ring_label == null:
		print("⚠️ Ring label not found!")
		return
	ring_label.text = "Rings: %d" % count
