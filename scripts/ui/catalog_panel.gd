class_name CatalogPanel
extends PanelContainer
## Catalogue du mode Acheter : onglets de catégorie (seul l'actif garde son libellé),
## filtre par collection, et une vignette par objet et par collection (image, nom, prix, style).
## « Toutes » montre chaque objet dans toutes ses collections ; un filtre n'en garde qu'une.
## Une vignette trop chère est grisée et refuse le clic.

const COIN := preload("res://assets/sprites/piece_mz.svg")
const CARD_SIZE := Vector2(120, 168)
const DOT_SIZE := 20.0

var _tabs := HBoxContainer.new()
var _filters := HBoxContainer.new()
var _cards := HBoxContainer.new()
var _category: StringName = &"cuisine"
## Collection filtrée (&"" = toutes).
var _filter: StringName = &""
var _tab_buttons: Dictionary[StringName, Button] = {}
var _filter_buttons: Dictionary[StringName, Button] = {}
## Vignettes affichées, par clé « objet|collection ».
var _card_buttons: Dictionary[String, Button] = {}
## Vignette de l'objet en cours de placement ("" = aucune).
var _selected := ""


func _ready() -> void:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	add_child(column)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	column.add_child(header)
	_tabs.add_theme_constant_override("separation", 6)
	header.add_child(_tabs)
	for spec in Catalog.CATEGORIES:
		_tabs.add_child(_make_tab(spec[0], spec[1]))
	header.add_child(_make_filter_group())
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var hint := Label.new()
	hint.text = "R : tourner · Échap : lâcher"
	# Au doigt, la barre de placement remplace ces touches.
	hint.visible = not Device.mobile
	hint.theme_type_variation = &"MutedLabel"
	header.add_child(hint)

	var scroll := ScrollContainer.new()
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size.y = CARD_SIZE.y
	column.add_child(scroll)
	_cards.add_theme_constant_override("separation", 12)
	scroll.add_child(_cards)

	EventBus.money_changed.connect(func(_funds: int, _delta: int) -> void: _refresh_affordability())
	EventBus.placement_ended.connect(_on_placement_ended)
	_show_category(_category)


# --- Onglets et filtre --------------------------------------------------------------

func _make_tab(category: StringName, title: String) -> Button:
	var button := Button.new()
	button.theme_type_variation = &"CategoryTab"
	button.icon = load("res://assets/icons/white/%s.svg" % category)
	button.tooltip_text = title
	button.set_meta("title", title)
	button.toggle_mode = true
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(36, 34)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.pressed.connect(_show_category.bind(category))
	_tab_buttons[category] = button
	return button


## « Toutes / Nature / Rétro / Moderne » dans un groupe arrondi.
func _make_filter_group() -> Control:
	var group := PanelContainer.new()
	group.theme_type_variation = &"SpeedGroup"
	group.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_filters.add_theme_constant_override("separation", 2)
	group.add_child(_filters)
	_filters.add_child(_make_filter(&"", "Toutes", null))
	for collection in Catalog.collections():
		_filters.add_child(_make_filter(collection.id, collection.display_name, collection))
	return group


func _make_filter(id: StringName, title: String, collection: CollectionDefinition) -> Button:
	var button := Button.new()
	button.theme_type_variation = &"ModeTab"
	button.text = title
	button.toggle_mode = true
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size.y = 30
	button.add_theme_font_size_override("font_size", 13)
	if collection != null:
		# Point de couleur signature devant le nom.
		var image := Image.create(12, 12, false, Image.FORMAT_RGBA8)
		image.fill(Color.TRANSPARENT)
		for y in 12:
			for x in 12:
				var d := Vector2(x + 0.5, y + 0.5).distance_to(Vector2(6, 6))
				if d <= 6.0:
					image.set_pixel(x, y, Palette.ENCRE if d > 4.5 else collection.color)
		button.icon = ImageTexture.create_from_image(image)
		for state in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_hover_pressed_color"]:
			button.add_theme_color_override(state, Color.WHITE)
	button.pressed.connect(_set_filter.bind(id))
	_filter_buttons[id] = button
	button.set_pressed_no_signal(id == _filter)
	return button


func _set_filter(id: StringName) -> void:
	_filter = id
	for key in _filter_buttons:
		_filter_buttons[key].set_pressed_no_signal(key == id)
	_show_category(_category)


