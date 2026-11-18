class_name ConfirmPanel
extends Control
## Fenêtre de confirmation centrée, dans le style du jeu, sur un voile qui bloque les clics.

signal confirmed

var _message := Label.new()
var _confirm := Button.new()


func _ready() -> void:
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var veil := ColorRect.new()
	veil.color = Color(Palette.ENCRE, 0.35)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(veil)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 380
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	panel.add_child(column)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_message)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	buttons.add_theme_constant_override("separation", 8)
	column.add_child(buttons)
	var cancel := Button.new()
	cancel.text = "Annuler"
	cancel.theme_type_variation = &"OptionCard"
	cancel.pressed.connect(hide)
	buttons.add_child(cancel)
	_confirm.theme_type_variation = &"ModeTab"
	_confirm.toggle_mode = false
	_confirm.add_theme_stylebox_override("normal", HudTheme.box(Palette.CONTOUR, 10, Color.TRANSPARENT, 0, 8))
	_confirm.add_theme_color_override("font_color", Palette.PAPIER)
	_confirm.pressed.connect(_on_confirm)
	buttons.add_child(_confirm)


func ask(message: String, confirm_label: String) -> void:
	_message.text = message
	_confirm.text = confirm_label
	show()


func _on_confirm() -> void:
	hide()
	confirmed.emit()


func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		hide()
		get_viewport().set_input_as_handled()
