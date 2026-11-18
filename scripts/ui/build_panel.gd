class_name BuildPanel
extends PanelContainer
## Panneau du mode Construire : grille d'outils, options de l'outil actif, phrase d'aide.
## Le choix est transmis au BuildController par EventBus.build_tool_selected.

## [identifiant, libellé, icône, aide]. « undo » est une action immédiate, pas un outil.
const TOOLS := [
	[&"wall", "Mur", "mur", "Glisse le long de la grille pour tracer un mur droit."],
	[&"demolish", "Démolir", "demolir", "Glisse sur des murs pour les démolir (portes et fenêtres comprises)."],
	[&"door", "Porte", "porte", "Clique sur un mur. Le battant s'ouvre du côté du pointeur ; R inverse la charnière."],
	[&"window", "Fenêtre", "fenetre", "Clique sur un mur pour y poser la fenêtre."],
	[&"floor", "Sol", "sol", "Glisse pour peindre un rectangle de sol."],
	[&"eraser", "Gomme", "gomme", "Glisse pour retirer le sol (l'herbe revient, le prix est rendu)."],
	[&"move", "Déplacer", "deplacer", "Clique sur un objet pour le reprendre, puis repose-le."],
	[&"undo", "Annuler", "annuler", "Annule la dernière opération (Ctrl+Z)."],
]
## Outils pas encore disponibles.
const DISABLED_TOOLS: Array[StringName] = [&"door", &"window", &"floor", &"eraser", &"move"]

var editor: LotEditor
var _buttons: Dictionary[StringName, Button] = {}
var _options := ToolOptions.new()
var _help := Label.new()
var _tool: StringName = &"wall"


func _ready() -> void:
	custom_minimum_size.x = 272
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	add_child(column)
	var title := Label.new()
	title.text = "OUTILS"
	title.theme_type_variation = &"SectionTitle"
	column.add_child(title)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	column.add_child(grid)
	var group := ButtonGroup.new()
	for spec in TOOLS:
		var button := _make_tool_button(spec)
		if spec[0] != &"undo":
			button.toggle_mode = true
			button.button_group = group
		grid.add_child(button)
		_buttons[spec[0]] = button

	var separator := HSeparator.new()
	separator.add_theme_stylebox_override("separator", _line())
	column.add_child(separator)
	column.add_child(_options)
	_options.option_selected.connect(_on_option_selected)
	_help.theme_type_variation = &"MutedLabel"
	_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_help)
	_select_tool.call_deferred(&"wall")


func setup(p_editor: LotEditor) -> void:
	editor = p_editor
	editor.history_changed.connect(func(can: bool) -> void: _buttons[&"undo"].disabled = not can)
	_buttons[&"undo"].disabled = not editor.can_undo()


func _make_tool_button(spec: Array) -> Button:
	var button := Button.new()
	button.theme_type_variation = &"ToolButton"
	button.text = spec[1]
	button.icon = load("res://assets/icons/white/%s.svg" % spec[2])
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	button.custom_minimum_size = Vector2(56, 56)
	button.focus_mode = Control.FOCUS_NONE
	button.tooltip_text = spec[3]
	button.disabled = spec[0] in DISABLED_TOOLS
	if spec[0] == &"undo":
		button.pressed.connect(func() -> void: editor.undo())
	else:
		button.pressed.connect(_select_tool.bind(spec[0]))
	return button


func _select_tool(tool: StringName) -> void:
	_tool = tool
	for key in _buttons:
		_buttons[key].set_pressed_no_signal(key == tool)
	for spec in TOOLS:
		if spec[0] == tool:
			_help.text = spec[3]
	_options.show_for(tool)
	EventBus.build_tool_selected.emit(tool, _options.selected)


func _on_option_selected(option: Resource) -> void:
	EventBus.build_tool_selected.emit(_tool, option)


func _line() -> StyleBoxLine:
	var line := StyleBoxLine.new()
	line.color = Palette.PAPIER_2
	line.thickness = 2
	return line
