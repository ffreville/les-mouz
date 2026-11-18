class_name QueuedAction
extends RefCounted
## Une entrée de la file d'actions d'un personnage.
## Trois sortes : simple déplacement, utilisation d'un objet, action avec un autre personnage.

enum State { PENDING, MOVING, RUNNING, DONE }

## Null pour un simple déplacement.
var definition: ActionDefinition
var target_object: SmartObject
var target_character: Character
var target_cell: Vector2i
## Vrai si l'action a été choisie par l'autonomie (un ordre du joueur la remplace).
var is_autonomous: bool = false
var state: State = State.PENDING
var elapsed_minutes: float = 0.0

## Pour une action sociale : l'action jumelle dans la file de l'autre personnage.
var partner_action: QueuedAction
## Vrai pour le personnage qui rejoint une action sociale (il ne se déplace pas).
var is_social_guest: bool = false
## Tentatives pour rejoindre un partenaire qui bouge.
var approach_attempts: int = 0
## Objet voisin que l'action fait fonctionner (la télé pour le canapé), pendant qu'elle dure.
var powered_object: SmartObject


static func move_to(cell: Vector2i) -> QueuedAction:
	var action := QueuedAction.new()
	action.target_cell = cell
	return action


static func use_object(p_definition: ActionDefinition, smart_object: SmartObject) -> QueuedAction:
	var action := QueuedAction.new()
	action.definition = p_definition
	action.target_object = smart_object
	return action


static func with_character(p_definition: ActionDefinition, partner: Character) -> QueuedAction:
	var action := QueuedAction.new()
	action.definition = p_definition
	action.target_character = partner
	return action


func is_move_only() -> bool:
	return definition == null


func is_social() -> bool:
	return target_character != null


## Texte affiché dans la file, par exemple « Manger (Frigo) ».
func get_label() -> String:
	if is_move_only():
		return "Aller ici"
	if target_object != null:
		return "%s (%s)" % [definition.display_name, target_object.get_display_name()]
	return "%s avec %s" % [definition.display_name, target_character.get_display_name()]


## Avancement entre 0 et 1.
func get_progress() -> float:
	if definition == null or definition.duration_minutes <= 0.0:
		return 0.0
	return clampf(elapsed_minutes / definition.duration_minutes, 0.0, 1.0)
