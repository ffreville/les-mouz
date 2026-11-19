class_name LotStep
extends VBoxContainer
## Deuxième étape : la famille en haut (portraits, nom, prénoms), le nom de la partie,
## le budget, puis les terrains côte à côte.

signal selection_changed

const COIN := preload("res://assets/sprites/piece_mz.svg")

var chosen: LotOffer
var game_name := LineEdit.new()
var _faces := HBoxContainer.new()
var _family_title := Label.new()
var _first_names := Label.new()
var _cards: Array[LotOfferCard] = []


func _ready() -> void:
	add_theme_constant_override("separation", 16)
	var header := PanelContainer.new()
	add_child(header)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	header.add_child(row)
	_faces.add_theme_constant_override("separation", -10)
	_faces.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_faces)
	var names := VBoxContainer.new()
	names.alignment = BoxContainer.ALIGNMENT_CENTER
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.add_theme_constant_override("separation", 0)
	_family_title.add_theme_font_override("font", HudTheme.font(HudTheme.BALOO, 800))
	_family_title.add_theme_font_size_override("font_size", 24)
	_first_names.theme_type_variation = &"MutedLabel"
	_first_names.add_theme_font_size_override("font_size", 13)
	names.add_child(_family_title)
	names.add_child(_first_names)
	row.add_child(names)
	var name_column := VBoxContainer.new()
	name_column.add_child(MemberEditor._title("NOM DE LA PARTIE"))
	game_name.custom_minimum_size.x = 340
	game_name.max_length = 40
	name_column.add_child(game_name)
	row.add_child(name_column)
	var budget_column := VBoxContainer.new()
	budget_column.add_child(MemberEditor._title("BUDGET"))
	var budget := Button.new()
	budget.text = Palette.format_mz(Wallet.settings.start_funds)
	budget.icon = COIN
	budget.disabled = true
	budget.add_theme_font_override("font", HudTheme.font(HudTheme.NUNITO, 800))
	budget.add_theme_font_size_override("font_size", 17)
	budget.add_theme_color_override("font_disabled_color", Palette.ENCRE)
	budget.add_theme_constant_override("icon_max_width", 20)
	budget.add_theme_stylebox_override("disabled", HudTheme.box(Palette.PAPIER_2, 12, Color.TRANSPARENT, 0, 8))
	budget_column.add_child(budget)
	row.add_child(budget_column)

	var cards := HBoxContainer.new()
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	cards.add_theme_constant_override("separation", 20)
	add_child(cards)
	for offer in Catalog.lot_offers():
		var card := LotOfferCard.new(offer)
		card.disabled = offer.price > Wallet.settings.start_funds
		card.pressed.connect(_choose.bind(offer))
		cards.add_child(card)
		_cards.append(card)
	if not _cards.is_empty():
		_choose(_cards[0].offer)


func show_family(family: Family) -> void:
	for child in _faces.get_children():
		child.queue_free()
	for member in family.members:
		var face := MouzPortrait.new(44)
		face.appearance = member["appearance"]
		face.background = Palette.PAPIER_2
		face.ring_width = 2.0
		face.ring_color = Palette.PAPIER
		_faces.add_child(face)
	_family_title.text = family.display_name()
	_first_names.text = family.first_names()
	var suggested := "La maison des %s" % family.family_name if family.family_name.strip_edges() != "" else "Nouvelle partie"
	if game_name.text == "" or game_name.has_meta("suggested") and game_name.text == game_name.get_meta("suggested"):
		game_name.text = suggested
	game_name.set_meta("suggested", suggested)


## Budget restant une fois le terrain payé.
func remaining() -> int:
	return Wallet.settings.start_funds - (chosen.price if chosen != null else 0)


func _choose(offer: LotOffer) -> void:
	chosen = offer
	for card in _cards:
		card.set_pressed_no_signal(card.offer == offer)
	selection_changed.emit()
