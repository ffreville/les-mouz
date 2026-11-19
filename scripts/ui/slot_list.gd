class_name SlotList
extends ScrollContainer
## Liste des parties enregistrées, une carte par partie :
## vignette, nom (et « En cours »), « Jour 3 · 18:40 · 18 800 Mz · 13 objets », date,
## puis Charger, Renommer et Supprimer. Renommer et Supprimer se font sur place.
## Une partie abîmée propose de restaurer sa copie de secours, sinon seulement de la supprimer.

signal slot_chosen(slot_id: String)
signal new_game_requested

const COIN := preload("res://assets/sprites/piece_mz.svg")
const CLOCK := preload("res://assets/icons/ink/horloge.svg")
const ALERT := preload("res://assets/icons/ink/alerte.svg")
const LOT_ICON := preload("res://assets/icons/ink/terrain.svg")
const THUMB_SIZE := Vector2(160, 90)
const BUTTON_HEIGHT := 36.0

var _list := VBoxContainer.new()


func _ready() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_list.add_theme_constant_override("separation", 12)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_list)
	SaveManager.slots_changed.connect(refresh)
	refresh()


func count() -> int:
	return SaveManager.list_slots().size()


func refresh() -> void:
	for child in _list.get_children():
		child.queue_free()
	var slots := SaveManager.list_slots()
	if slots.is_empty():
		_list.add_child(_empty_state())
	for slot in slots:
		_list.add_child(_make_card(slot))


# --- Carte d'une partie -------------------------------------------------------------

func _make_card(slot: Dictionary) -> Control:
	var card := PanelContainer.new()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	card.add_child(row)
	row.add_child(_thumbnail(slot))
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 2)
	row.add_child(info)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(actions)
	_show_normal(card, info, actions, slot)
	return card


func _card_style(card: PanelContainer, border: Color, width: int, background := Color.WHITE) -> void:
	var style := HudTheme.box(background, 14, border, width)
	style.content_margin_left = 12
	style.content_margin_top = 12
	style.content_margin_right = 14
	style.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", style)


func _thumbnail(slot: Dictionary) -> Control:
	var thumb := PanelContainer.new()
	thumb.custom_minimum_size = THUMB_SIZE
	thumb.clip_contents = true
	if slot.get("damaged", false):
		thumb.add_theme_stylebox_override("panel", HudTheme.box(Palette.CRITIQUE_DOUX, 10, Palette.CRITIQUE, 2))
		var alert := TextureRect.new()
		alert.texture = ALERT
		alert.modulate = Palette.CRITIQUE
		alert.custom_minimum_size = Vector2(28, 28)
		alert.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		alert.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		alert.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		alert.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		thumb.add_child(alert)
		return thumb
	thumb.add_theme_stylebox_override("panel", HudTheme.box(Palette.JARDIN, 10))
	if slot["thumbnail"] != null:
		var image := TextureRect.new()
		image.texture = slot["thumbnail"]
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		thumb.add_child(image)
	return thumb


