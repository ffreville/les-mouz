class_name ActionDefinition
extends Resource
## Une action proposée par un objet (ou entre personnages) : durée et effets.
## Les gains sont des totaux, répartis régulièrement sur toute la durée.

@export var id: StringName = &"action"
## Texte affiché dans les menus et la file d'actions.
@export var display_name: String = "Action"
## Durée en minutes de jeu.
@export var duration_minutes: float = 30.0
## Points gagnés sur la durée totale, par identifiant de besoin (ex. &"faim": 60).
@export var need_gains: Dictionary[StringName, float] = {}
## Variation de la relation (actions sociales uniquement), sur la durée totale.
@export var relationship_gain: float = 0.0
