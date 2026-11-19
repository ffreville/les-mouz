class_name MemberCard
extends Button
## Carte d'un membre dans la colonne de gauche : portrait, prénom, sexe et âge, bouton ✕.
## Choisie : fond accent doux, bord accent. Sans prénom : bord rouge et « Prénom manquant ».

signal remove_requested

const SIZE := Vector2(276, 72)
const REMOVE_ICON := preload("res://assets/icons/ink/retirer.svg")

var member: Dictionary
var _portrait := MouzPortrait.new(48)
var _name := Label.new()
var _details := Label.new()
var _remove := Button.new()


func _init(p_member: Dictionary) -> void:
	member = p_member
	toggle_mode = true
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = SIZE
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 12
	row.offset_right = -8
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	_portrait.background = Palette.PAPIER_2
	_portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_portrait)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 0)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name.theme_type_variation = &"StrongLabel"
	_name.add_theme_font_size_override("font_size", 15)
	_details.theme_type_variation = &"MutedLabel"
	for label in [_name, _details]:
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(label)
	row.add_child(column)
	_remove.icon = REMOVE_ICON
	_remove.theme_type_variation = &"IconButton"
	_remove.tooltip_text = "Retirer ce membre"
	_remove.focus_mode = Control.FOCUS_NONE
	_remove.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_remove.add_theme_constant_override("icon_max_width", 16)
	_remove.pressed.connect(remove_requested.emit)
	row.add_child(_remove)


func refresh(can_remove: bool) -> void:
	var look: MouzAppearance = member["appearance"]
	_portrait.appearance = look
	var missing := String(member["first_name"]).strip_edges() == ""
	_name.text = "Prénom manquant" if missing else member["first_name"]
	_name.add_theme_color_override("font_color", Palette.CRITIQUE if missing else Palette.ENCRE)
	_details.text = look.describe()
	_remove.visible = can_remove
	var border := Palette.CRITIQUE if missing else Palette.TRAIT
	add_theme_stylebox_override("normal", HudTheme.box(Color.WHITE, 14, border, 2))
	add_theme_stylebox_override("hover", HudTheme.box(Color.WHITE, 14, Palette.ACCENT, 2))
	var chosen := HudTheme.box(Palette.ACCENT_DOUX, 14, Palette.CRITIQUE if missing else Palette.ACCENT, 3)
	add_theme_stylebox_override("pressed", chosen)
	add_theme_stylebox_override("hover_pressed", chosen)
	_portrait.queue_redraw()
