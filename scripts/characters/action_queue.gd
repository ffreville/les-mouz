class_name ActionQueue
extends Node
## File d'actions d'un personnage : il exécute la première, puis passe à la suivante.
## Cycle d'une action : PENDING → MOVING (va sur place) → RUNNING (applique ses effets) → DONE.
##
## Actions sociales : l'initiateur rejoint son partenaire puis place une action
## « jumelle » en tête de la file du partenaire. Annuler l'une annule l'autre.

## La file a changé (ajout, retrait, début d'une action).
signal changed

## Nombre de fois où l'on recalcule le chemin vers un partenaire qui se déplace.
const MAX_APPROACH_ATTEMPTS := 6

var items: Array[QueuedAction] = []
var _character: Character


func setup(character: Character) -> void:
	_character = character
	_character.mover.arrived.connect(_on_arrived)
	GameClock.ticked.connect(_on_ticked)


func is_empty() -> bool:
	return items.is_empty()


func current() -> QueuedAction:
	return null if items.is_empty() else items[0]


## Ajoute une action en fin de file.
func enqueue(action: QueuedAction) -> void:
	# Un ordre du joueur remplace ce que l'autonomie avait décidé.
	if not action.is_autonomous:
		for other in items.duplicate():
			if other.is_autonomous:
				cancel(other)
	items.append(action)
	EventBus.action_queued.emit(_character, action)
	changed.emit()
	_start_next_if_idle()


## Place une action en tête de file et la démarre tout de suite.
## L'action en cours est remise en attente (ou annulée si elle venait de l'autonomie).
func push_front(action: QueuedAction) -> void:
	var interrupted := current()
	if interrupted != null and interrupted.state != QueuedAction.State.PENDING:
		_stop(interrupted)
		interrupted.state = QueuedAction.State.PENDING
	items.push_front(action)
	EventBus.action_queued.emit(_character, action)
	if interrupted != null and (interrupted.is_autonomous or interrupted.is_social()):
		cancel(interrupted)
	changed.emit()
	_start_next_if_idle()


## Retire une action de la file (et l'interrompt si elle est en cours).
func cancel(action: QueuedAction) -> void:
	if action not in items:
		return
	if action == current():
		_stop(action)
	items.erase(action)
	action.state = QueuedAction.State.DONE
	EventBus.action_cancelled.emit(_character, action)
	# L'action jumelle du partenaire s'arrête aussi.
	var partner := action.partner_action
	if partner != null and partner.state != QueuedAction.State.DONE:
		action.target_character.queue.cancel(partner)
	changed.emit()
	_start_next_if_idle()


func _start_next_if_idle() -> void:
	var action := current()
	if action != null and action.state == QueuedAction.State.PENDING:
		_begin(action)


## Première phase : rejoindre l'endroit où l'action se fait.
func _begin(action: QueuedAction) -> void:
	var destination := _destination_for(action)
	if destination == GridNavigation.NO_CELL:
		cancel(action)
		return
	if destination == _character.get_cell():
		_on_destination_reached(action)
		return
	if _character.mover.move_to_cell(destination):
		action.state = QueuedAction.State.MOVING
	else:
		cancel(action)


## Case où le personnage doit se rendre, ou NO_CELL si l'action est impossible.
func _destination_for(action: QueuedAction) -> Vector2i:
	var navigation := _character.world.navigation
	var here := _character.get_cell()
	if action.is_move_only():
		return action.target_cell
	if action.target_object != null:
		if not action.target_object.can_use(_character):
			return GridNavigation.NO_CELL
		var spots := navigation.cells_around(action.target_object.footprint)
		return navigation.closest_reachable(spots, here)
	# Action sociale : l'invité reste sur place, l'initiateur va à côté du partenaire.
	if action.is_social_guest:
		return here
	var partner_cell := action.target_character.get_cell()
	if _is_next_to(here, partner_cell):
		return here
	var spots := navigation.cells_around(Rect2i(partner_cell, Vector2i.ONE))
	return navigation.closest_reachable(spots, here)


func _on_arrived() -> void:
	var action := current()
	if action != null and action.state == QueuedAction.State.MOVING:
		_on_destination_reached(action)


func _on_destination_reached(action: QueuedAction) -> void:
	if action.is_move_only():
		_finish(action)
		return
	# Le partenaire a pu bouger pendant le trajet : on le rejoint à nouveau.
	if action.is_social() and not action.is_social_guest \
			and not _is_next_to(_character.get_cell(), action.target_character.get_cell()):
		action.approach_attempts += 1
		if action.approach_attempts > MAX_APPROACH_ATTEMPTS:
			cancel(action)
		else:
			action.state = QueuedAction.State.PENDING
			_begin(action)
		return
	_run(action)


## Deuxième phase : l'action commence réellement.
func _run(action: QueuedAction) -> void:
	if action.target_object != null and not action.target_object.reserve(_character):
		cancel(action)
		return
	action.state = QueuedAction.State.RUNNING
	EventBus.action_started.emit(_character, action)
	if action.is_social() and not action.is_social_guest:
		_invite_partner(action)
	changed.emit()


## Crée l'action jumelle chez le partenaire pour qu'il participe.
func _invite_partner(action: QueuedAction) -> void:
	var guest := QueuedAction.with_character(action.definition, _character)
	guest.is_social_guest = true
	guest.partner_action = action
	action.partner_action = guest
	action.target_character.queue.push_front(guest)


## Applique les effets de l'action en cours, au prorata du temps écoulé.
func _on_ticked(game_minutes: float) -> void:
	var action := current()
	if action == null or action.state != QueuedAction.State.RUNNING:
		return
	var definition := action.definition
	var step := minf(game_minutes, definition.duration_minutes - action.elapsed_minutes)
	action.elapsed_minutes += step
	var ratio := step / definition.duration_minutes if definition.duration_minutes > 0.0 else 1.0
	for need_id in definition.need_gains:
		_character.needs.change(need_id, definition.need_gains[need_id] * ratio)
	# La relation est symétrique : seul l'initiateur l'applique, pour ne pas la compter deux fois.
	if action.is_social() and not action.is_social_guest and definition.relationship_gain != 0.0:
		_character.relationships.change_with(action.target_character, definition.relationship_gain * ratio)
	if action.elapsed_minutes >= definition.duration_minutes:
		_finish(action)


func _finish(action: QueuedAction) -> void:
	_stop(action)
	items.erase(action)
	action.state = QueuedAction.State.DONE
	EventBus.action_finished.emit(_character, action)
	changed.emit()
	_start_next_if_idle()


## Arrête le déplacement et libère l'objet éventuellement réservé.
func _stop(action: QueuedAction) -> void:
	_character.mover.stop()
	if action.target_object != null:
		action.target_object.release(_character)


## Vrai si deux cases se touchent (y compris en diagonale) sans être confondues.
static func _is_next_to(a: Vector2i, b: Vector2i) -> bool:
	return a != b and absi(a.x - b.x) <= 1 and absi(a.y - b.y) <= 1
