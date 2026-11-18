class_name PausePill
extends HBoxContainer
## Remplace l'horloge en mode Construire et Acheter : pastille « En pause » + jour et heure.

const PAUSE_ICON := preload("res://assets/icons/white/pause.svg")

var _time := Label.new()


func _ready() -> void:
	add_theme_constant_override("separation", 10)
	var pill := PanelContainer.new()
	var style := HudTheme.box(Palette.CONTOUR, 8)
	style.content_margin_left = 10
	style.content_margin_right = 10
	pill.add_theme_stylebox_override("panel", style)
	pill.custom_minimum_size.y = 28
	pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	pill.add_child(row)
	var icon := TextureRect.new()
	icon.texture = PAUSE_ICON
	icon.modulate = Palette.PAPIER
	icon.custom_minimum_size = Vector2(14, 14)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var label := Label.new()
	label.text = "En pause"
	label.add_theme_color_override("font_color", Palette.PAPIER)
	label.add_theme_font_override("font", HudTheme.font(HudTheme.NUNITO, 800))
	label.add_theme_font_size_override("font_size", 13)
	row.add_child(label)
	add_child(pill)
	_time.theme_type_variation = &"MutedLabel"
	_time.add_theme_font_size_override("font_size", 14)
	add_child(_time)
	visibility_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	_time.text = "Jour %d · %02d:%02d" % [GameClock.get_day(), GameClock.get_hour(), GameClock.get_minute()]
