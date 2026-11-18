class_name CatalogPanel
extends PanelContainer
## Catalogue du mode Acheter : onglets de catégorie et vignettes (image, nom, prix).
## Une vignette trop chère est grisée et refuse le clic.

const COIN := preload("res://assets/sprites/piece_mz.svg")
const CARD_SIZE := Vector2(120, 140)

var _tabs := HBoxContainer.new()
var _cards := HBoxContainer.new()
var _category: StringName = &"cuisine"
var _tab_buttons: Dictionary[StringName, Button] = {}
var _card_buttons: Dictionary[Resource, Button] = {}


func _ready() -> void:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	add_child(column)

	var header := HBoxContainer.new()
	column.add_child(header)
	_tabs.add_theme_constant_override("separation", 6)
	_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_tabs)
	var hint := Label.new()
	hint.text = "R pour tourner · Échap pour lâcher · clic sur un objet posé pour le déplacer ou le revendre"
	hint.theme_type_variation = &"MutedLabel"
	header.add_child(hint)
	for spec in Catalog.CATEGORIES:
		_tabs.add_child(_make_tab(spec[0], spec[1]))

	var scroll := ScrollContainer.new()
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size.y = CARD_SIZE.y
	column.add_child(scroll)
	_cards.add_theme_constant_override("separation", 12)
	scroll.add_child(_cards)

	EventBus.money_changed.connect(func(_funds: int, _delta: int) -> void: _refresh_affordability())
	EventBus.placement_ended.connect(_on_placement_ended)
	_show_category(_category)


func _make_tab(category: StringName, title: String) -> Button:
	var button := Button.new()
	button.theme_type_variation = &"CategoryTab"
	button.text = title
	button.icon = load("res://assets/icons/white/%s.svg" % category)
	button.toggle_mode = true
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size.y = 34
	button.pressed.connect(_show_category.bind(category))
	_tab_buttons[category] = button
	return button


func _show_category(category: StringName) -> void:
	_category = category
	for key in _tab_buttons:
		_tab_buttons[key].set_pressed_no_signal(key == category)
	for child in _cards.get_children():
		child.queue_free()
	_card_buttons.clear()
	for definition in Catalog.objects_in(category):
		var card := _make_card(definition)
		_cards.add_child(card)
		_card_buttons[definition] = card
	_refresh_affordability()


func _make_card(definition: SmartObjectDefinition) -> Button:
	var card := Button.new()
	card.theme_type_variation = &"OptionCard"
	card.toggle_mode = true
	card.focus_mode = Control.FOCUS_NONE
	card.custom_minimum_size = CARD_SIZE
	card.tooltip_text = "%s · %s · %d × %d cases" % [definition.display_name,
			Palette.format_mz(definition.price), definition.size.x, definition.size.y]
	card.pressed.connect(_on_card_pressed.bind(definition))

	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 8
	column.offset_top = 8
	column.offset_right = -8
	column.offset_bottom = -8
	column.add_theme_constant_override("separation", 2)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(column)

	var frame := PanelContainer.new()
	frame.name = "Frame"
	frame.custom_minimum_size = Vector2(104, 72)
	frame.add_theme_stylebox_override("panel", HudTheme.box(Palette.PAPIER_2, 8, Color.TRANSPARENT, 0, 6))
	var image := TextureRect.new()
	image.texture = definition.sprite
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
	for control in [frame, image, title, row, coin, price, too_expensive]:
		control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return card


func _on_card_pressed(definition: SmartObjectDefinition) -> void:
	for key in _card_buttons:
		_card_buttons[key].set_pressed_no_signal(key == definition)
	EventBus.catalog_item_selected.emit(definition)


func _on_placement_ended() -> void:
	for key in _card_buttons:
		_card_buttons[key].set_pressed_no_signal(false)


## Grise les objets trop chers pour le solde actuel.
func _refresh_affordability() -> void:
	for definition in _card_buttons:
		var card := _card_buttons[definition]
		var affordable := Wallet.can_afford(definition.price)
		card.disabled = not affordable
		var price: Label = card.find_child("Price", true, false)
		price.add_theme_color_override("font_color", Palette.ENCRE if affordable else Palette.CRITIQUE)
		card.find_child("TooExpensive", true, false).visible = not affordable
		card.find_child("Frame", true, false).modulate = Color.WHITE if affordable else Color(1, 1, 1, 0.4)
