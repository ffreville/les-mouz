class_name NewGameScreen
extends Control
## Création d'une famille qui emménage sur un emplacement du quartier (SaveManager.moving_plot).
## La barre du bas porte Retour (au quartier), la raison d'un blocage, le budget après l'achat
## et « Emménager ».

const GRASS := preload("res://assets/floors/herbe.svg")
const HOME_ICON := preload("res://assets/icons/white/emmenager.svg")

var family := Family.new()
var _plot: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _family_step := HBoxContainer.new()
var _column := FamilyColumn.new()
var _preview := MemberPreview.new()
var _editor := MemberEditor.new()
var _reason := Label.new()
var _next := Button.new()


func _ready() -> void:
	theme = HudTheme.build()
	Music.enter_menu()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rng.randomize()
	_plot = Neighborhood.plot(SaveManager.neighborhood, SaveManager.moving_plot)
	_start_family()
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

	_family_step.add_theme_constant_override("separation", 12)
	_family_step.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_family_step.add_child(_column)
	_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_family_step.add_child(_preview)
	_editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_family_step.add_child(_editor)
	page.add_child(_family_step)
	page.add_child(_bottom_bar())

	_column.setup(family)
	_column.member_chosen.connect(_on_member_chosen)
	_column.family_changed.connect(_on_member_edited)
	_editor.changed.connect(_on_member_edited)
	_on_member_chosen(_column.selected)
	_refresh()


## Une famille de départ : deux adultes tirés au hasard, en couple.
func _start_family() -> void:
	family.family_name = NameIdeas.family_name(_rng)
	var taken: Array = []
	for sex in [&"femme", &"homme"]:
		var look := MouzAppearance.new()
		look.sex = sex
		look.age = &"adulte"
		look.randomize_look(_rng)
		var first_name := NameIdeas.first_name(sex, _rng, taken)
		taken.append(first_name)
		family.add_member(first_name, look)
	family.set_link(family.members[0]["id"], family.members[1]["id"], &"couple")


# --- Barres -------------------------------------------------------------------------

func _top_bar() -> Control:
	var bar := PanelContainer.new()
	var style := HudTheme.box(Palette.PAPIER, 16, Palette.TRAIT, 2)
	style.content_margin_left = 16
	style.content_margin_right = 16
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
	subtitle.text = "· Nouvelle famille"
	if not _plot.is_empty():
		subtitle.text += " · %s" % (_plot["house_name"] + ", " + _plot["address"] if _plot["house_name"] != "" else _plot["address"])
	subtitle.theme_type_variation = &"MutedLabel"
	subtitle.add_theme_font_size_override("font_size", 13)
	row.add_child(subtitle)
	return bar


func _bottom_bar() -> Control:
	var bar := PanelContainer.new()
	var style := HudTheme.box(Palette.PAPIER, 16, Palette.TRAIT, 2, 6)
	bar.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	bar.add_child(row)
	var back := Button.new()
	back.text = "Retour"
	back.theme_type_variation = &"SecondaryButton"
	back.focus_mode = Control.FOCUS_NONE
	back.pressed.connect(_on_back)
	row.add_child(back)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	_reason.add_theme_font_size_override("font_size", 13)
	_reason.theme_type_variation = &"StrongLabel"
	_reason.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_reason)
	_next.theme_type_variation = &"PrimaryButton"
	_next.text = "Emménager"
	_next.icon = HOME_ICON
	_next.focus_mode = Control.FOCUS_NONE
	_next.add_theme_constant_override("icon_max_width", 18)
	_next.pressed.connect(_on_next)
	row.add_child(_next)
	return bar


# --- État -----------------------------------------------------------------------------

## Prix de l'emplacement choisi.
func _price() -> int:
	return int(_plot.get("price", 0))


func _refresh() -> void:
	var problem := family.problem()
	if problem != "":
		_reason.add_theme_color_override("font_color", Palette.CRITIQUE)
		_reason.text = "⚠ " + problem
	else:
		_reason.add_theme_color_override("font_color", Palette.ENCRE_DOUCE)
		var remaining := Wallet.settings.start_funds - _price()
		_reason.text = ("Maison à %s : il vous restera %s" % [Palette.format_mz(_price()), Palette.format_mz(remaining)]) \
				if _price() > 0 else "Terrain libre : vous gardez vos %s" % Palette.format_mz(remaining)
	_next.disabled = problem != "" or _plot.is_empty()
	_column.refresh()


func _on_member_chosen(member: Dictionary) -> void:
	_editor.other_names = family.members.filter(func(m: Dictionary) -> bool: return m != member).map(
			func(m: Dictionary) -> String: return m["first_name"])
	_editor.edit(member)
	_preview.show_member(member, family.family_name)
	_refresh()


func _on_member_edited() -> void:
	_preview.show_member(_column.selected, family.family_name)
	_refresh()


func _on_back() -> void:
	if SaveManager.current_slot != "":
		SaveManager.go_to_neighborhood()
	else:
		SaveManager.go_to_title()


func _on_next() -> void:
	if family.problem() == "" and not _plot.is_empty():
		SaveManager.move_in(_plot["id"], family)
