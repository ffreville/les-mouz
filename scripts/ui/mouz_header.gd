class_name MouzHeader
extends HBoxContainer
## En-tête du panneau du Mouz : portrait, nom et humeur en mots (Grognon, Bof…).

var _portrait_box := PanelContainer.new()
var _portrait := TextureRect.new()
var _name := Label.new()
var _mood := Label.new()
var _needs: NeedsComponent


func _ready() -> void:
	add_theme_constant_override("separation", 12)
	_portrait_box.custom_minimum_size = Vector2(64, 64)
	_portrait.custom_minimum_size = Vector2(48, 48)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_portrait_box.add_child(_portrait)
	add_child(_portrait_box)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 0)
	_name.theme_type_variation = &"BigLabel"
	_mood.theme_type_variation = &"MutedLabel"
	column.add_child(_name)
	column.add_child(_mood)
	add_child(column)


func set_character(character: Character) -> void:
	if _needs != null:
		_needs.mood_changed.disconnect(_on_mood_changed)
	_needs = character.needs
	_needs.mood_changed.connect(_on_mood_changed)
	_portrait.texture = character.profile.sprite
	_portrait_box.add_theme_stylebox_override("panel",
			HudTheme.box(character.profile.color.lightened(0.6), 14, Palette.TRAIT, 2))
	_name.text = character.get_display_name()
	_on_mood_changed(_needs.get_mood())


func _on_mood_changed(mood: float) -> void:
	_mood.text = "Humeur : %s" % Palette.mot_humeur(mood)
