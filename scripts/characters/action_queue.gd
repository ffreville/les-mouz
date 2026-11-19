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
	EventBus.lot_changed.connect(_on_lot_changed)
	EventBus.object_displaced.connect(_on_object_displaced)


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
		var target := action.target_object
		if not target.can_use(_character) or target.action_problem(action.definition, _character.world) != "":
			return GridNavigation.NO_CELL
		return navigation.closest_reachable(target.get_spots(navigation), here)
	# Action sociale : l'invité reste sur place, l'initiateur va à côté du partenaire.
	if action.is_social_guest:
		return here
	var partner_cell := action.target_character.get_cell()
	if navigation.are_neighbors(here, partner_cell):
		return here
	return navigation.closest_reachable(navigation.cells_next_to(partner_cell), here)


## Un objet est revendu ou déplacé : on abandonne les actions qui le visent.
func _on_object_displaced(placed: Resource) -> void:
	for action in items.duplicate():
		if action.target_object != null and action.target_object.placed == placed:
			cancel(action)


## Le terrain a changé : on recalcule le trajet en cours (un mur a pu apparaître).
func _on_lot_changed() -> void:
	var action := current()
	if action != null and action.state == QueuedAction.State.MOVING:
		_character.mover.stop()
		action.state = QueuedAction.State.PENDING
		_begin(action)


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
			and not _character.world.navigation.are_neighbors(_character.get_cell(), action.target_character.get_cell()):
		action.approach_attempts += 1
		if action.approach_attempts > MAX_APPROACH_ATTEMPTS:
			cancel(action)
		else:
			action.state = QueuedAction.State.PENDING
			_begin(action)
		return
	_run(action)


## Tourne le personnage vers ce qu'il utilise (objet solide ou autre personnage).
func _face_target(action: QueuedAction) -> void:
	var target := Vector2.INF
	if action.target_object != null and action.target_object.definition.blocks_movement:
		var cs := float(_character.world.lot.cell_size)
		target = Rect2(Vector2(action.target_object.footprint.position) * cs,
				Vector2(action.target_object.footprint.size) * cs).get_center()
	elif action.target_character != null:
		target = action.target_character.position
	if target != Vector2.INF and target != _character.position:
		_character.mover.facing = (target - _character.position).normalized()


## Deuxième phase : l'action commence réellement.
func _run(action: QueuedAction) -> void:
	if action.target_object != null and not action.target_object.reserve(_character):
		cancel(action)
		return
	action.state = QueuedAction.State.RUNNING
	if action.target_object != null and action.definition.nearby_object_id != &"":
		action.powered_object = action.target_object.find_nearby(action.definition, _character.world)
		if action.powered_object != null:
			action.powered_object.power_on(_character)
	_face_target(action)
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
	if action.target_object != null:
		_apply_shared_gains(action, ratio)
	if action.elapsed_minutes >= definition.duration_minutes:
		_finish(action)


## Activité partagée : bonus quand d'autres Mouz utilisent le même objet en même temps.
## Chacun applique la moitié du gain de relation, qui est symétrique.
func _apply_shared_gains(action: QueuedAction, ratio: float) -> void:
	var definition := action.definition
	if definition.shared_need_gains.is_empty() and definition.shared_relationship_gain == 0.0:
		return
	var others := action.target_object.other_users(_character)
	if others.is_empty():
		return
	for need_id in definition.shared_need_gains:
		_character.needs.change(need_id, definition.shared_need_gains[need_id] * ratio)
	for other in others:
		_character.relationships.change_with(other, definition.shared_relationship_gain * ratio / 2.0)


func _finish(action: QueuedAction) -> void:
	if action.target_object != null:
		match action.definition.switch:
			ActionDefinition.Switch.TURN_ON:
				action.target_object.placed.switched_on = true
			ActionDefinition.Switch.TURN_OFF:
				action.target_object.placed.switched_on = false
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
	if action.powered_object != null:
		if is_instance_valid(action.powered_object):
			action.powered_object.power_off(_character)
		action.powered_object = null
