class_name IconBox
extends PanelContainer
## Case arrondie colorée avec une icône centrée (besoins, actions de la file).

var _icon := TextureRect.new()
var _style := StyleBoxFlat.new()


func _init(box_size: float = 28.0, icon_size: float = 18.0, radius: int = 8) -> void:
	custom_minimum_size = Vector2.ONE * box_size
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style.set_corner_radius_all(radius)
	_style.anti_aliasing = true
	add_theme_stylebox_override("panel", _style)
	_icon.custom_minimum_size = Vector2.ONE * icon_size
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	add_child(_icon)


func set_icon(texture: Texture2D) -> void:
	_icon.texture = texture


func set_colors(background: Color, border: Color = Color.TRANSPARENT, border_width := 0) -> void:
	_style.bg_color = background
	_style.border_color = border
	_style.set_border_width_all(border_width)
