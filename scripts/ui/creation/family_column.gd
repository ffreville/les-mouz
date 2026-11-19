class_name FamilyColumn
extends PanelContainer
## Colonne de gauche : nom de famille (avec dé), cartes des membres reliées par leurs liens,
## « Ajouter un membre » tant qu'il reste de la place, et le rappel de la règle des adultes.

signal member_chosen(member: Dictionary)
signal family_changed

const DICE := preload("res://assets/icons/ink/hasard.svg")
const ADD_ICON := preload("res://assets/icons/ink/ajouter_membre.svg")
const HEART := preload("res://assets/icons/ink/relation.svg")

var family: Family
var selected: Dictionary
var _rng := RandomNumberGenerator.new()
var _family_name := LineEdit.new()
var _count := Label.new()
var _list := VBoxContainer.new()
var _rule := PanelContainer.new()
var _cards: Array[MemberCard] = []


func _ready() -> void:
	_rng.randomize()
	custom_minimum_size.x = 308
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	add_child(column)
	column.add_child(MemberEditor._title("NOM DE FAMILLE"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_family_name.max_length = 20
	_family_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_family_name.text_changed.connect(_on_family_name)
	row.add_child(_family_name)
	var dice := Button.new()
	dice.icon = DICE
	dice.tooltip_text = "Tirer un nom au hasard"
	dice.focus_mode = Control.FOCUS_NONE
	dice.custom_minimum_size = Vector2(44, 40)
	dice.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dice.add_theme_constant_override("icon_max_width", 20)
	dice.add_theme_stylebox_override("normal", HudTheme.box(Palette.PAPIER_2, 10))
	dice.pressed.connect(_on_random_family_name)
	row.add_child(dice)
	column.add_child(row)
	var hint := Label.new()
	hint.text = "Sert aussi de nom à la partie."
	hint.theme_type_variation = &"MutedLabel"
	column.add_child(hint)
	var header := HBoxContainer.new()
	var members_title := MemberEditor._title("MEMBRES")
	members_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(members_title)
	_count.theme_type_variation = &"SectionTitle"
	header.add_child(_count)
	column.add_child(MemberEditor._gap(4))
	column.add_child(header)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 4)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	column.add_child(scroll)
	_rule.add_theme_stylebox_override("panel", HudTheme.box(Palette.CRITIQUE_DOUX, 10, Color.TRANSPARENT, 0, 10))
	var rule_text := Label.new()
	rule_text.text = "Il faut au moins un adulte ou un aîné dans la famille."
	rule_text.add_theme_color_override("font_color", Palette.CRITIQUE)
	rule_text.add_theme_font_size_override("font_size", 12)
	rule_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rule.add_child(rule_text)
	column.add_child(_rule)


func setup(p_family: Family) -> void:
	family = p_family
	_family_name.text = family.family_name
	selected = family.members[0]
	rebuild()


## Reconstruit les cartes (après un ajout, un retrait ou un changement de lien).
func rebuild() -> void:
	for child in _list.get_children():
		child.queue_free()
	_cards.clear()
	for i in family.members.size():
		var member := family.members[i]
		if i > 0:
			_list.add_child(_link_pill(family.members[i - 1], member))
		var card := MemberCard.new(member)
		card.pressed.connect(_choose.bind(member))
		card.remove_requested.connect(_remove.bind(member))
		_list.add_child(card)
		_cards.append(card)
	if family.members.size() < Family.MAX_MEMBERS:
		_list.add_child(_add_card())
	refresh()


## Met à jour le texte des cartes et la règle, sans reconstruire.
func refresh() -> void:
	_count.text = "%d / %d" % [family.members.size(), Family.MAX_MEMBERS]
	for card in _cards:
		card.refresh(family.members.size() > 1)
		card.set_pressed_no_signal(card.member == selected)
	_rule.visible = not family.has_grown_up()


func _choose(member: Dictionary) -> void:
	selected = member
	refresh()
	member_chosen.emit(member)


func _remove(member: Dictionary) -> void:
	if family.members.size() <= 1:
		return
	var index := family.members.find(member)
	family.remove_member(member)
	if selected == member:
		selected = family.members[clampi(index - 1, 0, family.members.size() - 1)]
	rebuild()
	member_chosen.emit(selected)
	family_changed.emit()


func _add_member() -> void:
	var look := MouzAppearance.new()
	look.sex = &"femme" if _rng.randf() < 0.5 else &"homme"
	look.age = &"enfant" if family.has_grown_up() else &"adulte"
	look.randomize_look(_rng)
	var taken: Array = family.members.map(func(m: Dictionary) -> String: return m["first_name"])
	selected = family.add_member(NameIdeas.first_name(look.sex, _rng, taken), look)
	rebuild()
	member_chosen.emit(selected)
	family_changed.emit()


func _add_card() -> Button:
	var card := Button.new()
	card.custom_minimum_size = MemberCard.SIZE
	card.focus_mode = Control.FOCUS_NONE
	card.icon = ADD_ICON
	card.add_theme_constant_override("icon_max_width", 22)
	card.text = "Ajouter un membre\n%d / %d places" % [family.members.size(), Family.MAX_MEMBERS]
	card.alignment = HORIZONTAL_ALIGNMENT_LEFT
	card.add_theme_font_size_override("font_size", 13)
	var dashed := HudTheme.box(Color.TRANSPARENT, 14, Palette.TRAIT, 2, 14)
	card.add_theme_stylebox_override("normal", dashed)
	card.add_theme_stylebox_override("hover", HudTheme.box(Color.WHITE, 14, Palette.ACCENT, 2, 14))
	card.add_theme_stylebox_override("pressed", HudTheme.box(Palette.ACCENT_DOUX, 14, Palette.ACCENT, 2, 14))
	card.pressed.connect(_add_member)
	return card


## Petite pastille entre deux cartes : le lien qui les unit (menu au clic).
func _link_pill(a: Dictionary, b: Dictionary) -> Control:
	var center := CenterContainer.new()
	var pill := MenuButton.new()
	var kind := family.link_between(a["id"], b["id"])
	pill.text = (Family.LINK_NAMES[kind] if kind != &"" else "Lien") + "  ▾"
	pill.icon = HEART
	pill.flat = false
	pill.focus_mode = Control.FOCUS_NONE
	pill.add_theme_constant_override("icon_max_width", 12)
	pill.add_theme_font_size_override("font_size", 11)
	pill.add_theme_stylebox_override("normal", HudTheme.box(Palette.PAPIER_2, 10, Palette.TRAIT, 1, 4))
	pill.add_theme_stylebox_override("hover", HudTheme.box(Color.WHITE, 10, Palette.ACCENT, 1, 4))
	pill.tooltip_text = "Lien entre %s et %s : il fixe leur relation de départ." % [a["first_name"], b["first_name"]]
	var popup := pill.get_popup()
	var kinds: Array[StringName] = [&""]
	kinds.append_array(Family.LINK_KINDS)
	for i in kinds.size():
		popup.add_item(_link_choice_label(kinds[i], a, b), i)
	popup.id_pressed.connect(func(id: int) -> void: _set_link(a, b, kinds[id]))
	center.add_child(pill)
	return center


static func _link_choice_label(kind: StringName, a: Dictionary, b: Dictionary) -> String:
	match kind:
		&"parent":
			return "%s est parent de %s" % [a["first_name"], b["first_name"]]
		&"enfant":
			return "%s est enfant de %s" % [a["first_name"], b["first_name"]]
	return Family.LINK_NAMES[kind]


func _set_link(a: Dictionary, b: Dictionary, kind: StringName) -> void:
	family.set_link(a["id"], b["id"], kind)
	rebuild()


func _on_family_name(text: String) -> void:
	family.family_name = text
	family_changed.emit()


func _on_random_family_name() -> void:
	_family_name.text = NameIdeas.family_name(_rng)
	_on_family_name(_family_name.text)
