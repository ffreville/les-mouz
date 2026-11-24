class_name SkillsPanel
extends VBoxContainer
## Les compétences du Mouz sélectionné : une ligne par compétence (icône, nom, niveau sur 10,
## avancement vers le niveau suivant), et la vitesse d'apprentissage du moment.

const ROW_HEIGHT := 30.0

var _skills: MouzSkills
var _rows: Dictionary[StringName, Dictionary] = {}
var _speed := Label.new()


func _ready() -> void:
	add_theme_constant_override("separation", 4)
	for id in Skills.ids():
		add_child(_make_row(id))
	_speed.theme_type_variation = &"MutedLabel"
	_speed.add_theme_font_size_override("font_size", 12)
	_speed.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_speed)


func set_character(character: Character) -> void:
	if _skills != null:
		_skills.changed.disconnect(_on_changed)
	_skills = character.skills
	_skills.changed.connect(_on_changed)
	_refresh_all()


func _process(_delta: float) -> void:
	# La vitesse dépend de l'humeur, qui bouge tout le temps.
	if visible and _skills != null:
		_speed.text = _speed_text()


func _make_row(id: StringName) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.custom_minimum_size.y = ROW_HEIGHT
	var icon := IconBox.new(24.0, 15.0, 6)
	icon.set_icon(Skills.icon(id))
	icon.set_colors(Skills.color(id).lightened(0.75))
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 2)
	row.add_child(column)
	var line := HBoxContainer.new()
	column.add_child(line)
	var name_label := Label.new()
	name_label.text = Skills.display_name(id)
	name_label.theme_type_variation = &"StrongLabel"
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(name_label)
	var level := Label.new()
	level.theme_type_variation = &"StrongLabel"
	level.add_theme_font_size_override("font_size", 13)
	line.add_child(level)
	var bar := ProgressBar.new()
	bar.max_value = 1.0
	bar.show_percentage = false
	bar.custom_minimum_size.y = 5
	var fill := HudTheme.box(Skills.color(id), 3)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", HudTheme.box(Palette.PAPIER_2, 3))
	column.add_child(bar)
	_rows[id] = {"level": level, "bar": bar}
	return row


func _refresh_all() -> void:
	for id in _rows:
		_refresh(id)
	_speed.text = _speed_text()


func _refresh(id: StringName) -> void:
	var level := _skills.level(id)
	_rows[id]["level"].text = "Niv. %d" % level
	_rows[id]["bar"].value = _skills.progress(id)


func _on_changed(skill: StringName) -> void:
	if skill == &"":
		_refresh_all()
	elif _rows.has(skill):
		_refresh(skill)


func _speed_text() -> String:
	match _skills.mood_key():
		&"bonne":
			return "De bonne humeur : apprend vite (×1,5)."
		&"mauvaise":
			return "De mauvaise humeur : apprend lentement (×0,5)."
	return "Apprend en pratiquant : cuisiner, lire, jouer du piano…"