## Nom, infos et date, puis Charger / Renommer / Supprimer.
func _show_normal(card: PanelContainer, info: VBoxContainer, actions: HBoxContainer, slot: Dictionary) -> void:
	_clear(info)
	_clear(actions)
	var current: bool = slot["id"] == SaveManager.current_slot
	var damaged: bool = slot.get("damaged", false)
	if damaged:
		_card_style(card, Palette.TRAIT, 2)
	else:
		_card_style(card, Palette.ACCENT if current else Palette.TRAIT, 3 if current else 2)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	title_row.add_child(_title(slot.get("name", "Sans nom")))
	if damaged:
		title_row.add_child(_tag("Abîmée", Palette.CRITIQUE))
	elif current:
		title_row.add_child(_tag("En cours", Palette.ACCENT))
	info.add_child(title_row)
	if damaged:
		var problem := Label.new()
		problem.text = "⚠ Cette sauvegarde ne se lit plus."
		problem.add_theme_color_override("font_color", Palette.CRITIQUE)
		problem.add_theme_font_size_override("font_size", 13)
		problem.theme_type_variation = &"StrongLabel"
		info.add_child(problem)
		info.add_child(_small("Une copie de secours du jour %d est disponible." % int(slot.get("backup_day", 1))
				if slot.get("restorable", false) else "Aucune copie de secours."))
		if slot.get("restorable", false):
			var restore := _button("Restaurer la copie", &"SecondaryButton", "charger")
			restore.pressed.connect(func() -> void: SaveManager.restore_slot(slot["id"]))
			actions.add_child(restore)
		actions.add_child(_delete_button(card, info, actions, slot))
		return
	info.add_child(_details(slot))
	info.add_child(_small("Enregistrée " + TimeFormat.since(float(slot.get("saved", 0)))))
	var load_button := _button("Charger", &"PrimaryButton", "charger")
	load_button.pressed.connect(func() -> void: slot_chosen.emit(slot["id"]))
	actions.add_child(load_button)
	var rename_button := _button("Renommer", &"SecondaryButton", "renommer")
	rename_button.pressed.connect(_show_rename.bind(card, info, actions, slot))
	actions.add_child(rename_button)
	actions.add_child(_delete_button(card, info, actions, slot))


func _show_rename(card: PanelContainer, info: VBoxContainer, actions: HBoxContainer, slot: Dictionary) -> void:
	_clear(actions)
	var title_row: Control = info.get_child(0)
	title_row.visible = false
	var field := LineEdit.new()
	field.text = slot.get("name", "")
	field.max_length = 40
	field.custom_minimum_size = Vector2(300, 38)
	field.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	info.add_child(field)
	info.move_child(field, 0)
	var ok := _button("OK", &"PrimaryButton", "valider")
	var confirm := func() -> void:
		if field.text.strip_edges() != "":
			SaveManager.rename_slot(slot["id"], field.text)
	ok.pressed.connect(confirm)
	field.text_submitted.connect(func(_text: String) -> void: confirm.call())
	field.text_changed.connect(func(text: String) -> void: ok.disabled = text.strip_edges() == "")
	var cancel_rename := func() -> void:
		field.queue_free()
		_show_normal(card, info, actions, slot)
	var on_key := func(event: InputEvent) -> void:
		if event.is_action_pressed("ui_cancel"):
			field.accept_event()
			cancel_rename.call()
	field.gui_input.connect(on_key)
	actions.add_child(ok)
	var cancel := _button("Annuler", &"SecondaryButton")
	cancel.pressed.connect(cancel_rename)
	actions.add_child(cancel)
	field.grab_focus.call_deferred()
	field.select_all.call_deferred()


func _ask_delete(card: PanelContainer, info: VBoxContainer, actions: HBoxContainer, slot: Dictionary) -> void:
	_clear(actions)
	_card_style(card, Palette.CRITIQUE, 2, Palette.CRITIQUE_DOUX)
	var question := Label.new()
	question.text = "Supprimer définitivement ?"
	question.add_theme_color_override("font_color", Palette.CRITIQUE)
	question.theme_type_variation = &"StrongLabel"
	question.add_theme_font_size_override("font_size", 13)
	actions.add_child(question)
	var yes := _button("Supprimer", &"DangerButton", "supprimer")
	yes.pressed.connect(func() -> void: SaveManager.delete_slot(slot["id"]))
	actions.add_child(yes)
	var no := _button("Garder", &"SecondaryButton")
	no.pressed.connect(_show_normal.bind(card, info, actions, slot))
	actions.add_child(no)


func _delete_button(card: PanelContainer, info: VBoxContainer, actions: HBoxContainer, slot: Dictionary) -> Button:
	var button := _button("", &"SecondaryButton", "supprimer")
	button.tooltip_text = "Supprimer"
	button.custom_minimum_size = Vector2(BUTTON_HEIGHT, BUTTON_HEIGHT)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for state in ["normal", "hover", "pressed"]:
		var style := HudTheme.box(Color.WHITE, 10, Palette.CRITIQUE if state != "normal" else Palette.CRITIQUE_DOUX, 2, 8)
		button.add_theme_stylebox_override(state, style)
	for state in ["icon_normal_color", "icon_hover_color", "icon_pressed_color"]:
		button.add_theme_color_override(state, Palette.CRITIQUE)
	button.pressed.connect(_ask_delete.bind(card, info, actions, slot))
	return button


