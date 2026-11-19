class_name MouzHeader
extends HBoxContainer
## En-tête du panneau du Mouz : portrait, nom et humeur en mots (Grognon, Bof…).

var _portrait := MouzPortrait.new(64)
var _name := Label.new()
var _mood := Label.new()
var _needs: NeedsComponent


func _ready() -> void:
	add_theme_constant_override("separation", 12)
	_portrait.ring_width = 2.0
	add_child(_portrait)

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
	_portrait.appearance = character.profile.appearance
	_portrait.background = character.profile.color.lightened(0.6)
	_name.text = character.get_display_name()
	_on_mood_changed(_needs.get_mood())


func _on_mood_changed(mood: float) -> void:
	_mood.text = "Humeur : %s" % Palette.mot_humeur(mood)
