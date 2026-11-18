class_name NeedsPanel
extends VBoxContainer
## Affiche l'humeur et les barres de besoins du personnage sélectionné.

const MOOD_COLOR := Color(0.95, 0.8, 0.3)

var _needs: NeedsComponent
var _bars: Dictionary[StringName, NeedBar] = {}
var _mood_bar: NeedBar


func set_character(character: Character) -> void:
	if _needs != null:
		_needs.need_changed.disconnect(_on_need_changed)
		_needs.mood_changed.disconnect(_on_mood_changed)
	for child in get_children():
		child.queue_free()
	_bars.clear()

	_needs = character.needs
	_mood_bar = _add_bar("Humeur", MOOD_COLOR, 0.0)
	_mood_bar.set_value(_needs.get_mood())
	add_child(HSeparator.new())
	for definition in _needs.definitions:
		var bar := _add_bar(definition.display_name, definition.color, definition.critical_threshold)
		bar.set_value(_needs.get_value(definition.id))
		_bars[definition.id] = bar

	_needs.need_changed.connect(_on_need_changed)
	_needs.mood_changed.connect(_on_mood_changed)


func _add_bar(title: String, color: Color, critical_threshold: float) -> NeedBar:
	var bar := NeedBar.new()
	bar.setup(title, color, critical_threshold)
	add_child(bar)
	return bar


func _on_need_changed(need_id: StringName, value: float) -> void:
	if _bars.has(need_id):
		_bars[need_id].set_value(value)


func _on_mood_changed(mood: float) -> void:
	_mood_bar.set_value(mood)
