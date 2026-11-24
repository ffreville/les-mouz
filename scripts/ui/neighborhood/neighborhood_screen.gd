class_name NeighborhoodScreen
extends Control
## L'écran du quartier : la carte (deux rangées d'emplacements de part et d'autre de la rue)
## et, à droite, la fiche de l'emplacement choisi.
##  - Une famille y vit : ses membres, son argent, « Jouer cette famille ».
##  - Maison à vendre ou terrain libre : son prix, « Faire emménager une famille ».
## Double-clic sur un emplacement : même chose que le bouton de la fiche.

const GRASS := preload("res://assets/floors/herbe.svg")
const COIN := preload("res://assets/sprites/piece_mz.svg")
const PLAY_ICON := preload("res://assets/icons/white/continuer.svg")
const MOVE_IN_ICON := preload("res://assets/icons/white/emmenager.svg")
const MENU_ICON := preload("res://assets/icons/white/menu.svg")
const SIDE_WIDTH := 350.0
const CARD_PLAN := Vector2(186, 124)
const SIDE_PLAN := Vector2(318, 212)
const ROAD := Color("#8E8A99")
const ROAD_LINE := Color("#F3EDE2")
const AGE_NAMES := {&"enfant": "Enfant", &"ado": "Ado", &"adulte": "Adulte", &"aine": "Aîné·e"}

var _plots: Array = []
var _lots: Dictionary = {}
var _cards: Dictionary = {}
var _selected := ""
var _side := VBoxContainer.new()


func _ready() -> void:
	theme = HudTheme.build()
	Music.enter_menu()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if SaveManager.neighborhood.is_empty():
		SaveManager.go_to_title.call_deferred()
		return
	_plots = SaveManager.neighborhood.get("plots", [])
	for plot in _plots:
		_lots[plot["id"]] = LotSerializer.from_data(plot["lot"])
	var grass := TextureRect.new()
	grass.texture = GRASS
	grass.stretch_mode = TextureRect.STRETCH_TILE
	grass.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(grass)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	add_child(margin)
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 10)
	margin.add_child(page)
	page.add_child(_top_bar())
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(body)
	body.add_child(_map())
	var side_panel := PanelContainer.new()
	side_panel.custom_minimum_size.x = SIDE_WIDTH
	_side.add_theme_constant_override("separation", 10)
	side_panel.add_child(_side)
	body.add_child(side_panel)
	_select(_first_selection())


func _first_selection() -> String:
	for plot in _plots:
		if Neighborhood.has_household(plot):
			return plot["id"]
	return _plots[0]["id"] if not _plots.is_empty() else ""


# --- Barre du haut ------------------------------------------------------------------

func _top_bar() -> Control:
	var bar := PanelContainer.new()
	var style := HudTheme.box(Palette.PAPIER, 16, Palette.TRAIT, 2)
	style.content_margin_left = 16
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	bar.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	bar.add_child(row)
	var logo := Label.new()
	logo.text = "Les Mouz"
	logo.add_theme_font_override("font", HudTheme.font(HudTheme.BALOO, 800))
	logo.add_theme_font_size_override("font_size", 24)
	row.add_child(logo)
	var subtitle := Label.new()
	subtitle.text = "· %s · %s" % [SaveManager.neighborhood.get("name", "Quartier"), GameClock.format_time()]
	subtitle.theme_type_variation = &"MutedLabel"
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(subtitle)
	var menu := Button.new()
	menu.text = "Menu principal"
	menu.icon = MENU_ICON
	menu.theme_type_variation = &"QuietButton"
	menu.focus_mode = Control.FOCUS_NONE
	menu.add_theme_constant_override("icon_max_width", 18)
	menu.pressed.connect(SaveManager.go_to_title)
	row.add_child(menu)
	return bar


# --- Carte --------------------------------------------------------------------------

