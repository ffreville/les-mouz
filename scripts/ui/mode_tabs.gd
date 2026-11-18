class_name ModeTabs
extends PanelContainer
## Onglets Vivre / Construire / Acheter dans la barre du haut (raccourcis F1 / F2 / F3).

const ICONS := {
	GameMode.Mode.LIVE: preload("res://assets/icons/white/vivre.svg"),
	GameMode.Mode.BUILD: preload("res://assets/icons/white/construire.svg"),
	GameMode.Mode.BUY: preload("res://assets/icons/white/acheter.svg"),
}

var _buttons: Dictionary[int, Button] = {}


func _ready() -> void:
	theme_type_variation = &"SpeedGroup"
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	add_child(row)
	var group := ButtonGroup.new()
	for mode in [GameMode.Mode.LIVE, GameMode.Mode.BUILD, GameMode.Mode.BUY]:
		var button := Button.new()
		button.theme_type_variation = &"ModeTab"
		button.text = GameMode.NAMES[mode]
		button.icon = ICONS[mode]
		button.toggle_mode = true
		button.button_group = group
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size.y = 36
		button.tooltip_text = "%s (F%d)" % [GameMode.NAMES[mode], mode + 1]
		button.add_theme_constant_override("icon_max_width", 18)
		button.pressed.connect(GameMode.set_mode.bind(mode))
		row.add_child(button)
		_buttons[mode] = button
	GameMode.mode_changed.connect(_on_mode_changed)
	_on_mode_changed(GameMode.mode)


func _on_mode_changed(mode: int) -> void:
	# set_pressed_no_signal ne relâche pas les autres boutons du groupe : on le fait nous-mêmes.
	for key in _buttons:
		_buttons[key].set_pressed_no_signal(key == mode)
