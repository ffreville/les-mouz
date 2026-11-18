class_name RelationshipPanel
extends VBoxContainer
## Affiche les relations du personnage sélectionné avec chacun des autres (-100 à 100).

const POSITIVE_COLOR := Color(0.45, 0.8, 0.45)
const NEGATIVE_COLOR := Color(0.85, 0.35, 0.35)

var _character: Character


func _ready() -> void:
	EventBus.relationship_changed.connect(_on_relationship_changed)


func set_character(character: Character) -> void:
	_character = character
	_rebuild()


func _on_relationship_changed(a: Node, b: Node, _value: float, _delta: float) -> void:
	if a == _character or b == _character:
		_rebuild()


func _rebuild() -> void:
	for child in get_children():
		child.queue_free()
	for other in _character.world.characters:
		if other != _character:
			add_child(_make_row(other, _character.relationships.get_value(other)))


func _make_row(other: Character, value: float) -> Control:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = "%s  %+d" % [other.get_display_name(), roundi(value)]
	label.custom_minimum_size.x = 80
	label.add_theme_font_size_override("font_size", 13)
	row.add_child(label)

	var bar := ProgressBar.new()
	bar.min_value = Relationships.MIN_VALUE
	bar.max_value = Relationships.MAX_VALUE
	bar.value = value
	bar.show_percentage = false
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.custom_minimum_size.y = 10
	var fill := StyleBoxFlat.new()
	fill.bg_color = POSITIVE_COLOR if value >= 0.0 else NEGATIVE_COLOR
	bar.add_theme_stylebox_override("fill", fill)
	row.add_child(bar)
	return row
