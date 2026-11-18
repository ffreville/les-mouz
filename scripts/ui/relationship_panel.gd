class_name RelationshipPanel
extends VBoxContainer
## Relation du personnage sélectionné avec chacun des autres :
## portraits, cœur, jauge de -100 à +100 partant du centre, palier en mots.

const HEART_ICON := preload("res://assets/icons/white/relation.svg")

var _character: Character
## Pour chaque autre personnage : sa jauge et son libellé, mis à jour sur place.
var _gauges: Dictionary[Node, NeedGauge] = {}
var _tiers: Dictionary[Node, Label] = {}


func _ready() -> void:
	add_theme_constant_override("separation", 12)
	EventBus.relationship_changed.connect(_on_relationship_changed)


func set_character(character: Character) -> void:
	_character = character
	_rebuild()


func _on_relationship_changed(a: Node, b: Node, value: float, _delta: float) -> void:
	var other: Node = b if a == _character else a
	if (a == _character or b == _character) and _gauges.has(other):
		_gauges[other].value = value
		_tiers[other].text = _tier_text(value)


func _rebuild() -> void:
	for child in get_children():
		child.queue_free()
	_gauges.clear()
	_tiers.clear()
	for other in _character.world.characters:
		if other != _character:
			add_child(_make_block(other, _character.relationships.get_value(other)))


func _make_block(other: Character, value: float) -> Control:
	var block := VBoxContainer.new()
	block.add_theme_constant_override("separation", 6)

	var faces := HBoxContainer.new()
	faces.add_child(_portrait(_character))
	faces.add_child(_spacer())
	var heart := TextureRect.new()
	heart.texture = HEART_ICON
	heart.modulate = Palette.ACCENT
	heart.custom_minimum_size = Vector2(18, 18)
	heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	heart.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	faces.add_child(heart)
	faces.add_child(_spacer())
	faces.add_child(_portrait(other, true))
	block.add_child(faces)

	var gauge := NeedGauge.new()
	gauge.from_center = true
	gauge.min_value = Relationships.MIN_VALUE
	gauge.max_value = Relationships.MAX_VALUE
	gauge.custom_minimum_size.y = 16
	gauge.value = value
	block.add_child(gauge)
	_gauges[other] = gauge

	var legend := HBoxContainer.new()
	legend.add_child(_small("−100"))
	var tier := Label.new()
	tier.text = _tier_text(value)
	_tiers[other] = tier
	tier.add_theme_font_size_override("font_size", 13)
	tier.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tier.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	legend.add_child(tier)
	legend.add_child(_small("+100"))
	block.add_child(legend)
	return block


## Petit portrait 32 px avec le nom (à droite du portrait, ou à gauche si `mirrored`).
func _portrait(character: Character, mirrored := false) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var face := TextureRect.new()
	face.texture = character.profile.sprite
	face.custom_minimum_size = Vector2(32, 32)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var label := Label.new()
	label.text = character.get_display_name()
	label.add_theme_font_size_override("font_size", 13)
	if mirrored:
		row.add_child(label)
		row.add_child(face)
	else:
		row.add_child(face)
		row.add_child(label)
	return row


func _spacer() -> Control:
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return spacer


func _small(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = &"MutedLabel"
	label.add_theme_font_size_override("font_size", 11)
	return label


## « Copains · +35 ».
func _tier_text(value: float) -> String:
	return "%s · %+d" % [Palette.palier_relation(value), roundi(value)]
