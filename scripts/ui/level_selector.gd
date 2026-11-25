class_name LevelSelector
extends PanelContainer
## Sélecteur d'étage de la barre du haut : descendre, nom court de l'étage regardé, monter.
## Page bas / Page haut font la même chose. (Flèches provisoires, en attendant les icônes du brief n° 7.)

var _world: World
var _down := Button.new()
var _up := Button.new()
var _label := Label.new()


func _ready() -> void:
	theme_type_variation = &"SpeedGroup"
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	add_child(row)
	for button in [_down, _up]:
		button.theme_type_variation = &"IconButton"
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(30, 30)
	_down.text = "▼"
	_down.tooltip_text = "Descendre d'un étage (Page bas)"
	_down.pressed.connect(func() -> void: _step(-1))
	_up.text = "▲"
	_up.tooltip_text = "Monter d'un étage (Page haut)"
	_up.pressed.connect(func() -> void: _step(1))
	_label.theme_type_variation = &"StrongLabel"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.custom_minimum_size.x = 36
	_label.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(_down)
	row.add_child(_label)
	row.add_child(_up)
	EventBus.view_level_changed.connect(func(_level: int) -> void: _refresh())
	_refresh()


func setup(world: World) -> void:
	_world = world
	_refresh()


func _step(delta: int) -> void:
	if _world != null:
		_world.set_view_level(_world.view_level + delta)


func _refresh() -> void:
	var level := _world.view_level if _world != null else 0
	_label.text = Levels.SHORT_NAMES[level]
	_label.tooltip_text = Levels.display_name(level)
	_down.disabled = level <= 0
	_up.disabled = level >= Levels.COUNT - 1


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_PAGEUP:
		_step(1)
	elif key.keycode == KEY_PAGEDOWN:
		_step(-1)
	else:
		return
	get_viewport().set_input_as_handled()