func _show_category(category: StringName) -> void:
	_category = category
	for key in _tab_buttons:
		var active := key == category
		var button := _tab_buttons[key]
		button.set_pressed_no_signal(active)
		button.text = button.get_meta("title") if active else ""
		button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT if active else HORIZONTAL_ALIGNMENT_CENTER
	for child in _cards.get_children():
		child.queue_free()
	_card_buttons.clear()
	for definition in Catalog.objects_in(category):
		for collection in Catalog.collections():
			if not definition.sprites.has(collection.id) or (_filter != &"" and collection.id != _filter):
				continue
			var card := _make_card(definition, collection)
			_cards.add_child(card)
			var key := _key(definition, collection.id)
			_card_buttons[key] = card
			card.set_pressed_no_signal(key == _selected)
	_refresh_affordability()


# --- Vignettes ------------------------------------------------------------------------

static func _key(definition: SmartObjectDefinition, collection: StringName) -> String:
	return "%s|%s" % [definition.resource_path, collection]


func _make_card(definition: SmartObjectDefinition, collection: CollectionDefinition) -> Button:
	var card := Button.new()
	card.theme_type_variation = &"OptionCard"
	card.toggle_mode = true
	card.focus_mode = Control.FOCUS_NONE
	card.custom_minimum_size = CARD_SIZE
	card.tooltip_text = "%s · %s · %s · %d × %d cases" % [definition.display_name, collection.display_name,
			Palette.format_mz(definition.price), definition.size.x, definition.size.y]
	card.set_meta("definition", definition)
	card.pressed.connect(_on_card_pressed.bind(definition, collection.id))

	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 8
	column.offset_top = 8
	column.offset_right = -8
	column.offset_bottom = -6
	column.add_theme_constant_override("separation", 2)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(column)

	var frame := PanelContainer.new()
	frame.name = "Frame"
	frame.custom_minimum_size = Vector2(104, 72)
	frame.add_theme_stylebox_override("panel", HudTheme.box(Palette.PAPIER_2, 8, Color.TRANSPARENT, 0, 6))
	var image := TextureRect.new()
	image.name = "Image"
	image.texture = definition.get_catalog_sprite(collection.id)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame.add_child(image)
	column.add_child(frame)

	var title := Label.new()
	title.text = definition.display_name
	title.theme_type_variation = &"StrongLabel"
	title.add_theme_font_size_override("font_size", 13)
	title.clip_text = true
	column.add_child(title)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var coin := TextureRect.new()
	coin.texture = COIN
	coin.custom_minimum_size = Vector2(14, 14)
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(coin)
	var price := Label.new()
	price.name = "Price"
	price.text = Palette.format_mz(definition.price)
	price.theme_type_variation = &"StrongLabel"
	price.add_theme_font_size_override("font_size", 13)
	row.add_child(price)
	var too_expensive := Label.new()
	too_expensive.name = "TooExpensive"
	too_expensive.text = "Trop cher"
	too_expensive.add_theme_color_override("font_color", Palette.CRITIQUE)
	too_expensive.add_theme_font_size_override("font_size", 11)
	too_expensive.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(too_expensive)
	column.add_child(row)

	var line := ColorRect.new()
	line.color = Palette.PAPIER_2
	line.custom_minimum_size.y = 2
	column.add_child(line)
	var style := _make_style_row(collection)
	column.add_child(style)
	for control in [frame, image, title, row, coin, price, too_expensive, line, style]:
		control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return card


## Pastille et nom de la collection de la vignette.
func _make_style_row(collection: CollectionDefinition) -> Control:
	var style := HBoxContainer.new()
	style.add_theme_constant_override("separation", 4)
	var dot := CollectionDot.new(collection, 12.0)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.selected = false
	style.add_child(dot)
	var label := Label.new()
	label.text = collection.display_name
	label.theme_type_variation = &"MutedLabel"
	label.add_theme_font_size_override("font_size", 11)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	style.add_child(label)
	return style


func _on_card_pressed(definition: SmartObjectDefinition, collection: StringName) -> void:
	_selected = _key(definition, collection)
	for key in _card_buttons:
		_card_buttons[key].set_pressed_no_signal(key == _selected)
	EventBus.catalog_item_selected.emit(definition, collection)


func _on_placement_ended() -> void:
	_selected = ""
	for key in _card_buttons:
		_card_buttons[key].set_pressed_no_signal(false)


## Grise les objets trop chers pour le solde actuel.
func _refresh_affordability() -> void:
	for key in _card_buttons:
		var card := _card_buttons[key]
		var definition: SmartObjectDefinition = card.get_meta("definition")
		var affordable := Wallet.can_afford(definition.price)
		card.disabled = not affordable
		var price: Label = card.find_child("Price", true, false)
		price.add_theme_color_override("font_color", Palette.ENCRE if affordable else Palette.CRITIQUE)
		card.find_child("TooExpensive", true, false).visible = not affordable
		card.find_child("Frame", true, false).modulate = Color.WHITE if affordable else Color(1, 1, 1, 0.4)
