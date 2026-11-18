class_name SlotList
extends ScrollContainer
## Liste des parties enregistrées : vignette, nom, jour, argent, date.
## Chaque carte propose Charger, Renommer (sur place) et Supprimer (avec confirmation sur place).

signal slot_chosen(slot_id: String)

const COIN := preload("res://assets/sprites/piece_mz.svg")
const THUMB_SIZE := Vector2(160, 90)

var _list := VBoxContainer.new()


func _ready() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_list.add_theme_constant_override("separation", 10)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_list)
	SaveManager.slots_changed.connect(refresh)
	refresh()


func refresh() -> void:
	for child in _list.get_children():
		child.queue_free()
	var slots := SaveManager.list_slots()
	if slots.is_empty():
		var empty := Label.new()
		empty.text = "Aucune partie enregistrée pour l'instant."
		empty.theme_type_variation = &"MutedLabel"
		_list.add_child(empty)
	for slot in slots:
		_list.add_child(_make_card(slot))


func _make_card(slot: Dictionary) -> Control:
	var card := PanelContainer.new()
	var current: bool = slot["id"] == SaveManager.current_slot
	var style := HudTheme.box(Color.WHITE if current else Palette.PAPIER_2, Palette.RAYON_ELEMENT,
			Palette.ACCENT if current else Color.TRANSPARENT, 2 if current else 0, 10)
	card.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	card.add_child(row)

	var thumb := PanelContainer.new()
	thumb.custom_minimum_size = THUMB_SIZE
	thumb.add_theme_stylebox_override("panel", HudTheme.box(Palette.JARDIN, 8))
	if slot["thumbnail"] != null:
		var image := TextureRect.new()
		image.texture = slot["thumbnail"]
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		thumb.add_child(image)
	row.add_child(thumb)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 2)
	row.add_child(info)
	var title := Label.new()
	title.text = slot.get("name", "Sans nom") + ("  (en cours)" if current else "")
	title.theme_type_variation = &"StrongLabel"
	title.add_theme_font_size_override("font_size", 16)
	title.clip_text = true
	info.add_child(title)
	var details := Label.new()
	details.text = "Jour %d · %s · %s · %d objets" % [int(slot.get("day", 1)), slot.get("time", "--:--"),
			Palette.format_mz(int(slot.get("funds", 0))), int(slot.get("objects", 0))]
	details.theme_type_variation = &"MutedLabel"
	info.add_child(details)
	var date := Label.new()
	date.text = "Enregistrée " + TimeFormat.since(float(slot.get("saved", 0)))
	date.theme_type_variation = &"MutedLabel"
	info.add_child(date)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 6)
	actions.alignment = BoxContainer.ALIGNMENT_END
	info.add_child(actions)
	_fill_actions(actions, info, title, slot)
	return card


## Boutons de la carte ; « Renommer » et « Supprimer » remplacent les boutons sur place.
func _fill_actions(actions: HBoxContainer, info: VBoxContainer, title: Label, slot: Dictionary) -> void:
	for child in actions.get_children():
		child.queue_free()
	var load_button := _button("Charger", &"PrimaryButton")
	load_button.pressed.connect(func() -> void: slot_chosen.emit(slot["id"]))
	actions.add_child(load_button)
	var rename_button := _button("Renommer", &"SecondaryButton")
	rename_button.pressed.connect(_start_rename.bind(actions, info, title, slot))
	actions.add_child(rename_button)
	var delete_button := _button("Supprimer", &"SecondaryButton")
	delete_button.pressed.connect(_ask_delete.bind(actions, info, title, slot))
	actions.add_child(delete_button)


func _start_rename(actions: HBoxContainer, info: VBoxContainer, title: Label, slot: Dictionary) -> void:
	for child in actions.get_children():
		child.queue_free()
	var field := LineEdit.new()
	field.text = slot.get("name", "")
	field.max_length = 40
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(field)
	var confirm := func() -> void:
		SaveManager.rename_slot(slot["id"], field.text)
	field.text_submitted.connect(func(_text: String) -> void: confirm.call())
	var ok := _button("OK", &"PrimaryButton")
	ok.pressed.connect(confirm)
	actions.add_child(ok)
	var cancel := _button("Annuler", &"SecondaryButton")
	cancel.pressed.connect(_fill_actions.bind(actions, info, title, slot))
	actions.add_child(cancel)
	field.grab_focus.call_deferred()
	field.select_all.call_deferred()


func _ask_delete(actions: HBoxContainer, info: VBoxContainer, title: Label, slot: Dictionary) -> void:
	for child in actions.get_children():
		child.queue_free()
	var question := Label.new()
	question.text = "Supprimer définitivement ?"
	question.add_theme_color_override("font_color", Palette.CRITIQUE)
	question.theme_type_variation = &"StrongLabel"
	actions.add_child(question)
	var yes := _button("Supprimer", &"PrimaryButton")
	yes.add_theme_stylebox_override("normal", HudTheme._padded(HudTheme.box(Palette.CRITIQUE, 12), 16, 10))
	yes.pressed.connect(func() -> void: SaveManager.delete_slot(slot["id"]))
	actions.add_child(yes)
	var no := _button("Garder", &"SecondaryButton")
	no.pressed.connect(_fill_actions.bind(actions, info, title, slot))
	actions.add_child(no)


func _button(text: String, variation: StringName) -> Button:
	var button := Button.new()
	button.text = text
	button.theme_type_variation = variation
	button.focus_mode = Control.FOCUS_NONE
	return button
