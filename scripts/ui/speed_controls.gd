class_name SpeedControls
extends HBoxContainer
## Boutons de vitesse Pause / x1 / x2 / x3.
## Raccourcis : Espace = pause/reprise, touches 1 à 3 = vitesses.

## Icône de chaque vitesse, dans l'ordre de GameClock.settings.speed_multipliers.
const ICONS: Array[Texture2D] = [
	preload("res://assets/icons/white/pause.svg"),
	preload("res://assets/icons/white/vitesse_1.svg"),
	preload("res://assets/icons/white/vitesse_2.svg"),
	preload("res://assets/icons/white/vitesse_3.svg"),
]

var _buttons: Array[Button] = []
var _speed_before_pause: int = 1


func _ready() -> void:
	add_theme_constant_override("separation", 4)
	var group := ButtonGroup.new()
	for i in GameClock.settings.speed_multipliers.size():
		var button := Button.new()
		if i < ICONS.size():
			button.icon = ICONS[i]
			button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			button.expand_icon = true
		else:
			button.text = GameClock.settings.speed_labels[i]
		button.custom_minimum_size = Vector2(40, 32)
		button.tooltip_text = GameClock.settings.speed_labels[i]
		button.toggle_mode = true
		button.button_group = group
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(GameClock.set_speed.bind(i))
		add_child(button)
		_buttons.append(button)
	GameClock.speed_changed.connect(_on_speed_changed)
	_on_speed_changed(GameClock.speed_index)


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_SPACE:
			if GameClock.is_paused():
				GameClock.set_speed(_speed_before_pause)
			else:
				_speed_before_pause = GameClock.speed_index
				GameClock.set_speed(0)
		KEY_1, KEY_2, KEY_3:
			GameClock.set_speed(key.keycode - KEY_0)
		_:
			return
	get_viewport().set_input_as_handled()


func _on_speed_changed(index: int) -> void:
	_buttons[index].button_pressed = true
