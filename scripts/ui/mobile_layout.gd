class_name MobileLayout
extends RefCounted
## Disposition de l'interface sur téléphone (voir Device) : l'écran fait MOBILE_HEIGHT unités de
## haut, il faut donc replier et faire défiler ce qui ne tient pas.
##  - Le panneau du Mouz se replie sous son en-tête (bouton à côté du portrait) ; replié au départ.
##  - Les relations se replient sous leur titre ; repliées au départ.
##  - Les deux colonnes défilent au doigt quand elles sont plus hautes que l'écran.
## Sur ordinateur, rien de tout cela n'est appliqué.

const MARGIN := 12.0
const OPEN_ICON := preload("res://assets/icons/ink/deplier.svg")


## Applique la disposition mobile au HUD (après la construction de ses panneaux).
static func apply(hud: Hud) -> void:
	_fold_mouz_panel(hud)
	_fold_relations(hud)
	hud.queue_help.text = "Touche un objet ou un autre Mouz pour lui donner une action."
	hud.left_column = _scrolling(hud.left_column, false)
	hud.build_panel_area = _scrolling(hud.build_panel, false)
	hud.right_panel = _scrolling(hud.right_panel, true)


## Range sous un bouton à replier ce qui suit l'en-tête du Mouz (onglets, jauges, autonomie).
static func _fold_mouz_panel(hud: Hud) -> void:
	var content := hud.mouz_header.get_parent()
	var details := VBoxContainer.new()
	details.add_theme_constant_override("separation", 12)
	var moved: Array[Node] = []
	for child in content.get_children():
		if child.get_index() > hud.mouz_header.get_index():
			moved.append(child)
	content.add_child(details)
	for child in moved:
		child.reparent(details, false)
	details.visible = false
	hud.mouz_header.add_child(_fold_button(details, "les besoins"))


static func _fold_relations(hud: Hud) -> void:
	var list := hud.relationship_panel
	var content := list.get_parent()
	var title: Control = content.get_child(0)
	var row := HBoxContainer.new()
	content.add_child(row)
	content.move_child(row, 0)
	title.reparent(row, false)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_fold_button(list, "les relations"))
	list.visible = false


## Bouton rond qui montre ou cache `target` ; sa flèche pointe vers le bas quand c'est ouvert.
static func _fold_button(target: Control, what: String) -> Button:
	var button := Button.new()
	button.icon = OPEN_ICON
	button.expand_icon = true
	button.focus_mode = Control.FOCUS_NONE
	button.toggle_mode = true
	button.button_pressed = target.visible
	button.custom_minimum_size = Vector2(36, 36)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.flat = true
	button.add_theme_color_override("icon_normal_color", Palette.ENCRE)
	button.add_theme_color_override("icon_pressed_color", Palette.ENCRE)
	button.add_theme_color_override("icon_hover_color", Palette.ACCENT)
	button.add_theme_color_override("icon_hover_pressed_color", Palette.ACCENT)
	button.pivot_offset = Vector2(18, 18)
	var refresh := func() -> void:
		button.rotation = PI / 2 if target.visible else 0.0
		button.tooltip_text = ("Cacher " if target.visible else "Montrer ") + what
	button.toggled.connect(func(on: bool) -> void:
		target.visible = on
		refresh.call())
	refresh.call()
	return button


## Met une colonne dans une zone qui défile, à sa place, et l'ajuste à l'écran : aussi haute que
## son contenu, sans dépasser le bas de l'écran. Renvoie la zone (montrée ou cachée à sa place).
static func _scrolling(column: Control, right: bool) -> Control:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	var parent := column.get_parent()
	parent.add_child(scroll)
	parent.move_child(scroll, column.get_index())
	var top := column.offset_top
	var width := column.offset_right - column.offset_left
	column.reparent(scroll, false)
	# La zone montre ou cache la colonne à sa place (voir Hud._on_mode_changed).
	scroll.visible = column.visible
	column.visible = true
	column.set_anchors_preset(Control.PRESET_TOP_LEFT)
	column.position = Vector2.ZERO
	column.custom_minimum_size.x = width
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if right:
		scroll.anchor_left = 1.0
		scroll.anchor_right = 1.0
		scroll.offset_left = -MARGIN - width
		scroll.offset_right = -MARGIN
	else:
		scroll.offset_left = MARGIN
		scroll.offset_right = MARGIN + width
	scroll.offset_top = top
	var fit := func() -> void:
		var room := scroll.get_viewport_rect().size.y - top - MARGIN
		scroll.offset_bottom = top + minf(column.get_combined_minimum_size().y, room)
	column.minimum_size_changed.connect(fit)
	Device.layout_changed.connect(fit)
	scroll.tree_exiting.connect(func() -> void: Device.layout_changed.disconnect(fit))
	fit.call_deferred()
	return scroll
