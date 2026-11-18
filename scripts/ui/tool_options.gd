class_name ToolOptions
extends GridContainer
## Options de l'outil actif : couleurs de mur, revêtements de sol, modèles de porte ou de fenêtre.

signal option_selected(option: Resource)

const COIN := preload("res://assets/sprites/piece_mz.svg")

## Option choisie pour l'outil courant (null si l'outil n'en a pas).
var selected: Resource
## Dernier choix par outil, pour le retrouver en revenant sur l'outil.
var _memory: Dictionary[StringName, Resource] = {}
var _tool: StringName


func _ready() -> void:
	add_theme_constant_override("h_separation", 6)
	add_theme_constant_override("v_separation", 6)


func show_for(tool: StringName) -> void:
	_tool = tool
	for child in get_children():
		child.queue_free()
	var items: Array = []
	match tool:
		&"wall":
			columns = 2
			items = Catalog.load_folder(Catalog.WALLS)
		_:
			columns = 1
	selected = _memory.get(tool, items[0] if not items.is_empty() else null)
	var group := ButtonGroup.new()
	for item in items:
		var card := _wall_card(item)
		card.button_group = group
		card.button_pressed = item == selected
		card.pressed.connect(_choose.bind(item))
		add_child(card)


func _choose(item: Resource) -> void:
	selected = item
	_memory[_tool] = item
	option_selected.emit(item)


## Carte d'une couleur de mur : pastille, nom et prix par segment.
func _wall_card(style: WallStyleDefinition) -> Button:
	var card := _card(Vector2(113, 48))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var swatch := Panel.new()
	swatch.custom_minimum_size = Vector2(22, 22)
	swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	swatch.add_theme_stylebox_override("panel", HudTheme.box(style.color, 6))
	row.add_child(swatch)
	row.add_child(_name_and_price(style.display_name, style.price_per_segment))
	_fill(card, row)
	return card


func _card(min_size: Vector2) -> Button:
	var card := Button.new()
	card.theme_type_variation = &"OptionCard"
	card.toggle_mode = true
	card.focus_mode = Control.FOCUS_NONE
	card.custom_minimum_size = min_size
	return card


func _name_and_price(title: String, price: int) -> Control:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var label := Label.new()
	label.text = title
	label.theme_type_variation = &"StrongLabel"
	label.add_theme_font_size_override("font_size", 12)
	column.add_child(label)
	var price_label := Label.new()
	price_label.text = Palette.format_mz(price)
	price_label.theme_type_variation = &"MutedLabel"
	price_label.add_theme_font_size_override("font_size", 11)
	column.add_child(price_label)
	return column


## Place un contenu dans une carte (bouton), sans capter les clics.
func _fill(card: Button, content: Control) -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8)
	_ignore_mouse(content)
	margin.add_child(content)
	card.add_child(margin)


func _ignore_mouse(control: Control) -> void:
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in control.get_children():
		if child is Control:
			_ignore_mouse(child)
