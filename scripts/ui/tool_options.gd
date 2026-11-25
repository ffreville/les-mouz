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
		&"floor":
			columns = 3
			# L'herbe est le sol par défaut : on l'obtient avec la gomme.
			items = Catalog.load_folder(Catalog.FLOORS).filter(func(f): return f.price_per_cell > 0)
		&"room":
			_show_room()
			return
		&"wallpaper":
			columns = 2
			items = [_no_wallpaper()]
			items.append_array(Catalog.load_folder(Catalog.WALLPAPERS))
		&"door", &"window":
			columns = 2
			var kind := OpeningDefinition.Kind.DOOR if tool == &"door" else OpeningDefinition.Kind.WINDOW
			items = Catalog.load_folder(Catalog.OPENINGS).filter(func(o): return o.kind == kind)
		_:
			columns = 1
	selected = _memory.get(tool, items[0] if not items.is_empty() else null)
	var group := ButtonGroup.new()
	for item in items:
		var card: Button
		if item is WallpaperDefinition:
			card = _wallpaper_card(item)
		elif item is WallStyleDefinition:
			card = _wall_card(item)
		elif item is FloorDefinition:
			card = _floor_card(item)
		else:
			card = _opening_card(item)
		card.button_group = group
		card.button_pressed = item == selected
		card.pressed.connect(_choose.bind(item))
		add_child(card)


## Pièce : deux listes, la couleur des murs puis le sol (le dernier choix des outils Mur et Sol).
func _show_room() -> void:
	columns = 1
	var style: RoomStyle = _memory.get(&"room")
	var walls := Catalog.load_folder(Catalog.WALLS)
	var floors := Catalog.load_folder(Catalog.FLOORS).filter(func(f): return f.price_per_cell > 0)
	if style == null:
		style = RoomStyle.new()
		style.wall = _memory.get(&"wall", walls[0])
		style.floor = _memory.get(&"floor", floors[0])
		_memory[&"room"] = style
	selected = style
	for part in [["MURS", walls, 2], ["SOL", floors, 4]]:
		var title := Label.new()
		title.text = part[0]
		title.theme_type_variation = &"SectionTitle"
		add_child(title)
		var grid := GridContainer.new()
		grid.columns = part[2]
		grid.add_theme_constant_override("h_separation", 6)
		grid.add_theme_constant_override("v_separation", 6)
		add_child(grid)
		var group := ButtonGroup.new()
		for item in part[1]:
			var card: Button = _wall_card(item) if item is WallStyleDefinition else _floor_swatch(item)
			card.button_group = group
			card.button_pressed = item == style.wall or item == style.floor
			card.pressed.connect(_choose_room_part.bind(item))
			grid.add_child(card)


func _choose_room_part(item: Resource) -> void:
	var style: RoomStyle = _memory[&"room"]
	if item is WallStyleDefinition:
		style.wall = item
	else:
		style.floor = item
	selected = style
	option_selected.emit(style)


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


## Carte d'un revêtement : aperçu en mosaïque, nom et prix par case.
func _floor_card(definition: FloorDefinition) -> Button:
	var card := _card(Vector2(72, 104))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	var preview := TextureRect.new()
	preview.texture = definition.texture
	preview.custom_minimum_size = Vector2(56, 56)
	preview.stretch_mode = TextureRect.STRETCH_TILE
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	column.add_child(preview)
	var label := Label.new()
	label.text = definition.display_name
	label.theme_type_variation = &"StrongLabel"
	label.add_theme_font_size_override("font_size", 11)
	label.clip_text = true
	column.add_child(label)
	var price := Label.new()
	price.text = Palette.format_mz(definition.price_per_cell)
	price.theme_type_variation = &"MutedLabel"
	price.add_theme_font_size_override("font_size", 11)
	column.add_child(price)
	_fill(card, column)
	card.tooltip_text = "%s · %s par case" % [definition.display_name, Palette.format_mz(definition.price_per_cell)]
	return card


## L'option « Retirer » du papier peint (revend celui de la pièce).
static var _remove_paper: WallpaperDefinition


static func _no_wallpaper() -> WallpaperDefinition:
	if _remove_paper == null:
		_remove_paper = WallpaperDefinition.new()
		_remove_paper.id = LotEditor.NO_WALLPAPER
		_remove_paper.display_name = "Retirer"
		_remove_paper.price_per_segment = 0
	return _remove_paper


## Carte d'un papier peint : échantillon, nom et prix par pan de mur.
func _wallpaper_card(definition: WallpaperDefinition) -> Button:
	var card := _card(Vector2(113, 48))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var swatch := Control.new()
	swatch.custom_minimum_size = Vector2(22, 30)
	swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var paint := func() -> void:
		if definition.id == LotEditor.NO_WALLPAPER:
			swatch.draw_rect(Rect2(Vector2.ZERO, swatch.size), Palette.PAPIER_2)
			swatch.draw_line(Vector2(3, 3), swatch.size - Vector2(3, 3), Palette.CRITIQUE, 2.0)
		else:
			definition.draw(swatch, Rect2(Vector2.ZERO, swatch.size))
		swatch.draw_rect(Rect2(Vector2.ZERO, swatch.size), Palette.TRAIT, false, 1.0)
	swatch.draw.connect(paint)
	row.add_child(swatch)
	if definition.id == LotEditor.NO_WALLPAPER:
		var label := Label.new()
		label.text = "Retirer"
		label.theme_type_variation = &"StrongLabel"
		label.add_theme_font_size_override("font_size", 12)
		label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(label)
	else:
		row.add_child(_name_and_price(definition.display_name, definition.price_per_segment))
	_fill(card, row)
	card.tooltip_text = definition.display_name
	return card


## Petite vignette de sol (outil Pièce) : le nom et le prix sont dans l'info-bulle.
func _floor_swatch(definition: FloorDefinition) -> Button:
	var card := _card(Vector2(56, 56))
	var preview := TextureRect.new()
	preview.texture = definition.texture
	preview.stretch_mode = TextureRect.STRETCH_TILE
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.custom_minimum_size = Vector2(36, 36)
	_fill(card, preview)
	card.tooltip_text = "%s · %s par case" % [definition.display_name, Palette.format_mz(definition.price_per_cell)]
	return card


## Carte d'une porte ou d'une fenêtre : vignette, nom et prix.
func _opening_card(definition: OpeningDefinition) -> Button:
	var card := _card(Vector2(113, 92))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	var preview := TextureRect.new()
	preview.texture = definition.sprite
	preview.custom_minimum_size = Vector2(64, 40)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	column.add_child(preview)
	column.add_child(_name_and_price(definition.display_name, definition.price))
	_fill(card, column)
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
