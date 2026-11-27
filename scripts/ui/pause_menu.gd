class_name PauseMenu
extends Control
## Menu en jeu (Échap) : Reprendre, Sauvegarder, Sauvegarder sous…, Charger…,
## Menu principal, Quitter. Le temps est arrêté tant que le menu est ouvert.
## Ctrl+S sauvegarde directement, même menu fermé.

## Résultat à annoncer : texte, réussite ou échec (avec une action pour réessayer).
signal message(text: String, ok: bool, retry: Callable)

const CARD_WIDTH := 376.0
const BUTTON_WIDTH := 320.0
const COIN := preload("res://assets/sprites/piece_mz.svg")

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
var _save_as_button: Button


func _ready() -> void:
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var veil := ColorRect.new()
	veil.color = Color(Palette.ENCRE, 0.55)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(veil)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_card.custom_minimum_size.x = CARD_WIDTH
	center.add_child(_card)
	_load_panel.visible = false
	_load_panel.closed.connect(_show_buttons)
	center.add_child(_load_panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	_card.add_child(column)
	_title.add_theme_font_override("font", HudTheme.font(HudTheme.BALOO, 800))
	_title.add_theme_font_size_override("font_size", 24)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_title)
	_subtitle.theme_type_variation = &"MutedLabel"
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_subtitle)
	column.add_child(_buttons)
	column.add_child(_save_as)
	_build_buttons()
	_build_save_as()


# Changer de partie depuis le menu remplace la scène : le menu n'est alors plus ouvert.
func _exit_tree() -> void:
	is_open = false


func setup(p_world: World) -> void:
	world = p_world


func _build_buttons() -> void:
	_buttons.add_theme_constant_override("separation", 8)
	_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_add(_buttons, "Reprendre", &"PrimaryButton", close, "continuer", "Échap")
	_add(_buttons, "Sauvegarder", &"SecondaryButton", _on_save_pressed, "sauvegarder", "Ctrl S")
	_add(_buttons, "Sauvegarder sous…", &"SecondaryButton", _show_save_as, "sauvegarder")
	_add(_buttons, "Charger une partie…", &"SecondaryButton", _show_load, "charger")
	var line := ColorRect.new()
	line.color = Palette.TRAIT
	line.custom_minimum_size = Vector2(BUTTON_WIDTH, 2)
	line.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_buttons.add_child(line)
	_add(_buttons, "Retour au quartier", &"SecondaryButton", _on_neighborhood_pressed, "emmenager")
	_add(_buttons, "Menu principal", &"QuietButton", _on_title_pressed, "menu")
	if Device.mobile:
		_add(_buttons, "Plein écran", &"QuietButton", Device.toggle_fullscreen, "plein_ecran")
	# Dans un navigateur, « Quitter » ne ferme rien : on ferme l'onglet.
	if not OS.has_feature("web"):
		_add(_buttons, "Quitter le jeu", &"QuietButton", _on_quit_pressed, "quitter")


func _on_save_pressed() -> void:
	save_now()
	close()


func _on_neighborhood_pressed() -> void:
	_resume_time()
	SaveManager.leave_to_neighborhood(world)


func _on_title_pressed() -> void:
	save_now(false)
	_resume_time()
	SaveManager.go_to_title()


func _on_quit_pressed() -> void:
	save_now(false)
	get_tree().quit()


func _build_save_as() -> void:
	_save_as.add_theme_constant_override("separation", 8)
	var label := Label.new()
	label.text = "NOM DE LA COPIE"
	label.theme_type_variation = &"SectionTitle"
	_save_as.add_child(label)
	_name_field.max_length = 40
	_name_field.text_submitted.connect(func(_text: String) -> void: _confirm_save_as())
	_name_field.text_changed.connect(_on_copy_name_changed)
	_save_as.add_child(_name_field)
	var hint := Label.new()
	hint.text = "La partie en cours reste ouverte."
	hint.theme_type_variation = &"MutedLabel"
	_save_as.add_child(hint)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_save_as.add_child(row)
	_add(row, "Retour", &"SecondaryButton", _show_buttons)
	_save_as_button = _add(row, "Enregistrer", &"PrimaryButton", _confirm_save_as, "sauvegarder")
	for button in row.get_children():
		button.custom_minimum_size.x = 0
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL


## Bouton de 320 px, avec une icône et une petite pastille de raccourci à droite.
func _add(parent: Control, text: String, variation: StringName, action: Callable, icon := "",
		shortcut := "") -> Button:
	var button := Button.new()
	button.text = text
	button.theme_type_variation = variation
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(BUTTON_WIDTH, 38 if Device.mobile else 44)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if icon != "":
		button.icon = load("res://assets/icons/white/%s.svg" % icon)
	button.pressed.connect(action)
	# Pas de raccourci clavier à afficher sur un téléphone.
	if shortcut != "" and not Device.mobile:
		var light := variation == &"PrimaryButton"
		var pill := Label.new()
		pill.text = shortcut
		pill.add_theme_font_override("font", HudTheme.font(HudTheme.NUNITO, 800))
		pill.add_theme_font_size_override("font_size", 11)
		var ink := Palette.PAPIER if light else Palette.ENCRE
		pill.add_theme_color_override("font_color", ink)
		var style := HudTheme.box(Color.TRANSPARENT, 6, ink, 1)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.content_margin_left = 6
		style.content_margin_right = 6
		style.content_margin_top = 1
		style.content_margin_bottom = 1
		pill.add_theme_stylebox_override("normal", style)
		pill.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
		pill.offset_left = -64
		pill.offset_right = -14
		pill.offset_top = -11
		pill.offset_bottom = 11
		pill.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		pill.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		pill.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(pill)
	parent.add_child(button)
	return button


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
	_on_copy_name_changed(_name_field.text)
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
		message.emit("Partie enregistrée" if ok else "La sauvegarde a échoué", ok, save_now)


func _confirm_save_as() -> void:
	if _name_field.text.strip_edges() == "":
		return
	var ok := SaveManager.save_as(world, _name_field.text)
	message.emit(("Copie enregistrée : " + SaveManager.current_name) if ok else "La sauvegarde a échoué",
			ok, _confirm_save_as)
	close()


## Un nom vide : le champ passe en erreur et « Enregistrer » est inactif.
func _on_copy_name_changed(text: String) -> void:
	var empty := text.strip_edges() == ""
	_save_as_button.disabled = empty
	var style := HudTheme._padded(HudTheme.box(Color.WHITE, 10, Palette.CRITIQUE if empty else Palette.TRAIT, 2), 12, 8)
	_name_field.add_theme_stylebox_override("normal", style)


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
