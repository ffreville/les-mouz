class_name MemberEditor
extends PanelContainer
## Éditeur du membre choisi, en deux colonnes :
##  - prénom (avec dé), sexe, âge, « Apparence au hasard » ;
##  - peau, coupe, couleur des cheveux, tenue, couleur de la tenue.
## Émet `changed` à chaque modification.

signal changed

const DICE := preload("res://assets/icons/ink/hasard.svg")
const DICE_WHITE := preload("res://assets/icons/white/hasard.svg")
const HAIR_CELL := Vector2(56, 52)

var _member: Dictionary
var _rng := RandomNumberGenerator.new()
var _first_name := LineEdit.new()
var _name_error := Label.new()
var _sex := ChoiceGroup.new([[&"homme", "Homme", load("res://assets/icons/white/homme.svg")],
		[&"femme", "Femme", load("res://assets/icons/white/femme.svg")]])
var _age := ChoiceGroup.new([[&"enfant", "Enfant", load("res://assets/icons/white/enfant.svg")],
		[&"ado", "Ado", load("res://assets/icons/white/ado.svg")],
		[&"adulte", "Adulte", load("res://assets/icons/white/adulte.svg")],
		[&"aine", "Aîné", load("res://assets/icons/white/aine.svg")]], true)
var _skin := ColorSwatches.new(MouzAppearance.SKINS, 22)
var _hair_grid := GridContainer.new()
var _all_hair := Button.new()
var _show_all_hair := false
var _hair_color := ColorSwatches.new(MouzAppearance.HAIR_COLORS, 22)
var _outfits := HBoxContainer.new()
var _outfit_color := ColorSwatches.new(MouzAppearance.OUTFIT_COLORS, 18)
## Prénoms déjà pris dans la famille (le dé les évite).
var other_names: Array = []


func _ready() -> void:
	_rng.randomize()
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 20)
	add_child(columns)
	columns.add_child(_identity_column())
	columns.add_child(_look_column())
	_sex.chosen.connect(_on_sex_chosen)
	_age.chosen.connect(_on_age_chosen)
	_skin.picked.connect(func(color: Color) -> void: _change_look(&"skin", color))
	_hair_color.picked.connect(func(color: Color) -> void: _change_look(&"hair_color", color))
	_outfit_color.picked.connect(func(color: Color) -> void: _change_look(&"outfit_color", color))


func _identity_column() -> Control:
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 228
	column.add_theme_constant_override("separation", 6)
	column.add_child(_title("PRÉNOM"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_first_name.placeholder_text = "Écris un prénom"
	_first_name.max_length = 18
	_first_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_first_name.text_changed.connect(_on_name_typed)
	row.add_child(_first_name)
	row.add_child(_dice_button("Tirer un prénom au hasard", _on_random_name))
	column.add_child(row)
	_name_error.text = "Écris un prénom ou tire-en un au hasard."
	_name_error.add_theme_color_override("font_color", Palette.CRITIQUE)
	_name_error.add_theme_font_size_override("font_size", 12)
	_name_error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_name_error)
	column.add_child(_gap(6))
	column.add_child(_title("SEXE"))
	column.add_child(_sex)
	column.add_child(_gap(6))
	column.add_child(_title("ÂGE"))
	column.add_child(_age)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)
	var random := Button.new()
	random.text = "Apparence au hasard"
	random.icon = DICE_WHITE
	random.theme_type_variation = &"SecondaryButton"
	random.focus_mode = Control.FOCUS_NONE
	random.add_theme_constant_override("icon_max_width", 18)
	random.pressed.connect(_on_random_look)
	column.add_child(random)
	return column


func _look_column() -> Control:
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 278
	column.add_theme_constant_override("separation", 4)
	column.add_child(_title("PEAU"))
	column.add_child(_skin)
	var hair_title := HBoxContainer.new()
	hair_title.add_child(_title("COUPE"))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hair_title.add_child(spacer)
	_all_hair.flat = true
	_all_hair.focus_mode = Control.FOCUS_NONE
	_all_hair.add_theme_font_size_override("font_size", 11)
	_all_hair.add_theme_color_override("font_color", Palette.ACCENT_TEXTE)
	_all_hair.add_theme_color_override("font_hover_color", Palette.ACCENT)
	_all_hair.pressed.connect(_on_all_hair)
	hair_title.add_child(_all_hair)
	column.add_child(hair_title)
	_hair_grid.columns = 4
	_hair_grid.add_theme_constant_override("h_separation", 6)
	_hair_grid.add_theme_constant_override("v_separation", 4)
	column.add_child(_hair_grid)
	column.add_child(_title("COULEUR DES CHEVEUX"))
	column.add_child(_hair_color)
	column.add_child(_title("TENUE"))
	_outfits.add_theme_constant_override("separation", 6)
	for outfit in MouzAppearance.OUTFITS:
		_outfits.add_child(_outfit_card(outfit))
	column.add_child(_outfits)
	column.add_child(_title("COULEUR DE LA TENUE"))
	column.add_child(_outfit_color)
	return column


# --- Membre affiché -----------------------------------------------------------------

func edit(member: Dictionary) -> void:
	_member = member
	_first_name.text = member["first_name"]
	refresh()


