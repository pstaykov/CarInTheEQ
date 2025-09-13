extends SubViewportContainer

@export var margin_top: int = 20     # px from the top
@export var size_pct: float = 0.22   # width of minimap as % of screen width (square)

func _ready():
	_apply_layout()
	get_viewport().size_changed.connect(_apply_layout)

func _apply_layout():
	var view_size = get_viewport().get_visible_rect().size
	var s = view_size.x * size_pct
	size = Vector2(s, s)

	# Anchors: top center
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.0
	anchor_bottom = 0.0

	offset_left = -s / 2
	offset_right = s / 2
	offset_top = margin_top
	offset_bottom = offset_top + s
