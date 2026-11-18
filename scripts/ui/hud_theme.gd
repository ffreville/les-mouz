class_name HudTheme
extends RefCounted
## Construit le Theme Godot de l'interface à partir de la Palette (design « Maison de poche »).
## Variantes de type disponibles : SectionTitle, MutedLabel, TitleLabel, BigLabel,
## SpeedGroup, IconButton, ToggleChip.


static func build() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 14
	_panels(theme)
	_labels(theme)
	_buttons(theme)
	_popup_menu(theme)
	_misc(theme)
	return theme


## Boîte arrondie réutilisable.
static func box(color: Color, radius: int, border_color := Color.TRANSPARENT, border := 0,
		margin := 0.0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.border_color = border_color
	style.set_border_width_all(border)
	style.set_content_margin_all(margin)
	style.anti_aliasing = true
	return style


static func _panels(theme: Theme) -> void:
	var panel := box(Palette.PAPIER, Palette.RAYON_PANNEAU, Palette.TRAIT, 2, Palette.MARGE_PANNEAU)
	# Ombre « découpée » : décalée vers le bas, presque sans flou.
	panel.shadow_color = Palette.OMBRE
	panel.shadow_size = 1
	panel.shadow_offset = Vector2(0, 4)
	theme.set_stylebox("panel", "PanelContainer", panel)

	theme.set_type_variation("SpeedGroup", "PanelContainer")
	theme.set_stylebox("panel", "SpeedGroup", box(Palette.PAPIER_2, 12, Color.TRANSPARENT, 0, 4))


static func _labels(theme: Theme) -> void:
	theme.set_color("font_color", "Label", Palette.ENCRE)
	for variation in ["SectionTitle", "MutedLabel", "TitleLabel", "BigLabel"]:
		theme.set_type_variation(variation, "Label")
	theme.set_color("font_color", "SectionTitle", Palette.ENCRE_DOUCE)
	theme.set_font_size("font_size", "SectionTitle", 12)
	theme.set_color("font_color", "MutedLabel", Palette.ENCRE_DOUCE)
	theme.set_font_size("font_size", "MutedLabel", 12)
	theme.set_font_size("font_size", "TitleLabel", 24)
	theme.set_font_size("font_size", "BigLabel", 22)


static func _buttons(theme: Theme) -> void:
	var accent := Palette.ACCENT
	theme.set_stylebox("normal", "Button", box(Color.TRANSPARENT, Palette.RAYON_BOUTON, Color.TRANSPARENT, 0, 6))
	theme.set_stylebox("hover", "Button", box(Color.WHITE, Palette.RAYON_BOUTON, accent, 2, 6))
	theme.set_stylebox("pressed", "Button", box(Palette.CONTOUR, Palette.RAYON_BOUTON, Color.TRANSPARENT, 0, 6))
	theme.set_stylebox("hover_pressed", "Button", box(Palette.CONTOUR, Palette.RAYON_BOUTON, accent, 2, 6))
	theme.set_stylebox("disabled", "Button", box(Color.TRANSPARENT, Palette.RAYON_BOUTON, Color.TRANSPARENT, 0, 6))
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	for state in ["font_color", "font_hover_color", "font_focus_color", "icon_normal_color",
			"icon_hover_color", "icon_focus_color"]:
		theme.set_color(state, "Button", Palette.ENCRE)
	for state in ["font_pressed_color", "font_hover_pressed_color", "icon_pressed_color",
			"icon_hover_pressed_color"]:
		theme.set_color(state, "Button", Palette.PAPIER)
	theme.set_constant("h_separation", "Button", 6)

	# Bouton ✕ des éléments de la file.
	theme.set_type_variation("IconButton", "Button")
	theme.set_stylebox("normal", "IconButton", box(Color.TRANSPARENT, Palette.RAYON_BOUTON, Color.TRANSPARENT, 0, 7))
	theme.set_stylebox("hover", "IconButton", box(Palette.PAPIER_2, Palette.RAYON_BOUTON, Palette.TRAIT, 2, 7))
	theme.set_stylebox("pressed", "IconButton", box(Palette.TRAIT, Palette.RAYON_BOUTON, Palette.TRAIT, 2, 7))
	theme.set_color("icon_pressed_color", "IconButton", Palette.ENCRE)
	theme.set_color("icon_hover_pressed_color", "IconButton", Palette.ENCRE)

	# Interrupteur « Autonomie » : case vide ou cochée.
	theme.set_type_variation("ToggleChip", "Button")
	theme.set_stylebox("normal", "ToggleChip", box(Color.WHITE, 6, Palette.CONTOUR, 2, 6))
	theme.set_stylebox("hover", "ToggleChip", box(Color.WHITE, 6, accent, 2, 6))
	theme.set_stylebox("pressed", "ToggleChip", box(Palette.CONTOUR, 6, Palette.CONTOUR, 2, 6))
	theme.set_stylebox("hover_pressed", "ToggleChip", box(Palette.CONTOUR, 6, accent, 2, 6))
	# Coche invisible quand c'est décoché.
	theme.set_color("icon_normal_color", "ToggleChip", Color.TRANSPARENT)
	theme.set_color("icon_hover_color", "ToggleChip", Color(Palette.ENCRE, 0.25))
	theme.set_constant("icon_max_width", "ToggleChip", 14)


static func _popup_menu(theme: Theme) -> void:
	var panel := box(Palette.PAPIER, Palette.RAYON_MENU, Palette.TRAIT, 2, 8)
	panel.shadow_color = Palette.OMBRE
	panel.shadow_size = 1
	panel.shadow_offset = Vector2(0, 4)
	theme.set_stylebox("panel", "PopupMenu", panel)
	theme.set_stylebox("hover", "PopupMenu", box(Palette.ACCENT_DOUX, 10))
	var line := StyleBoxLine.new()
	line.color = Palette.PAPIER_2
	line.thickness = 2
	theme.set_stylebox("separator", "PopupMenu", line)
	theme.set_stylebox("labeled_separator_left", "PopupMenu", line)
	theme.set_stylebox("labeled_separator_right", "PopupMenu", line)
	theme.set_color("font_color", "PopupMenu", Palette.ENCRE)
	theme.set_color("font_hover_color", "PopupMenu", Palette.ENCRE)
	theme.set_color("font_separator_color", "PopupMenu", Palette.ENCRE)
	theme.set_color("font_disabled_color", "PopupMenu", Palette.ENCRE_DOUCE)
	theme.set_font_size("font_size", "PopupMenu", 15)
	theme.set_font_size("font_separator_size", "PopupMenu", 13)
	theme.set_constant("v_separation", "PopupMenu", 14)
	theme.set_constant("h_separation", "PopupMenu", 10)
	theme.set_constant("item_start_padding", "PopupMenu", 10)
	theme.set_constant("item_end_padding", "PopupMenu", 16)
	theme.set_constant("icon_max_width", "PopupMenu", 20)


static func _misc(theme: Theme) -> void:
	theme.set_stylebox("background", "ProgressBar", box(Palette.PISTE, 2))
	theme.set_stylebox("fill", "ProgressBar", box(Palette.ACCENT, 2))
	var line := StyleBoxLine.new()
	line.color = Palette.TRAIT
	line.thickness = 2
	line.vertical = true
	theme.set_stylebox("separator", "VSeparator", line)
	theme.set_constant("separation", "VSeparator", 12)
