class_name RelationshipPanel
extends VBoxContainer
## Relation du personnage sélectionné avec chacun des autres : une ligne par membre
## (portrait, prénom, lien de famille, palier en mots) et une jauge de -100 à +100.
## Les voisins en visite y apparaissent aussi, le temps de leur visite.

const HEART_ICON := preload("res://assets/icons/white/relation.svg")

var _character: Character
## Pour chaque autre personnage : sa jauge et son libellé, mis à jour sur place.
var _gauges: Dictionary[Node, NeedGauge] = {}
var _tiers: Dictionary[Node, Label] = {}


func _ready() -> void:
	add_theme_constant_override("separation", 12)
	EventBus.relationship_changed.connect(_on_relationship_changed)
	EventBus.visitor_arrived.connect(_on_visitors_changed)
	EventBus.visitor_left.connect(_on_visitors_changed)


func _on_visitors_changed(_visitor: Node) -> void:
	if _character != null and is_instance_valid(_character):
		_rebuild()


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
	for other in _character.world.people:
		if other != _character:
			add_child(_make_block(other, _character.relationships.get_value(other)))


func _make_block(other: Character, value: float) -> Control:
	var block := VBoxContainer.new()
	block.add_theme_constant_override("separation", 4)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var face := MouzPortrait.new(32)
	face.appearance = other.profile.appearance
	face.background = other.profile.color.lightened(0.6)
	row.add_child(face)
	var name_label := Label.new()
	name_label.text = other.get_display_name()
	name_label.theme_type_variation = &"StrongLabel"
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(name_label)
	var link := _character.world.family.link_label(String(_character.profile.id), String(other.profile.id))
	if other.is_visitor():
		var guest := _small("En visite")
		guest.tooltip_text = "Famille %s" % other.family_name
		guest.mouse_filter = Control.MOUSE_FILTER_PASS
		row.add_child(guest)
	elif link != "":
		var heart := TextureRect.new()
		heart.texture = HEART_ICON
		heart.modulate = Palette.ACCENT
		heart.custom_minimum_size = Vector2(14, 14)
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(heart)
		row.add_child(_small(link))
	row.add_child(_spacer())
	var tier := Label.new()
	tier.text = _tier_text(value)
	_tiers[other] = tier
	tier.theme_type_variation = &"StrongLabel"
	tier.add_theme_font_size_override("font_size", 12)
	tier.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(tier)
	block.add_child(row)

	var gauge := NeedGauge.new()
	gauge.from_center = true
	gauge.min_value = Relationships.MIN_VALUE
	gauge.max_value = Relationships.MAX_VALUE
	gauge.custom_minimum_size.y = 12
	gauge.value = value
	block.add_child(gauge)
	_gauges[other] = gauge
	return block


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
