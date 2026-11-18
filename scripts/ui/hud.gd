class_name Hud
extends CanvasLayer
## Interface principale : relaie le personnage sélectionné aux différents panneaux.

var _selected: Character

@onready var character_name: Label = %CharacterName
@onready var needs_panel: NeedsPanel = %NeedsPanel
@onready var queue_panel: ActionQueuePanel = %ActionQueuePanel
@onready var autonomy_check: CheckBox = %AutonomyCheck


func _ready() -> void:
	EventBus.character_selected.connect(_on_character_selected)
	autonomy_check.toggled.connect(_on_autonomy_toggled)


func _on_character_selected(character: Node) -> void:
	_selected = character
	character_name.text = _selected.get_display_name()
	needs_panel.set_character(_selected)
	queue_panel.set_character(_selected)
	autonomy_check.set_pressed_no_signal(_selected.brain.enabled)


func _on_autonomy_toggled(pressed: bool) -> void:
	if _selected != null:
		_selected.brain.enabled = pressed
