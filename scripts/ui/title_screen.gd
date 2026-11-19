class_name TitleScreen
extends Control
## Écran d'accueil : Continuer la dernière partie, Nouvelle partie (création de la famille),
## Charger une partie, Quitter.

const GRASS := preload("res://assets/floors/herbe.svg")
const NEW_GAME_SCENE := "res://scenes/new_game.tscn"
const FACES := ["res://data/characters/myrtille.tres", "res://data/characters/pepin.tres"]

var _menu := VBoxContainer.new()
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
	_build_menu()

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
	for path in FACES:
		var face := MouzPortrait.new(56)
		face.appearance = load(path).appearance
		face.background = Palette.PAPIER_2
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
	new_game.pressed.connect(func() -> void: get_tree().change_scene_to_file(NEW_GAME_SCENE))
	_menu.add_child(new_game)
	var load_game := _button("Charger une partie", &"SecondaryButton")
	load_game.disabled = latest == ""
	load_game.pressed.connect(_show_load)
	_menu.add_child(load_game)
	var quit := _button("Quitter", &"SecondaryButton")
	quit.pressed.connect(func() -> void: get_tree().quit())
	_menu.add_child(quit)


func _show_menu() -> void:
	_main_card.visible = true
	_menu.visible = true
	_load_panel.visible = false


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
