class_name CharacterSwitcher
extends HBoxContainer
## Sélecteur de famille : un portrait de 40 px et le prénom en dessous par Mouz.
## Le Mouz contrôlé a un anneau accent. Raccourci : Tab passe au suivant.

const PORTRAIT_SIZE := 40.0

var _world: World
var _portraits: Dictionary[Node, MouzPortrait] = {}
var _badges: Dictionary[Node, PanelContainer] = {}


func _ready() -> void:
	add_theme_constant_override("separation", 6)
	EventBus.character_selected.connect(_on_character_selected)


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if _world == null or key == null or not key.pressed or key.echo or key.keycode != KEY_TAB:
		return
	var characters := _world.characters
	var index := characters.find(_world.selection.selected)
	_world.selection.select(characters[(index + 1) % characters.size()])
	get_viewport().set_input_as_handled()


func _on_character_selected(character: Node) -> void:
	if _world == null:
		_build(character.world)
	for other in _portraits:
		var chosen: bool = other == character
		_portraits[other].ring_color = Palette.ACCENT if chosen else Palette.TRAIT
		_portraits[other].ring_width = 3.0 if chosen else 2.0
		_portraits[other].queue_redraw()


func _build(world: World) -> void:
	_world = world
	for character in world.characters:
		var button := Button.new()
		button.flat = true
		button.focus_mode = Control.FOCUS_NONE
		button.tooltip_text = "Contrôler %s (Tab)" % character.get_display_name()
		button.custom_minimum_size = Vector2(56, 60)
		var column := VBoxContainer.new()
		column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		column.add_theme_constant_override("separation", 0)
		column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var portrait := MouzPortrait.new(PORTRAIT_SIZE)
		portrait.appearance = character.profile.appearance
		portrait.background = character.profile.color.lightened(0.6)
		portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		column.add_child(portrait)
		# Repère d'étage (brief n° 7), seulement quand le Mouz n'est pas à l'étage regardé.
		var badge := _level_badge()
		portrait.add_child(badge)
		_badges[character] = badge
		var label := Label.new()
		label.text = character.get_display_name()
		label.theme_type_variation = &"StrongLabel"
		label.add_theme_font_size_override("font_size", 11)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.clip_text = true
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(label)
		button.add_child(column)
		button.pressed.connect(world.selection.select.bind(character))
		add_child(button)
		_portraits[character] = portrait
	EventBus.view_level_changed.connect(func(_level: int) -> void: _refresh_badges())
	EventBus.character_level_changed.connect(func(_character: Node, _level: int) -> void: _refresh_badges())
	_refresh_badges()


## Pastille « RDC », « 1er », « 2e » à −6, −6 du coin du portrait, liseré papier.
func _level_badge() -> PanelContainer:
	var badge := PanelContainer.new()
	var style := HudTheme.box(Palette.CONTOUR, 9, Palette.PAPIER, 2)
	style.content_margin_left = 5
	style.content_margin_right = 5
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	badge.add_theme_stylebox_override("panel", style)
	badge.position = Vector2(-6, -6)
	badge.custom_minimum_size.y = 18
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := Label.new()
	label.add_theme_font_override("font", HudTheme.font(HudTheme.NUNITO, 800))
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Palette.PAPIER)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_child(label)
	return badge


func _refresh_badges() -> void:
	for character in _badges:
		if not is_instance_valid(character):
			continue
		var badge: PanelContainer = _badges[character]
		badge.visible = character.level != _world.view_level
		(badge.get_child(0) as Label).text = Levels.SHORT_NAMES[character.level]
