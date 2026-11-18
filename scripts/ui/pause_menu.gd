class_name PauseMenu
extends Control
## Menu en jeu (Échap) : Reprendre, Sauvegarder, Sauvegarder sous…, Charger…,
## Menu principal, Quitter. Le temps est arrêté tant que le menu est ouvert.
## Ctrl+S sauvegarde directement, même menu fermé.

signal message(text: String)

## Vrai quand un menu en jeu est ouvert (les raccourcis de vitesse sont alors ignorés).
static var is_open := false

var world: World
var _card := PanelContainer.new()
var _title := Label.new()
var _subtitle := Label.new()
var _buttons := VBoxContainer.new()
var _save_as := VBoxContainer.new()
var _name_field := LineEdit.new()
var _load_panel := LoadPanel.new()
var _speed_before := 1


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
	_card.custom_minimum_size.x = 360
	center.add_child(_card)
	_load_panel.visible = false
	_load_panel.closed.connect(_show_buttons)
	center.add_child(_load_panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	_card.add_child(column)
	_title.theme_type_variation = &"BigLabel"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_title)
	_subtitle.theme_type_variation = &"MutedLabel"
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_subtitle)
	column.add_child(_buttons)
	column.add_child(_save_as)
	_build_buttons()
	_build_save_as()


func setup(p_world: World) -> void:
	world = p_world


func _build_buttons() -> void:
	_buttons.add_theme_constant_override("separation", 8)
	_add(_buttons, "Reprendre", &"PrimaryButton", close)
	_add(_buttons, "Sauvegarder  (Ctrl+S)", &"SecondaryButton", _on_save_pressed)
	_add(_buttons, "Sauvegarder sous…", &"SecondaryButton", _show_save_as)
	_add(_buttons, "Charger une partie…", &"SecondaryButton", _show_load)
	_add(_buttons, "Menu principal", &"SecondaryButton", _on_title_pressed)
	_add(_buttons, "Quitter le jeu", &"SecondaryButton", _on_quit_pressed)


func _on_save_pressed() -> void:
	save_now()
	close()


func _on_title_pressed() -> void:
	save_now(false)
	_resume_time()
	SaveManager.go_to_title()


func _on_quit_pressed() -> void:
	save_now(false)
	get_tree().quit()


func _build_save_as() -> void:
	_save_as.add_theme_constant_override("separation", 10)
	var label := Label.new()
	label.text = "Nom de la copie"
	label.theme_type_variation = &"StrongLabel"
	_save_as.add_child(label)
	_name_field.max_length = 40
	_name_field.text_submitted.connect(func(_text: String) -> void: _confirm_save_as())
	_save_as.add_child(_name_field)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 8)
	_save_as.add_child(row)
	_add(row, "Retour", &"SecondaryButton", _show_buttons)
	_add(row, "Enregistrer", &"PrimaryButton", _confirm_save_as)


func _add(parent: Control, text: String, variation: StringName, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.theme_type_variation = variation
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size.y = 42
	button.pressed.connect(action)
	parent.add_child(button)


# --- Ouvrir et fermer ------------------------------------------------------------

func open() -> void:
	if visible:
		return
	_speed_before = GameClock.speed_index
	GameClock.set_speed(0)
	_title.text = SaveManager.current_name if SaveManager.current_name != "" else "Partie non enregistrée"
	_subtitle.text = "Jour %d · %02d:%02d · %s" % [GameClock.get_day(), GameClock.get_hour(),
			GameClock.get_minute(), Palette.format_mz(Wallet.funds)]
	_show_buttons()
	visible = true
	is_open = true


func close() -> void:
	if not visible:
		return
	visible = false
	is_open = false
	_resume_time()


func _resume_time() -> void:
	# En mode Construire ou Acheter, le temps reste en pause.
	if GameMode.is_live():
		GameClock.set_speed(_speed_before)


func _show_buttons() -> void:
	_card.visible = true
	_buttons.visible = true
	_save_as.visible = false
	_load_panel.visible = false


func _show_save_as() -> void:
	_buttons.visible = false
	_save_as.visible = true
	_name_field.text = (SaveManager.current_name + " (copie)") if SaveManager.current_name != "" else "Ma partie"
	_name_field.grab_focus()
	_name_field.select_all()


func _show_load() -> void:
	# On enregistre la partie en cours avant d'en ouvrir une autre.
	save_now(false)
	_card.visible = false
	_load_panel.visible = true


# --- Sauvegarder -------------------------------------------------------------------

## Sauvegarde la partie en cours (ou en crée une si elle n'a pas encore d'emplacement).
func save_now(announce := true) -> void:
	if world == null:
		return
	var ok: bool
	if SaveManager.current_slot == "":
		ok = SaveManager.save_as(world, "Ma partie")
	else:
		ok = SaveManager.save_current(world)
	if announce:
		message.emit("Partie enregistrée" if ok else "La sauvegarde a échoué")


func _confirm_save_as() -> void:
	var ok := SaveManager.save_as(world, _name_field.text)
	message.emit(("Copie enregistrée : " + SaveManager.current_name) if ok else "La sauvegarde a échoué")
	close()


# --- Clavier -----------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_S and key.is_command_or_control_pressed():
		save_now()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		if visible:
			if _card.visible and _buttons.visible:
				close()
			else:
				_show_buttons()
		elif not _gesture_in_progress():
			open()
		else:
			return
		get_viewport().set_input_as_handled()


## Un tracé ou un objet en main : Échap est pour eux.
func _gesture_in_progress() -> bool:
	return world != null and (world.build_controller.is_busy() or world.buy_controller.is_busy())
