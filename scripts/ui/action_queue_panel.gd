class_name ActionQueuePanel
extends VBoxContainer
## Affiche la file d'actions du personnage sélectionné, avec un bouton ✕ par action.

var _queue: ActionQueue
var _current_bar: ProgressBar


func set_character(character: Character) -> void:
	if _queue != null:
		_queue.changed.disconnect(_rebuild)
	_queue = character.queue
	_queue.changed.connect(_rebuild)
	_rebuild()


func _process(_delta: float) -> void:
	if _current_bar != null and _queue != null and not _queue.is_empty():
		_current_bar.value = _queue.current().get_progress()


func _rebuild() -> void:
	for child in get_children():
		child.queue_free()
	_current_bar = null
	if _queue.is_empty():
		var empty := Label.new()
		empty.text = "(vide)"
		empty.modulate.a = 0.5
		add_child(empty)
		return
	for i in _queue.items.size():
		add_child(_make_row(_queue.items[i], i == 0))


func _make_row(action: QueuedAction, is_current: bool) -> Control:
	var row := VBoxContainer.new()
	var line := HBoxContainer.new()
	row.add_child(line)

	var label := Label.new()
	label.text = action.get_label() + (" (auto)" if action.is_autonomous else "")
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.clip_text = true
	label.add_theme_font_size_override("font_size", 13)
	if is_current:
		label.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
	line.add_child(label)

	var cancel_button := Button.new()
	cancel_button.text = "✕"
	cancel_button.tooltip_text = "Annuler"
	cancel_button.focus_mode = Control.FOCUS_NONE
	cancel_button.pressed.connect(_queue.cancel.bind(action))
	line.add_child(cancel_button)

	if is_current and not action.is_move_only():
		_current_bar = ProgressBar.new()
		_current_bar.max_value = 1.0
		_current_bar.show_percentage = false
		_current_bar.custom_minimum_size.y = 6
		_current_bar.value = action.get_progress()
		row.add_child(_current_bar)
	return row
