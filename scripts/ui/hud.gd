class_name Hud
extends CanvasLayer
## Interface principale : relaie le personnage sélectionné aux différents panneaux.

@onready var character_name: Label = %CharacterName
@onready var needs_panel: NeedsPanel = %NeedsPanel


func _ready() -> void:
	EventBus.character_selected.connect(_on_character_selected)


func _on_character_selected(character: Node) -> void:
	character_name.text = character.get_display_name()
	needs_panel.set_character(character)
