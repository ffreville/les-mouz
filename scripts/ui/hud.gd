class_name Hud
extends CanvasLayer
## Interface principale : applique le thème, relaie le personnage sélectionné aux panneaux
## et montre les panneaux du mode courant (Vivre, Construire, Acheter).

const CHECK_ICON := preload("res://assets/icons/white/valider.svg")

var _selected: Character

@onready var root: Control = $Root
@onready var context_menu: ContextMenu = $ContextMenu
@onready var mouz_header: MouzHeader = %MouzHeader
@onready var needs_panel: NeedsPanel = %NeedsPanel
@onready var relationship_panel: RelationshipPanel = %RelationshipPanel
@onready var queue_panel: ActionQueuePanel = %ActionQueuePanel
@onready var queue_count: Label = %QueueCount
@onready var autonomy_toggle: Button = %AutonomyToggle
@onready var left_column: Control = %LeftColumn
@onready var right_panel: Control = %RightColumn
@onready var build_panel: BuildPanel = %BuildPanel
@onready var catalog_panel: CatalogPanel = %CatalogPanel
@onready var logo: Button = %Logo
@onready var pause_menu: PauseMenu = %PauseMenu
@onready var toast: Toast = %Toast
@onready var clock_panel: Control = %ClockPanel
@onready var speed_group: Control = %SpeedGroup
@onready var pause_pill: Control = %PausePill


func _ready() -> void:
	var theme := HudTheme.build()
	root.theme = theme
	context_menu.theme = theme
	autonomy_toggle.icon = CHECK_ICON
	autonomy_toggle.toggled.connect(_on_autonomy_toggled)
	queue_panel.count_changed.connect(func(count: int) -> void: queue_count.text = str(count))
	EventBus.character_selected.connect(_on_character_selected)
	GameMode.mode_changed.connect(_on_mode_changed)
	_on_mode_changed(GameMode.mode)
	_setup_game_menu()


func _on_character_selected(character: Node) -> void:
	if build_panel.editor == null:
		build_panel.setup(character.world.editor)
		pause_menu.setup(character.world)
	if _selected != null:
		_selected.brain.enabled_changed.disconnect(_on_brain_enabled_changed)
	_selected = character
	_selected.brain.enabled_changed.connect(_on_brain_enabled_changed)
	mouz_header.set_character(_selected)
	needs_panel.set_character(_selected)
	relationship_panel.set_character(_selected)
	queue_panel.set_character(_selected)
	_on_brain_enabled_changed(_selected.brain.enabled)


func _on_autonomy_toggled(pressed: bool) -> void:
	if _selected != null:
		_selected.brain.enabled = pressed


func _on_brain_enabled_changed(enabled: bool) -> void:
	autonomy_toggle.set_pressed_no_signal(enabled)


func _on_mode_changed(mode: int) -> void:
	var live := mode == GameMode.Mode.LIVE
	left_column.visible = live
	right_panel.visible = live
	clock_panel.visible = live
	speed_group.visible = live
	pause_pill.visible = not live
	build_panel.visible = mode == GameMode.Mode.BUILD
	catalog_panel.visible = mode == GameMode.Mode.BUY


## Le logo ouvre le menu du jeu (comme Échap).
func _setup_game_menu() -> void:
	logo.add_theme_font_override("font", HudTheme.font(HudTheme.BALOO, 800))
	logo.add_theme_font_size_override("font_size", 24)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		logo.add_theme_color_override(state, Palette.ENCRE)
	# Sans marges, pour garder la barre du haut à sa hauteur.
	for state in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
		logo.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	logo.pressed.connect(pause_menu.open)
	pause_menu.message.connect(toast.show_message)
	GameMode.wall_mode_changed.connect(_on_wall_mode_changed)


func _on_wall_mode_changed(wall_mode: int) -> void:
	toast.show_message("%s (touche V)" % GameMode.WALL_MODE_NAMES[wall_mode])
