class_name LevelSelector
extends PanelContainer
## Sélecteur d'étage de la barre du haut (brief n° 7, version compacte) : une pastille avec « descendre »,
## trois points qui montrent l'étage regardé parmi les trois, son nom court (« RDC », « 1er », « 2e »)
## et « monter ». Le nom complet est dans l'infobulle. Page bas / Page haut aussi.
## Après un trait, la vue de la maison en mode Vivre : la hauteur des murs (pleins, coupés,
## baissés ; touche V) et le toit affiché ou non (touche T).

const DOWN_ICON := preload("res://assets/icons/ink/etage_descendre.svg")
const UP_ICON := preload("res://assets/icons/ink/etage_monter.svg")
const WALLS_ICON := preload("res://assets/icons/ink/murs.svg")
const ROOF_ICON := preload("res://assets/icons/ink/toit.svg")
const HEIGHT := 44.0
const BUTTON := 32.0

var _world: World
var _down := Button.new()
var _up := Button.new()
var _label := Label.new()
var _dots := Control.new()
var _walls := Button.new()
var _roof := Button.new()


func _ready() -> void:
	theme_type_variation = &"SpeedGroup"
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	custom_minimum_size.y = HEIGHT
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	add_child(row)
	for button in [_down, _up, _walls, _roof]:
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(BUTTON, BUTTON)
		button.expand_icon = true
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		button.add_theme_stylebox_override("normal", HudTheme.box(Color.TRANSPARENT, 9, Color.TRANSPARENT, 0, 6))
		button.add_theme_stylebox_override("hover", HudTheme.box(Color.WHITE, 9, Palette.ACCENT, 2, 6))
		button.add_theme_stylebox_override("pressed", HudTheme.box(Palette.CONTOUR, 9, Color.TRANSPARENT, 0, 6))
		button.add_theme_stylebox_override("disabled", HudTheme.box(Color.TRANSPARENT, 9, Color.TRANSPARENT, 0, 6))
		button.add_theme_color_override("icon_pressed_color", Palette.PAPIER)
		button.add_theme_color_override("icon_disabled_color", Color(Palette.ENCRE, 0.35))
	_down.icon = DOWN_ICON
	_down.tooltip_text = "Descendre d'un étage (Page bas)"
	_down.pressed.connect(func() -> void: _step(-1))
	_up.icon = UP_ICON
	_up.tooltip_text = "Monter d'un étage (Page haut)"
	_up.pressed.connect(func() -> void: _step(1))
	_dots.custom_minimum_size = Vector2(6, 22)
	_dots.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_dots.draw.connect(_draw_dots)
	_label.add_theme_font_override("font", HudTheme.font(HudTheme.BALOO, 800))
	_label.add_theme_font_size_override("font_size", 18)
	_label.custom_minimum_size.x = 34
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.mouse_filter = Control.MOUSE_FILTER_PASS
	_label.add_theme_color_override("font_color", Palette.ENCRE)
	_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_down)
	row.add_child(_dots)
	row.add_child(_label)
	row.add_child(_up)
	var line := ColorRect.new()
	line.color = Color(Palette.ENCRE_DOUCE, 0.3)
	line.custom_minimum_size = Vector2(2, 24)
	line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(line)
	_walls.icon = WALLS_ICON
	_walls.pressed.connect(GameMode.cycle_wall_mode)
	row.add_child(_walls)
	_roof.icon = ROOF_ICON
	_roof.toggle_mode = true
	_roof.toggled.connect(GameMode.set_show_roof)
	# Toit affiché : bouton enfoncé, sans le survol qui le cacherait.
	_roof.add_theme_stylebox_override("hover_pressed", HudTheme.box(Palette.CONTOUR, 9, Palette.ACCENT, 2, 6))
	_roof.add_theme_color_override("icon_hover_pressed_color", Palette.PAPIER)
	row.add_child(_roof)
	GameMode.wall_mode_changed.connect(func(_wall_mode: int) -> void: _refresh_view())
	GameMode.roof_changed.connect(func(_shown: bool) -> void: _refresh_view())
	GameMode.mode_changed.connect(func(_mode: int) -> void: _refresh_view())
	_refresh_view()
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
	tooltip_text = Levels.display_name(level)
	_down.disabled = level <= 0
	_up.disabled = level >= Levels.COUNT - 1
	_dots.queue_redraw()


## Boutons de la vue de la maison : état courant dans l'infobulle, grisés hors du mode Vivre.
func _refresh_view() -> void:
	var live := GameMode.is_live()
	_walls.disabled = not live
	_roof.disabled = not live
	_roof.set_pressed_no_signal(GameMode.show_roof)
	if not live:
		_walls.tooltip_text = "Murs baissés pour construire"
		_roof.tooltip_text = "Toit masqué pour construire"
		return
	var walls: String = "Murs pleins (avec le toit)" if GameMode.show_roof else GameMode.WALL_MODE_NAMES[GameMode.wall_mode]
	_walls.tooltip_text = "%s : cliquer pour changer (V)" % walls
	_roof.tooltip_text = "Masquer le toit (T)" if GameMode.show_roof else "Afficher le toit (T)"


## Trois points empilés, du 2e étage (en haut) au rez-de-chaussée (en bas) ; celui de l'étage regardé est plein.
func _draw_dots() -> void:
	var level := _world.view_level if _world != null else 0
	for i in Levels.COUNT:
		var center := Vector2(3, 3 + (Levels.COUNT - 1 - i) * 8)
		if i == level:
			_dots.draw_circle(center, 3.0, Palette.CONTOUR)
		else:
			_dots.draw_circle(center, 2.2, Color(Palette.ENCRE_DOUCE, 0.45))


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
