class_name ChoiceGroup
extends PanelContainer
## Boutons segmentés dans un groupe arrondi (Homme / Femme, tranches d'âge).
## Chaque option : [id, libellé, icône (facultative)]. L'option active est en encre.

signal chosen(id: StringName)

var _buttons: Dictionary[StringName, Button] = {}


func _init(options: Array, vertical_icons := false) -> void:
	theme_type_variation = &"SpeedGroup"
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	add_child(row)
	for option in options:
		var button := Button.new()
		button.theme_type_variation = &"ModeTab"
		button.text = option[1]
		if option.size() > 2 and option[2] != null:
			button.icon = option[2]
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_NONE
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 52 if vertical_icons else 36
		button.add_theme_font_size_override("font_size", 12 if vertical_icons else 14)
		if vertical_icons:
			button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
			button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			button.add_theme_constant_override("icon_max_width", 18)
		button.pressed.connect(_on_pressed.bind(option[0]))
		row.add_child(button)
		_buttons[option[0]] = button


func select(id: StringName) -> void:
	for key in _buttons:
		_buttons[key].set_pressed_no_signal(key == id)


func _on_pressed(id: StringName) -> void:
	select(id)
	chosen.emit(id)
