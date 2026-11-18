class_name NeedsPanel
extends VBoxContainer
## Affiche l'humeur et les barres de besoins du personnage sélectionné.

const MOOD_COLOR := Color("#6C5BB3")
const MOOD_BACKGROUND := Color("#E6E1F5")
const MOOD_ICON := preload("res://assets/icons/ink/humeur.svg")

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
	_mood_bar = _add_bar("Humeur", MOOD_ICON, MOOD_COLOR, MOOD_BACKGROUND, Palette.SEUIL_CRITIQUE)
	_mood_bar.set_value(_needs.get_mood())
	for definition in _needs.definitions:
		var bar := _add_bar(definition.display_name, definition.icon, definition.color,
				definition.background_color, definition.critical_threshold)
		bar.set_value(_needs.get_value(definition.id))
		_bars[definition.id] = bar

	_needs.need_changed.connect(_on_need_changed)
	_needs.mood_changed.connect(_on_mood_changed)


func _add_bar(title: String, icon: Texture2D, color: Color, background: Color, critical: float) -> NeedBar:
	var bar := NeedBar.new()
	bar.setup(title, icon, color, background, critical)
	add_child(bar)
	return bar


func _on_need_changed(need_id: StringName, value: float) -> void:
	if _bars.has(need_id):
		_bars[need_id].set_value(value)


func _on_mood_changed(mood: float) -> void:
	_mood_bar.set_value(mood)
