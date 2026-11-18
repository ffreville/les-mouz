class_name ActionQueue
extends Node
## File d'actions d'un personnage : il exécute la première, puis passe à la suivante.
## Cycle d'une action : PENDING → MOVING (va sur place) → RUNNING (applique ses effets) → DONE.

## La file a changé (ajout, retrait, début d'une action).
signal changed

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


## Retire une action de la file (et l'interrompt si elle est en cours).
func cancel(action: QueuedAction) -> void:
	if action not in items:
		return
	if action == current():
		_stop(action)
	items.erase(action)
	action.state = QueuedAction.State.DONE
	EventBus.action_cancelled.emit(_character, action)
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
	if action.is_move_only():
		return action.target_cell
	if action.target_object != null:
		if not action.target_object.can_use(_character):
			return GridNavigation.NO_CELL
		var spots := navigation.cells_around(action.target_object.footprint)
		return navigation.closest_reachable(spots, _character.get_cell())
	return GridNavigation.NO_CELL


func _on_arrived() -> void:
	var action := current()
	if action != null and action.state == QueuedAction.State.MOVING:
		_on_destination_reached(action)


func _on_destination_reached(action: QueuedAction) -> void:
	if action.is_move_only():
		_finish(action)
	else:
		_run(action)


## Deuxième phase : l'action commence réellement.
func _run(action: QueuedAction) -> void:
	if action.target_object != null and not action.target_object.reserve(_character):
		cancel(action)
		return
	action.state = QueuedAction.State.RUNNING
	EventBus.action_started.emit(_character, action)
	changed.emit()


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