func refresh() -> void:
	if _member.is_empty():
		return
	var look: MouzAppearance = _member["appearance"]
	var missing := String(_member["first_name"]).strip_edges() == ""
	_name_error.visible = missing
	var style := HudTheme._padded(HudTheme.box(Color.WHITE, 10, Palette.CRITIQUE if missing else Palette.TRAIT, 2), 12, 8)
	_first_name.add_theme_stylebox_override("normal", style)
	_sex.select(look.sex)
	_age.select(look.age)
	_skin.select(look.skin)
	_hair_color.select(look.hair_color)
	_outfit_color.select(look.outfit_color)
	_rebuild_hair()
	for card in _outfits.get_children():
		card.set_pressed_no_signal(card.get_meta("outfit") == look.outfit)
		card.get_meta("preview").appearance = _variant(&"outfit", card.get_meta("outfit"))


func _rebuild_hair() -> void:
	var look: MouzAppearance = _member["appearance"]
	for child in _hair_grid.get_children():
		child.queue_free()
	var styles: Array = MouzAppearance.HAIR_STYLES if _show_all_hair else MouzAppearance.HAIR_BY_SEX[look.sex]
	if not look.hair_style in styles:
		styles = styles + [look.hair_style]
	_all_hair.text = "Coupes suggérées" if _show_all_hair else "Toutes les coupes (%d)" % MouzAppearance.HAIR_STYLES.size()
	for style in styles:
		_hair_grid.add_child(_hair_cell(style, look))


func _hair_cell(style: StringName, look: MouzAppearance) -> Control:
	var cell := VBoxContainer.new()
	cell.add_theme_constant_override("separation", 0)
	var button := Button.new()
	button.theme_type_variation = &"OptionCard"
	button.toggle_mode = true
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = HAIR_CELL
	button.tooltip_text = MouzAppearance.HAIR_NAMES[style]
	var available := MouzAppearance.hair_available(style, look.age)
	button.disabled = not available
	button.set_pressed_no_signal(style == look.hair_style)
	var portrait := MouzPortrait.new(46)
	portrait.appearance = _variant(&"hair_style", style)
	portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait.modulate = Color.WHITE if available else Color(1, 1, 1, 0.35)
	button.add_child(portrait)
	button.pressed.connect(_change_look.bind(&"hair_style", style))
	cell.add_child(button)
	var label := Label.new()
	label.text = MouzAppearance.HAIR_NAMES[style] if available else "dès adulte"
	label.theme_type_variation = &"MutedLabel"
	label.add_theme_font_size_override("font_size", 10)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cell.add_child(label)
	return cell


func _outfit_card(outfit: StringName) -> Button:
	var card := Button.new()
	card.theme_type_variation = &"OptionCard"
	card.toggle_mode = true
	card.focus_mode = Control.FOCUS_NONE
	card.custom_minimum_size = Vector2(84, 70)
	card.set_meta("outfit", outfit)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.add_theme_constant_override("separation", 0)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var preview := BodyPreview.new(0.8, &"bas")
	preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(preview)
	card.set_meta("preview", preview)
	var label := Label.new()
	label.text = MouzAppearance.OUTFIT_NAMES[outfit]
	label.add_theme_font_size_override("font_size", 11)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(label)
	card.add_child(column)
	card.pressed.connect(_change_look.bind(&"outfit", outfit))
	return card


## Copie de l'apparence du membre avec une propriété changée (vignettes de choix).
func _variant(property: StringName, value: Variant) -> MouzAppearance:
	var look: MouzAppearance = _member["appearance"].duplicate()
	look.set(property, value)
	return look


# --- Modifications ------------------------------------------------------------------

func _change_look(property: StringName, value: Variant) -> void:
	_member["appearance"].set(property, value)
	refresh()
	changed.emit()


func _on_sex_chosen(sex: StringName) -> void:
	var look: MouzAppearance = _member["appearance"]
	look.sex = sex
	if not look.hair_style in MouzAppearance.HAIR_BY_SEX[sex]:
		look.hair_style = MouzAppearance.HAIR_BY_SEX[sex][0]
	if sex == &"homme" and look.outfit == &"robe":
		look.outfit = &"tshirt"
	refresh()
	changed.emit()


func _on_age_chosen(age: StringName) -> void:
	_change_look(&"age", age)


func _on_name_typed(text: String) -> void:
	_member["first_name"] = text
	refresh()
	changed.emit()


func _on_random_name() -> void:
	_first_name.text = NameIdeas.first_name(_member["appearance"].sex, _rng, other_names)
	_on_name_typed(_first_name.text)


func _on_random_look() -> void:
	_member["appearance"].randomize_look(_rng)
	refresh()
	changed.emit()


func _on_all_hair() -> void:
	_show_all_hair = not _show_all_hair
	_rebuild_hair()


# --- Petits éléments ----------------------------------------------------------------

func _dice_button(tooltip: String, callback: Callable) -> Button:
	var button := Button.new()
	button.icon = DICE
	button.tooltip_text = tooltip
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(44, 40)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_constant_override("icon_max_width", 20)
	button.add_theme_stylebox_override("normal", HudTheme.box(Palette.PAPIER_2, 10))
	button.pressed.connect(callback)
	return button


static func _title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = &"SectionTitle"
	return label


static func _gap(height: float) -> Control:
	var gap := Control.new()
	gap.custom_minimum_size.y = height
	return gap
