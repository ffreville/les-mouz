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
var skills_panel := SkillsPanel.new()
var bills_button := BillsButton.new()
var level_selector := LevelSelector.new()
## Tourner / Poser / Annuler au doigt (téléphone).
var placement_bar := PlacementBar.new()
var _holding := false
@onready var relationship_panel: RelationshipPanel = %RelationshipPanel
@onready var queue_panel: ActionQueuePanel = %ActionQueuePanel
@onready var queue_help: Label = %QueueHelp
@onready var queue_count: Label = %QueueCount
@onready var autonomy_toggle: Button = %AutonomyToggle
@onready var left_column: Control = %LeftColumn
@onready var right_panel: Control = %RightColumn
@onready var build_panel: BuildPanel = %BuildPanel
## Ce qu'on montre ou cache pour le panneau Construire (sa zone qui défile, sur téléphone).
@onready var build_panel_area: Control = %BuildPanel
@onready var catalog_panel: CatalogPanel = %CatalogPanel
@onready var logo: Button = %Logo
const MENU_ICON := preload("res://assets/icons/ink/menu.svg")
var _fitting := false
@onready var pause_menu: PauseMenu = %PauseMenu
@onready var toast: Toast = %Toast
@onready var clock_panel: ClockPanel = %ClockPanel
@onready var speed_group: Control = %SpeedGroup
@onready var pause_pill: Control = %PausePill


func _ready() -> void:
	var theme := HudTheme.build()
	root.theme = theme
	context_menu.theme = theme
	autonomy_toggle.icon = CHECK_ICON
	autonomy_toggle.toggled.connect(_on_autonomy_toggled)
	queue_panel.count_changed.connect(_on_queue_count_changed)
	EventBus.character_selected.connect(_on_character_selected)
	GameMode.mode_changed.connect(_on_mode_changed)
	_on_mode_changed(GameMode.mode)
	_setup_game_menu()
	_setup_skills_tab()
	# Étage regardé, juste après les onglets Vivre / Construire / Acheter.
	var tabs := root.get_node("TopBar/Row/ModeTabs")
	tabs.get_parent().add_child(level_selector)
	tabs.get_parent().move_child(level_selector, tabs.get_index() + 1)
	# Factures, juste avant l'argent dans la barre du haut.
	var funds := root.get_node("TopBar/Row/FundsDisplay")
	funds.get_parent().add_child(bills_button)
	funds.get_parent().move_child(bills_button, funds.get_index())
	EventBus.bill_received.connect(func(_amount: int) -> void: Sfx.play(&"alerte", -4.0))
	# Petites annonces, par-dessus tout le reste de l'interface.
	var job_board := JobBoardPanel.new()
	root.add_child(job_board)
	# Les messages restent lisibles au-dessus du voile des annonces.
	if toast.get_parent() == root:
		root.move_child(job_board, toast.get_index())
	EventBus.notice.connect(func(text: String) -> void: toast.show_message(text))
	if Device.mobile:
		MobileLayout.apply(self)
		root.add_child(placement_bar)
		_on_mode_changed(GameMode.mode)
	EventBus.salary_paid.connect(func(_character: Node, _amount: int) -> void: Sfx.play(&"achat"))


func _on_character_selected(character: Node) -> void:
	if build_panel.editor == null:
		build_panel.setup(character.world.editor)
		bills_button.setup(character.world.bills)
		level_selector.setup(character.world)
		pause_menu.setup(character.world)
		if Device.mobile:
			placement_bar.setup(character.world.buy_controller)
			character.world.buy_controller.holding_changed.connect(_on_holding_changed)
	if _selected != null:
		_selected.brain.enabled_changed.disconnect(_on_brain_enabled_changed)
	_selected = character
	_selected.brain.enabled_changed.connect(_on_brain_enabled_changed)
	mouz_header.set_character(_selected)
	needs_panel.set_character(_selected)
	skills_panel.set_character(_selected)
	relationship_panel.set_character(_selected)
	queue_panel.set_character(_selected)
	_on_brain_enabled_changed(_selected.brain.enabled)