# --- Liste vide ---------------------------------------------------------------------

func _empty_state() -> Control:
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 10)
	column.custom_minimum_size.y = 300
	var picture := PanelContainer.new()
	picture.custom_minimum_size = Vector2(110, 62)
	picture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	picture.add_theme_stylebox_override("panel", HudTheme.box(Palette.JARDIN, 10))
	var sign := TextureRect.new()
	sign.texture = LOT_ICON
	sign.custom_minimum_size = Vector2(32, 32)
	sign.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sign.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sign.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	sign.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	picture.add_child(sign)
	column.add_child(picture)
	var title := Label.new()
	title.text = "Aucune partie enregistrée"
	title.add_theme_font_override("font", HudTheme.font(HudTheme.BALOO, 800))
	title.add_theme_font_size_override("font_size", 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var help := _small("Crée une famille et construis sa maison : la partie apparaîtra ici.")
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(help)
	var button := _button("Nouvelle partie", &"PrimaryButton", "famille")
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(new_game_requested.emit)
	column.add_child(button)
	return column


# --- Petits éléments ----------------------------------------------------------------

func _details(slot: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.add_child(_icon(CLOCK, 14))
	row.add_child(_info_label("Jour %d · %s ·" % [int(slot.get("day", 1)), slot.get("time", "--:--")]))
	row.add_child(_icon(COIN, 14, false))
	row.add_child(_info_label("%s · %d objets" % [Palette.format_mz(int(slot.get("funds", 0))), int(slot.get("objects", 0))]))
	return row


func _title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", HudTheme.font(HudTheme.BALOO, 700))
	label.add_theme_font_size_override("font_size", 20)
	return label


func _tag(text: String, color: Color) -> Control:
	var tag := Label.new()
	tag.text = text
	tag.add_theme_font_override("font", HudTheme.font(HudTheme.NUNITO, 800))
	tag.add_theme_font_size_override("font_size", 11)
	tag.add_theme_color_override("font_color", Color.WHITE)
	var style := HudTheme.box(color, 8)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 1
	style.content_margin_bottom = 1
	tag.add_theme_stylebox_override("normal", style)
	tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return tag


func _info_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = &"StrongLabel"
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Palette.ENCRE_DOUCE)
	return label


func _small(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = &"MutedLabel"
	return label


func _icon(texture: Texture2D, side: float, tint := true) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = texture
	rect.custom_minimum_size = Vector2(side, side)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if tint:
		rect.modulate = Palette.ENCRE_DOUCE
	return rect


func _button(text: String, variation: StringName, icon := "") -> Button:
	var button := Button.new()
	button.text = text
	button.theme_type_variation = variation
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size.y = BUTTON_HEIGHT
	button.add_theme_font_size_override("font_size", 13)
	if icon != "":
		button.icon = load("res://assets/icons/white/%s.svg" % icon)
	# Boutons de 36 px dans les cartes : mêmes couleurs que le thème, marges réduites.
	var fill: Color = {&"PrimaryButton": Palette.CONTOUR, &"DangerButton": Palette.CRITIQUE}.get(variation, Color.WHITE)
	var border := Palette.TRAIT if variation == &"SecondaryButton" else Color.TRANSPARENT
	var styles := {
		"normal": _compact(fill, border),
		"pressed": _compact(fill, border),
		"hover": _compact(fill, Palette.ACCENT),
		"hover_pressed": _compact(fill, Palette.ACCENT),
		"disabled": _compact(Palette.PISTE, Color.TRANSPARENT),
	}
	for state in styles:
		button.add_theme_stylebox_override(state, styles[state])
	return button


static func _compact(fill: Color, border: Color) -> StyleBoxFlat:
	var style := HudTheme.box(fill, 10, border, 2 if border.a > 0 else 0)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


static func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
