class_name ActionQueuePanel
extends VBoxContainer
## Affiche la file d'actions du personnage sélectionné : icône, nom, détail, bouton ✕.
## L'action en cours est encadrée d'accent et montre sa progression ; les suivantes
## tiennent sur une ligne, et au-delà de MAX_WAITING on n'affiche que leur nombre.

## Émis quand le nombre d'actions change (pour le compteur du titre).
signal count_changed(count: int)

const CLOSE_ICON := preload("res://assets/icons/white/fermer.svg")
## Icône des déplacements simples (« Aller ici »).
const MOVE_ICON := preload("res://assets/icons/ink/vitesse_1.svg")
## Actions en attente affichées sous l'action en cours.
const MAX_WAITING := 3

var _character: Character
var _current_detail: Label
var _current_bar: ProgressBar


func _ready() -> void:
	add_theme_constant_override("separation", 6)


func set_character(character: Character) -> void:
	if _character != null:
		_character.queue.changed.disconnect(_rebuild)
	_character = character
	_character.queue.changed.connect(_rebuild)
	_rebuild()


func _process(_delta: float) -> void:
	if _character == null or _current_detail == null or _character.queue.is_empty():
		return
	var action := _character.queue.current()
	_current_detail.text = _detail_text(action)
	if _current_bar != null:
		_current_bar.value = action.get_progress()


func _rebuild() -> void:
	for child in get_children():
		child.queue_free()
	_current_detail = null
	_current_bar = null
	var items := _character.queue.items
	count_changed.emit(items.size())
	if items.is_empty():
		var empty := Label.new()
		empty.text = "Rien de prévu."
		empty.theme_type_variation = &"MutedLabel"
		add_child(empty)
		return
	add_child(_make_row(items[0], true))
	for i in range(1, mini(items.size(), MAX_WAITING + 1)):
		add_child(_make_row(items[i], false))
	var hidden := items.size() - 1 - MAX_WAITING
	if hidden > 0:
		var more := Label.new()
		more.text = "+ %d autre%s action%s" % [hidden, "s" if hidden > 1 else "", "s" if hidden > 1 else ""]
		more.theme_type_variation = &"MutedLabel"
		more.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(more)


func _make_row(action: QueuedAction, is_current: bool) -> Control:
	var card := PanelContainer.new()
	var style := HudTheme.box(Color.WHITE if is_current else Palette.PAPIER_2, Palette.RAYON_ELEMENT,
			Palette.ACCENT if is_current else Color.TRANSPARENT, 2 if is_current else 0)
	style.content_margin_left = 12 if is_current else 8
	style.content_margin_right = 8 if is_current else 4
	style.content_margin_top = 8 if is_current else 3
	style.content_margin_bottom = 8 if is_current else 3
	card.add_theme_stylebox_override("panel", style)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	card.add_child(column)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	column.add_child(row)

	var icon_box := IconBox.new(32.0, 20.0, 8) if is_current else IconBox.new(24.0, 15.0, 6)
	icon_box.set_icon(MOVE_ICON if action.is_move_only() else action.definition.icon)
	icon_box.set_colors(_main_need_background(action))
	row.add_child(icon_box)

	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_theme_constant_override("separation", 0)
	row.add_child(texts)
	var title := Label.new()
	title.text = "Aller ici" if action.is_move_only() else action.definition.display_name
	title.theme_type_variation = &"StrongLabel"
	title.clip_text = true
	texts.add_child(title)
	var detail := Label.new()
	detail.theme_type_variation = &"MutedLabel"
	detail.text = _detail_text(action)
	detail.clip_text = true
	# En attente : une seule ligne, le détail passe dans l'infobulle.
	detail.visible = is_current
	card.tooltip_text = "" if is_current else _detail_text(action)
	texts.add_child(detail)

	var close := Button.new()
	close.theme_type_variation = &"IconButton"
	close.icon = CLOSE_ICON
	close.expand_icon = true
	close.custom_minimum_size = Vector2(28, 28) if is_current else Vector2(22, 22)
	close.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	close.tooltip_text = "Annuler"
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(_character.queue.cancel.bind(action))
	row.add_child(close)

	if is_current:
		_current_detail = detail
		if not action.is_move_only():
			_current_bar = ProgressBar.new()
			_current_bar.max_value = 1.0
			_current_bar.show_percentage = false
			_current_bar.custom_minimum_size.y = 4
			_current_bar.value = action.get_progress()
			column.add_child(_current_bar)
	return card


## « Frigo · en cours 62 % », « Myrtille · en route », « en attente · auto »…
func _detail_text(action: QueuedAction) -> String:
	var parts: Array[String] = []
	if action.target_object != null:
		parts.append(action.target_object.get_display_name())
	elif action.target_character != null:
		parts.append(action.target_character.get_display_name())
	match action.state:
		QueuedAction.State.RUNNING:
			parts.append("en cours %d %%" % roundi(action.get_progress() * 100))
		QueuedAction.State.MOVING:
			parts.append("en route")
		_:
			parts.append("en attente")
	if action.is_autonomous:
		parts.append("auto")
	return " · ".join(parts)


## Teinte du besoin que l'action remplit le plus (fond de la case d'icône).
func _main_need_background(action: QueuedAction) -> Color:
	if action.is_move_only():
		return Palette.PAPIER_2
	var best_id: StringName
	var best_gain := 0.0
	for need_id in action.definition.need_gains:
		if action.definition.need_gains[need_id] > best_gain:
			best_gain = action.definition.need_gains[need_id]
			best_id = need_id
	var definition := _character.needs.get_definition(best_id)
	return definition.background_color if definition != null else Palette.PAPIER_2
