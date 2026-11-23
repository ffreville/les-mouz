class_name NewGameScreen
extends Control
## Nouvelle partie, en deux étapes : 1. Créer la famille, 2. Choisir le terrain.
## La barre du bas porte Retour, la raison d'un blocage, et le bouton pour continuer.

const GRASS := preload("res://assets/floors/herbe.svg")
const HOME_ICON := preload("res://assets/icons/white/emmenager.svg")
const LOT_ICON := preload("res://assets/icons/white/terrain.svg")

var family := Family.new()
var _step := 1
var _rng := RandomNumberGenerator.new()
var _family_step := HBoxContainer.new()
var _column := FamilyColumn.new()
var _preview := MemberPreview.new()
var _editor := MemberEditor.new()
var _lot_step := LotStep.new()
var _steps: Array[Label] = []
var _step_dots: Array[PanelContainer] = []
var _reason := Label.new()
var _next := Button.new()


func _ready() -> void:
	theme = HudTheme.build()
	Music.enter_menu()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rng.randomize()
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
	_lot_step.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(_lot_step)
	page.add_child(_bottom_bar())

	_column.setup(family)
	_column.member_chosen.connect(_on_member_chosen)
	_column.family_changed.connect(_on_member_edited)
	_editor.changed.connect(_on_member_edited)
	_lot_step.selection_changed.connect(_refresh)
	_on_member_chosen(_column.selected)
	_show_step(1)


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
	subtitle.text = "· Nouvelle partie"
	subtitle.theme_type_variation = &"MutedLabel"
	subtitle.add_theme_font_size_override("font_size", 13)
	row.add_child(subtitle)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	for i in 2:
		if i > 0:
			var line := ColorRect.new()
			line.color = Palette.TRAIT
			line.custom_minimum_size = Vector2(40, 2)
			line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(line)
		var dot := PanelContainer.new()
		dot.custom_minimum_size = Vector2(24, 24)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var number := Label.new()
		number.text = str(i + 1)
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		number.add_theme_font_size_override("font_size", 12)
		number.theme_type_variation = &"StrongLabel"
		dot.add_child(number)
		row.add_child(dot)
		_step_dots.append(dot)
		var label := Label.new()
		label.text = ["Famille", "Terrain"][i]
		label.theme_type_variation = &"StrongLabel"
		label.add_theme_font_size_override("font_size", 13)
		row.add_child(label)
		_steps.append(label)
	var end_spacer := Control.new()
	end_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(end_spacer)
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
	_next.focus_mode = Control.FOCUS_NONE
	_next.add_theme_constant_override("icon_max_width", 18)
	_next.pressed.connect(_on_next)
	row.add_child(_next)
	return bar


# --- Étapes -------------------------------------------------------------------------

func _show_step(step: int) -> void:
	_step = step
	_family_step.visible = step == 1
	_lot_step.visible = step == 2
	if step == 2:
		_lot_step.show_family(family)
	for i in _step_dots.size():
		var done := i + 1 < step
		var current := i + 1 == step
		var color := Palette.GAIN if done else (Palette.CONTOUR if current else Palette.PAPIER_2)
		_step_dots[i].add_theme_stylebox_override("panel", HudTheme.box(color, 12))
		var number: Label = _step_dots[i].get_child(0)
		number.text = "✓" if done else str(i + 1)
		number.add_theme_color_override("font_color", Palette.PAPIER if done or current else Palette.ENCRE_DOUCE)
		_steps[i].add_theme_color_override("font_color", Palette.ENCRE if current or done else Palette.ENCRE_DOUCE)
	_next.text = "Choisir le terrain" if step == 1 else "Emménager"
	_next.icon = LOT_ICON if step == 1 else HOME_ICON
	_refresh()


func _refresh() -> void:
	var problem := ""
	if _step == 1:
		problem = family.problem()
		_reason.add_theme_color_override("font_color", Palette.CRITIQUE)
		_reason.text = ("⚠ " + problem) if problem != "" else ""
	else:
		if _lot_step.chosen == null:
			problem = "Choisis un terrain."
		_reason.add_theme_color_override("font_color", Palette.ENCRE_DOUCE)
		_reason.text = "Après l'achat, il vous restera %s" % Palette.format_mz(_lot_step.remaining())
	_next.disabled = problem != ""
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
	if _step == 2:
		_show_step(1)
	else:
		SaveManager.go_to_title()


func _on_next() -> void:
	if _step == 1:
		if family.problem() == "":
			_show_step(2)
		return
	if _lot_step.chosen != null:
		SaveManager.start_new_game(_lot_step.game_name.text, family, _lot_step.chosen)
