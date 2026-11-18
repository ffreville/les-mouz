class_name NeedBar
extends HBoxContainer
## Une barre de besoin : nom + jauge colorée (rouge sous le seuil critique).

const CRITICAL_COLOR := Color(0.9, 0.25, 0.25)
const BACKGROUND_COLOR := Color(1, 1, 1, 0.08)

var _label := Label.new()
var _bar := ProgressBar.new()
var _fill := StyleBoxFlat.new()
var _color: Color
var _critical_threshold: float


func setup(title: String, color: Color, critical_threshold: float) -> void:
	_color = color
	_critical_threshold = critical_threshold
	_label.text = title
	_label.custom_minimum_size.x = 70
	_label.add_theme_font_size_override("font_size", 13)
	_bar.max_value = 100.0
	_bar.show_percentage = false
	_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_bar.custom_minimum_size.y = 14
	_fill.set_corner_radius_all(3)
	_bar.add_theme_stylebox_override("fill", _fill)
	var background := StyleBoxFlat.new()
	background.bg_color = BACKGROUND_COLOR
	background.set_corner_radius_all(3)
	_bar.add_theme_stylebox_override("background", background)
	add_child(_label)
	add_child(_bar)


func set_value(value: float) -> void:
	_bar.value = value
	_fill.bg_color = CRITICAL_COLOR if value < _critical_threshold else _color
