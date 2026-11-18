class_name ClockPanel
extends HBoxContainer
## Affiche l'horloge de jeu et les boutons de vitesse (Pause / x1 / x2 / x3).
## Raccourcis : Espace = pause/reprise, touches 1 à 3 = vitesses.

var _time_label: Label
var _buttons: Array[Button] = []
var _speed_before_pause: int = 1


func _ready() -> void:
	add_theme_constant_override("separation", 6)
	_time_label = Label.new()
	_time_label.custom_minimum_size.x = 160
	_time_label.add_theme_font_size_override("font_size", 18)
	add_child(_time_label)

	var group := ButtonGroup.new()
	for i in GameClock.settings.speed_labels.size():
		var button := Button.new()
		button.text = GameClock.settings.speed_labels[i]
		button.toggle_mode = true
		button.button_group = group
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(GameClock.set_speed.bind(i))
		add_child(button)
		_buttons.append(button)

	GameClock.minute_changed.connect(_on_minute_changed)
	GameClock.speed_changed.connect(_on_speed_changed)
	_time_label.text = GameClock.format_time()
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


func _on_minute_changed(_day: int, _hour: int, _minute: int) -> void:
	_time_label.text = GameClock.format_time()


func _on_speed_changed(index: int) -> void:
	_buttons[index].button_pressed = true
