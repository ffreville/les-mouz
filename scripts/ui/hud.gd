class_name Hud
extends CanvasLayer
## Interface principale : applique le thème et relaie le personnage sélectionné aux panneaux.

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


func _ready() -> void:
	var theme := HudTheme.build()
	root.theme = theme
	context_menu.theme = theme
	autonomy_toggle.icon = CHECK_ICON
	autonomy_toggle.toggled.connect(_on_autonomy_toggled)
	queue_panel.count_changed.connect(func(count: int) -> void: queue_count.text = str(count))
	EventBus.character_selected.connect(_on_character_selected)


func _on_character_selected(character: Node) -> void:
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