## Deux rangées d'emplacements, la rue entre les deux.
func _map() -> Control:
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	center.add_child(column)
	var half := ceili(_plots.size() / 2.0)
	column.add_child(_row(_plots.slice(0, half)))
	column.add_child(_road(half))
	column.add_child(_row(_plots.slice(half)))
	return center


func _row(plots: Array) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	for plot in plots:
		var card := _plot_card(plot)
		row.add_child(card)
		_cards[plot["id"]] = card
	return row


## La rue des Lilas : une chaussée grise avec ses pointillés.
func _road(count: int) -> Control:
	var road := Control.new()
	road.custom_minimum_size = Vector2(count * (CARD_PLAN.x + 24) + (count - 1) * 12, 56)
	var paint := func() -> void:
		road.draw_rect(Rect2(0, 12, road.size.x, 32), ROAD)
		var x := 8.0
		while x < road.size.x - 8:
			road.draw_line(Vector2(x, 28), Vector2(minf(x + 18, road.size.x - 8), 28), ROAD_LINE, 3)
			x += 32
	road.draw.connect(paint)
	return road


func _plot_card(plot: Dictionary) -> Button:
	var card := Button.new()
	card.theme_type_variation = &"OptionCard"
	card.toggle_mode = true
	card.focus_mode = Control.FOCUS_NONE
	var chosen := HudTheme.box(Palette.ACCENT_DOUX, 14, Palette.ACCENT, 3, 10)
	card.add_theme_stylebox_override("normal", HudTheme.box(Palette.PAPIER, 14, Palette.TRAIT, 2, 10))
	card.add_theme_stylebox_override("hover", HudTheme.box(Palette.PAPIER, 14, Palette.ACCENT, 2, 10))
	card.add_theme_stylebox_override("pressed", chosen)
	card.add_theme_stylebox_override("hover_pressed", chosen)
	card.custom_minimum_size = CARD_PLAN + Vector2(24, 70)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 12
	column.offset_top = 10
	column.offset_right = -12
	column.offset_bottom = -8
	column.add_theme_constant_override("separation", 4)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(column)
	column.add_child(LotPlan.new(_lots[plot["id"]], CARD_PLAN))
	var title := _label(plot["address"], &"StrongLabel", 13)
	column.add_child(title)
	var status := _label(_status_text(plot), &"MutedLabel", 12)
	status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if Neighborhood.has_household(plot):
		status.add_theme_color_override("font_color", Palette.ACCENT_TEXTE)
	column.add_child(status)
	card.pressed.connect(_select.bind(plot["id"]))
	card.gui_input.connect(_on_card_input.bind(plot["id"]))
	return card


## « Famille Martin », « À vendre · 10 500 Mz », « Terrain libre ».
func _status_text(plot: Dictionary) -> String:
	if Neighborhood.has_household(plot):
		return Family.from_dict(plot["household"]["family"]).display_name()
	if plot["house_name"] != "":
		return "À vendre · %s" % Palette.format_mz(int(plot["price"]))
	return "Terrain libre"


func _on_card_input(event: InputEvent, plot_id: String) -> void:
	var click := event as InputEventMouseButton
	if click != null and click.double_click and click.button_index == MOUSE_BUTTON_LEFT:
		_activate(plot_id)


# --- Fiche --------------------------------------------------------------------------

func _select(plot_id: String) -> void:
	_selected = plot_id
	for id in _cards:
		_cards[id].set_pressed_no_signal(id == plot_id)
	for child in _side.get_children():
		child.queue_free()
	var plot := Neighborhood.plot(SaveManager.neighborhood, plot_id)
	if plot.is_empty():
		return
	var title := Label.new()
	title.text = plot["house_name"] if plot["house_name"] != "" else "Terrain libre"
	title.add_theme_font_override("font", HudTheme.font(HudTheme.BALOO, 800))
	title.add_theme_font_size_override("font_size", 24)
	_side.add_child(title)
	var lot: Lot = _lots[plot_id]
	_side.add_child(_label("%s · %d × %d cases" % [plot["address"], lot.size.x, lot.size.y], &"MutedLabel", 13))
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", HudTheme.box(Palette.JARDIN, 10))
	frame.add_child(LotPlan.new(lot, SIDE_PLAN))
	_side.add_child(frame)
	if Neighborhood.has_household(plot):
		_household_details(plot)
	else:
		_sale_details(plot)


