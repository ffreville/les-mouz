class_name MouzHeader
extends HBoxContainer
## En-tête du panneau du Mouz : portrait, nom, humeur en mots (Grognon, Bof…) et métier.

var _portrait := MouzPortrait.new(64)
var _name := Label.new()
var _mood := Label.new()
var _job_label := Label.new()
var _needs: NeedsComponent
var _job: MouzJob


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
	_job_label.theme_type_variation = &"MutedLabel"
	_job_label.add_theme_font_size_override("font_size", 12)
	# Un long nom de métier ne doit pas élargir le panneau.
	_job_label.clip_text = true
	_job_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(_job_label)
	add_child(column)


func set_character(character: Character) -> void:
	if _needs != null:
		_needs.mood_changed.disconnect(_on_mood_changed)
	_needs = character.needs
	if _job != null:
		_job.changed.disconnect(_on_job_changed)
	_job = character.job
	_job.changed.connect(_on_job_changed)
	_on_job_changed()
	_needs.mood_changed.connect(_on_mood_changed)
	_portrait.appearance = character.profile.appearance
	_portrait.background = character.profile.color.lightened(0.6)
	_name.text = character.get_display_name()
	_on_mood_changed(_needs.get_mood())


func _on_mood_changed(mood: float) -> void:
	_mood.text = "Humeur : %s" % Palette.mot_humeur(mood)


func _on_job_changed() -> void:
	_job_label.text = _job.status_text()
