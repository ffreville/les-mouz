class_name ClockPanel
extends HBoxContainer
## Affiche l'horloge de jeu (jour et heure).

const CLOCK_ICON := preload("res://assets/icons/ink/horloge.svg")

var _time_label := Label.new()


func _ready() -> void:
	add_theme_constant_override("separation", 8)
	var icon := TextureRect.new()
	icon.texture = CLOCK_ICON
	icon.custom_minimum_size = Vector2(22, 22)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	add_child(icon)
	_time_label.theme_type_variation = &"BigLabel"
	add_child(_time_label)
	GameClock.minute_changed.connect(_on_minute_changed)
	_time_label.text = GameClock.format_time()


func _on_minute_changed(_day: int, _hour: int, _minute: int) -> void:
	_time_label.text = GameClock.format_time()