func _household_details(plot: Dictionary) -> void:
	var household: Dictionary = plot["household"]
	var family := Family.from_dict(household["family"])
	var section := Label.new()
	section.text = family.display_name().to_upper()
	section.theme_type_variation = &"SectionTitle"
	_side.add_child(section)
	var members := VBoxContainer.new()
	members.add_theme_constant_override("separation", 4)
	for member in family.members:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var face := MouzPortrait.new(34)
		face.appearance = member["appearance"]
		face.background = Palette.PAPIER_2
		row.add_child(face)
		var name_label := _label(member["first_name"], &"StrongLabel", 14)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(name_label)
		var age := _label(AGE_NAMES.get(member["appearance"].age, ""), &"MutedLabel", 12)
		age.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(age)
		members.add_child(row)
	_side.add_child(members)
	_side.add_child(_money_row("Argent du foyer", int(household.get("funds", 0))))
	_side.add_child(_spacer())
	var play := _action_button("Jouer cette famille", PLAY_ICON)
	play.pressed.connect(_activate.bind(plot["id"]))
	_side.add_child(play)


func _sale_details(plot: Dictionary) -> void:
	var price := int(plot["price"])
	if plot["house_name"] != "":
		_side.add_child(_wrapped("Maison meublée, prête à habiter."))
		_side.add_child(_money_row("Prix", price))
	else:
		_side.add_child(_wrapped("Un terrain nu : la famille construit sa maison avec son budget."))
		_side.add_child(_money_row("Prix", 0))
	_side.add_child(_money_row("Budget d'une nouvelle famille", Wallet.settings.start_funds))
	_side.add_child(_spacer())
	var move_in := _action_button("Faire emménager une famille", MOVE_IN_ICON)
	move_in.disabled = price > Wallet.settings.start_funds
	if move_in.disabled:
		move_in.tooltip_text = "Trop cher pour une nouvelle famille."
	move_in.pressed.connect(_activate.bind(plot["id"]))
	_side.add_child(move_in)


## Jouer la famille de l'emplacement, ou y faire emménager une nouvelle famille.
func _activate(plot_id: String) -> void:
	var plot := Neighborhood.plot(SaveManager.neighborhood, plot_id)
	if Neighborhood.has_household(plot):
		SaveManager.play(plot_id)
	elif int(plot.get("price", 0)) <= Wallet.settings.start_funds:
		SaveManager.create_family_for(plot_id)


# --- Petits éléments ----------------------------------------------------------------

func _money_row(text: String, amount: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var label := _label(text, &"MutedLabel", 13)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var coin := TextureRect.new()
	coin.texture = COIN
	coin.custom_minimum_size = Vector2(16, 16)
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(coin)
	row.add_child(_label("Gratuit" if amount == 0 else Palette.format_mz(amount), &"StrongLabel", 14))
	return row


func _action_button(text: String, icon: Texture2D) -> Button:
	var button := Button.new()
	button.text = text
	button.icon = icon
	button.theme_type_variation = &"PrimaryButton"
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size.y = 44
	button.add_theme_constant_override("icon_max_width", 18)
	return button


func _wrapped(text: String) -> Label:
	var label := _label(text, &"MutedLabel", 13)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _spacer() -> Control:
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return spacer


func _label(text: String, variation: StringName, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variation
	label.add_theme_font_size_override("font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		SaveManager.go_to_title()
		get_viewport().set_input_as_handled()