## Onglets « Besoins / Compétences » au-dessus des jauges du Mouz.
func _setup_skills_tab() -> void:
	var tabs := ChoiceGroup.new([[&"besoins", "Besoins"], [&"competences", "Compétences"]])
	tabs.select(&"besoins")
	var parent := needs_panel.get_parent()
	parent.add_child(tabs)
	parent.move_child(tabs, needs_panel.get_index())
	skills_panel.visible = false
	parent.add_child(skills_panel)
	parent.move_child(skills_panel, needs_panel.get_index() + 1)
	var show_tab := func(id: StringName) -> void:
		needs_panel.visible = id == &"besoins"
		skills_panel.visible = id == &"competences"
	tabs.chosen.connect(show_tab)


func _on_queue_count_changed(count: int) -> void:
	queue_count.text = str(count)
	# L'aide ne sert que tant que la file est vide.
	queue_help.visible = count == 0


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
	build_panel_area.visible = mode == GameMode.Mode.BUILD
	# Sur téléphone, le catalogue s'efface tant qu'on tient un objet (place pour la maison).
	catalog_panel.visible = mode == GameMode.Mode.BUY and not _holding


func _on_holding_changed(holding: bool) -> void:
	_holding = holding
	_on_mode_changed(GameMode.mode)


## Resserre la barre du haut si elle déborde de l'écran : le logo devient l'icône du menu, puis
## les onglets Vivre / Construire / Acheter ne gardent que leur icône, l'horloge perd la saison et
## la température, et le sélecteur d'étage son nom. Elle se rouvre dès qu'il y a la place.
func _fit_top_bar() -> void:
	if _fitting:
		return
	_fitting = true
	var bar: Control = root.get_node("TopBar")
	var row: Control = root.get_node("TopBar/Row")
	var tabs = root.get_node("TopBar/Row/ModeTabs")
	var room := get_viewport().get_visible_rect().size.x - 24.0 - (bar.get_minimum_size().x - row.get_combined_minimum_size().x)
	# Sur téléphone, on part directement du logo en icône.
	for step in range(1 if Device.mobile else 0, 5):
		logo.text = "" if step >= 1 else "Les Mouz"
		logo.icon = MENU_ICON if step >= 1 else null
		tabs.set_compact(step >= 2)
		clock_panel.set_compact(step >= 3)
		level_selector.set_compact(step >= 4)
		if row.get_combined_minimum_size().x <= room:
			break
	_fitting = false


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
	# Barre du haut trop étroite (facture affichée, petite fenêtre) : on la resserre.
	var row: Control = root.get_node("TopBar/Row")
	row.minimum_size_changed.connect(_fit_top_bar)
	get_viewport().size_changed.connect(_fit_top_bar)
	_fit_top_bar.call_deferred()
	pause_menu.message.connect(_on_save_message)
	GameMode.wall_mode_changed.connect(_on_wall_mode_changed)
	GameMode.roof_changed.connect(_on_roof_changed)


func _on_wall_mode_changed(_wall_mode: int) -> void:
	if not GameMode.show_roof:
		toast.show_message("%s (touche V)" % GameMode.WALL_MODE_NAMES[GameMode.wall_mode])


func _on_roof_changed(shown: bool) -> void:
	toast.show_message("Toit affiché (touche T)" if shown else "Toit masqué (touche T)")


## Résultat d'une sauvegarde : réussite (2 s) ou échec avec « Réessayer » (6 s).
func _on_save_message(text: String, ok: bool, retry: Callable) -> void:
	if ok:
		toast.show_message(text, Toast.Kind.SUCCESS)
	else:
		toast.show_message(text, Toast.Kind.FAILURE, "Disque plein ou dossier protégé.", retry)
