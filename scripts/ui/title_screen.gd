class_name TitleScreen
extends Control
## Écran d'accueil.
##  - Sans partie : un petit jardin où se promènent des Mouz, et « Nouvelle partie ».
##  - Avec une partie : sa vignette en grand derrière la carte, et « Continuer : … ».
## Puis Nouvelle partie (création de la famille), Charger une partie, Quitter.

const GRASS := preload("res://assets/floors/herbe.svg")
const PLANT := "res://assets/sprites/plante_nature_bas.svg"
const NEW_GAME_SCENE := "res://scenes/new_game.tscn"
const CARD_WIDTH := 440.0
const VEIL := Color(0.169, 0.141, 0.251, 0.38)
## Plantes et promeneurs du jardin (positions relatives à l'écran).
const PLANTS := [Vector2(0.06, 0.2), Vector2(0.4, 0.06), Vector2(0.82, 0.27), Vector2(0.92, 0.82),
		Vector2(0.27, 0.83), Vector2(0.67, 0.92), Vector2(0.04, 0.6), Vector2(0.95, 0.5)]
const WALKERS := [Vector2(0.21, 0.52), Vector2(0.27, 0.66), Vector2(0.73, 0.38), Vector2(0.78, 0.6)]

var _menu := VBoxContainer.new()
var _load_panel := LoadPanel.new()
var _main_card := PanelContainer.new()
var _rng := RandomNumberGenerator.new()
var _latest := ""


func _ready() -> void:
	theme = HudTheme.build()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rng.randomize()
	_latest = SaveManager.latest_slot()
	_build_background()

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_main_card.custom_minimum_size.x = CARD_WIDTH
	center.add_child(_main_card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	_main_card.add_child(column)
	column.add_child(_header())
	column.add_child(_menu)
	_build_menu()

	_load_panel.visible = false
	_load_panel.closed.connect(_show_menu)
	_load_panel.new_game_requested.connect(_new_game)
	center.add_child(_load_panel)
	_show_menu()


# --- Fond ---------------------------------------------------------------------------

func _build_background() -> void:
	var grass := TextureRect.new()
	grass.texture = GRASS
	grass.stretch_mode = TextureRect.STRETCH_TILE
	grass.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(grass)
	var thumbnail: Texture2D = null
	if _latest != "":
		for slot in SaveManager.list_slots():
			if slot["id"] == _latest:
				thumbnail = slot["thumbnail"]
	if thumbnail != null:
		# On retrouve sa maison avant même de cliquer.
		var house := TextureRect.new()
		house.texture = thumbnail
		house.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		house.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		house.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(house)
		var veil := ColorRect.new()
		veil.color = VEIL
		veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(veil)
		return
	# Sinon, un petit jardin vivant.
	var garden := Control.new()
	garden.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	garden.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(garden)
	var screen := get_viewport_rect().size
	for spot in PLANTS:
		var plant := TextureRect.new()
		plant.texture = load(PLANT)
		plant.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		plant.size = Vector2(48, 99)
		plant.position = spot * screen - Vector2(24, 80)
		garden.add_child(plant)
	for spot in WALKERS:
		var walker := BodyPreview.new(1.6)
		walker.appearance = _random_look(&"adulte" if _rng.randf() < 0.7 else &"enfant")
		walker._time = _rng.randf() * 6.0
		walker.position = spot * screen - walker.custom_minimum_size / 2
		walker.size = walker.custom_minimum_size
		garden.add_child(walker)


func _random_look(age: StringName) -> MouzAppearance:
	var look := MouzAppearance.new()
	look.sex = &"femme" if _rng.randf() < 0.5 else &"homme"
	look.age = age
	look.randomize_look(_rng)
	return look


# --- Carte --------------------------------------------------------------------------

func _header() -> Control:
	var header := VBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 0)
	var faces := HBoxContainer.new()
	faces.alignment = BoxContainer.ALIGNMENT_CENTER
	faces.add_theme_constant_override("separation", -12)
	for look in _family_looks():
		var face := MouzPortrait.new(56)
		face.appearance = look
		face.background = Palette.PAPIER_2
		face.ring_width = 3.0
		face.ring_color = Palette.PAPIER
		faces.add_child(face)
	header.add_child(faces)
	var logo := Label.new()
	logo.text = "Les Mouz"
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.add_theme_font_override("font", HudTheme.font(HudTheme.BALOO, 800))
	logo.add_theme_font_size_override("font_size", 60)
	logo.add_theme_constant_override("line_spacing", -10)
	header.add_child(logo)
	var subtitle := Label.new()
	subtitle.text = "Une maison de poche à construire"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.theme_type_variation = &"MutedLabel"
	subtitle.add_theme_font_size_override("font_size", 14)
	header.add_child(subtitle)
	return header


## Portraits de la famille de la dernière partie, ou d'une famille tirée au hasard.
func _family_looks() -> Array:
	var family := SaveManager.latest_family()
	if not family.is_empty():
		return Family.from_dict(family).members.map(func(m: Dictionary) -> MouzAppearance: return m["appearance"])
	return [_random_look(&"adulte"), _random_look(&"adulte"), _random_look(&"enfant"), _random_look(&"aine")]


func _build_menu() -> void:
	_menu.add_theme_constant_override("separation", 10)
	if _latest != "":
		var meta := SaveManager.read_meta(_latest)
		var resume := _button("Continuer : %s" % meta.get("name", "dernière partie"), &"PrimaryButton", "continuer")
		resume.pressed.connect(func() -> void: SaveManager.load_slot(_latest))
		_menu.add_child(resume)
		_menu.add_child(_note("Jour %d · %s · enregistrée %s" % [int(meta.get("day", 1)), meta.get("time", "--:--"),
				TimeFormat.since(float(meta.get("saved", 0)))]))
	var new_game := _button("Nouvelle partie", &"SecondaryButton" if _latest != "" else &"PrimaryButton", "famille")
	new_game.pressed.connect(_new_game)
	_menu.add_child(new_game)
	var has_slots := not SaveManager.list_slots().is_empty()
	var load_game := _button("Charger une partie", &"SecondaryButton", "charger")
	load_game.disabled = not has_slots
	load_game.pressed.connect(_show_load)
	_menu.add_child(load_game)
	if not has_slots:
		_menu.add_child(_note("Aucune partie enregistrée pour l'instant."))
	var quit := _button("Quitter", &"QuietButton", "quitter")
	quit.pressed.connect(func() -> void: get_tree().quit())
	_menu.add_child(quit)


func _new_game() -> void:
	get_tree().change_scene_to_file(NEW_GAME_SCENE)


func _show_menu() -> void:
	_main_card.visible = true
	_menu.visible = true
	_load_panel.visible = false


func _show_load() -> void:
	_main_card.visible = false
	_load_panel.visible = true


func _note(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = &"MutedLabel"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _button(text: String, variation: StringName, icon := "") -> Button:
	var button := Button.new()
	button.text = text
	button.theme_type_variation = variation
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size.y = 44
	button.clip_text = true
	if icon != "":
		button.icon = load("res://assets/icons/white/%s.svg" % icon)
	return button


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _load_panel.visible:
		_show_menu()
		get_viewport().set_input_as_handled()
