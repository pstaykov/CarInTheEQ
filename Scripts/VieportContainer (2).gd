extends SubViewportContainer

@export var margin_top: int = 20     # pixels from top
@export var size_pct: float = 0.5    # % of screen width (0.3 = 30%)

func _ready():
	# center it properly
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER

	_apply_layout()
	get_viewport().size_changed.connect(_apply_layout)

func _apply_layout():
	var screen_size = get_viewport().size
	var s = 9   # square minimap, relative to screen width

	# anchors → center top
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.0
	anchor_bottom = 0.0

	# offsets → move from anchors
	offset_left = -s / 2
	offset_right = s / 2
	offset_top = margin_top
	offset_bottom = margin_top + s

	# force size
	custom_minimum_size = Vector2(s, s)
