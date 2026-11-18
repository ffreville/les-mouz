class_name TitleScreen
extends Control
## Écran d'accueil : Continuer la dernière partie, Nouvelle partie (avec un nom),
## Charger une partie, Quitter.

const PEPIN := preload("res://assets/sprites/mouz_pepin.svg")
const MYRTILLE := preload("res://assets/sprites/mouz_myrtille.svg")
const GRASS := preload("res://assets/floors/herbe.svg")
const DEFAULT_NAME := "La maison de Pépin et Myrtille"

var _menu := VBoxContainer.new()
var _new_game := VBoxContainer.new()
var _name_field := LineEdit.new()
var _load_panel := LoadPanel.new()
var _main_card := PanelContainer.new()


func _ready() -> void:
	theme = HudTheme.build()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var grass := TextureRect.new()
	grass.texture = GRASS
	grass.stretch_mode = TextureRect.STRETCH_TILE
	grass.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(grass)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_main_card.custom_minimum_size.x = 420
	center.add_child(_main_card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	_main_card.add_child(column)
	column.add_child(_header())
	column.add_child(_menu)
	column.add_child(_new_game)
	_build_menu()
	_build_new_game()

	_load_panel.visible = false
	_load_panel.closed.connect(_show_menu)
	center.add_child(_load_panel)
	_show_menu()


func _header() -> Control:
	var header := VBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 4)
	var faces := HBoxContainer.new()
	faces.alignment = BoxContainer.ALIGNMENT_CENTER
	faces.add_theme_constant_override("separation", 12)
	for sprite in [PEPIN, MYRTILLE]:
		var face := TextureRect.new()
		face.texture = sprite
		face.custom_minimum_size = Vector2(56, 56)
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		faces.add_child(face)
	header.add_child(faces)
	var logo := Label.new()
	logo.text = "Les Mouz"
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.add_theme_font_override("font", HudTheme.font(HudTheme.BALOO, 800))
	logo.add_theme_font_size_override("font_size", 48)
	header.add_child(logo)
	var subtitle := Label.new()
	subtitle.text = "Une maison de poche à construire"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.theme_type_variation = &"MutedLabel"
	subtitle.add_theme_font_size_override("font_size", 14)
	header.add_child(subtitle)
	return header


func _build_menu() -> void:
	_menu.add_theme_constant_override("separation", 10)
	var latest := SaveManager.latest_slot()
	if latest != "":
		var meta := SaveManager.read_meta(latest)
		var resume := _button("Continuer : %s" % meta.get("name", "dernière partie"), &"PrimaryButton")
		resume.tooltip_text = "Jour %d · %s" % [int(meta.get("day", 1)), Palette.format_mz(int(meta.get("funds", 0)))]
		resume.pressed.connect(func() -> void: SaveManager.load_slot(latest))
		_menu.add_child(resume)
	var new_game := _button("Nouvelle partie", &"SecondaryButton" if latest != "" else &"PrimaryButton")
	new_game.pressed.connect(_show_new_game)
	_menu.add_child(new_game)
	var load_game := _button("Charger une partie", &"SecondaryButton")
	load_game.disabled = latest == ""
	load_game.pressed.connect(_show_load)
	_menu.add_child(load_game)
	var quit := _button("Quitter", &"SecondaryButton")
	quit.pressed.connect(func() -> void: get_tree().quit())
	_menu.add_child(quit)


func _build_new_game() -> void:
	_new_game.add_theme_constant_override("separation", 10)
	var label := Label.new()
	label.text = "Nom de la partie"
	label.theme_type_variation = &"StrongLabel"
	_new_game.add_child(label)
	_name_field.text = DEFAULT_NAME
	_name_field.max_length = 40
	_name_field.text_submitted.connect(func(_text: String) -> void: _start())
	_new_game.add_child(_name_field)
	var hint := Label.new()
	hint.text = "Un terrain vide et %s pour construire." % Palette.format_mz(Wallet.settings.start_funds)
	hint.theme_type_variation = &"MutedLabel"
	_new_game.add_child(hint)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 8)
	var back := _button("Retour", &"SecondaryButton")
	back.pressed.connect(_show_menu)
	row.add_child(back)
	var start := _button("Commencer", &"PrimaryButton")
	start.pressed.connect(_start)
	row.add_child(start)
	_new_game.add_child(row)


func _start() -> void:
	SaveManager.start_new_game(_name_field.text)


func _show_menu() -> void:
	_main_card.visible = true
	_menu.visible = true
	_new_game.visible = false
	_load_panel.visible = false


func _show_new_game() -> void:
	_menu.visible = false
	_new_game.visible = true
	_name_field.grab_focus()
	_name_field.select_all()


func _show_load() -> void:
	_main_card.visible = false
	_load_panel.visible = true


func _button(text: String, variation: StringName) -> Button:
	var button := Button.new()
	button.text = text
	button.theme_type_variation = variation
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size.y = 44
	return button


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not _menu.visible:
		_show_menu()
		get_viewport().set_input_as_handled()
