class_name MouzJob
extends Node
## Le métier d'un Mouz et ses journées de travail.
##  - À l'heure de début, un jour travaillé, il laisse tomber ce qu'il faisait et sort par la rue
##    (bas du terrain) ; arrivé au bord, il disparaît (« au travail »).
##  - À l'heure de fin, il revient au même endroit avec son salaire, et sa journée a marqué
##    ses besoins (`need_changes` du métier).
## Pendant qu'il est au travail, il n'est ni cliquable ni disponible pour les autres.

## Le métier, l'état « au travail » ou l'heure ont changé (pour l'affichage).
signal changed

## Un Mouz ne part pas s'il reste moins que ça avant la fin (minutes de jeu).
const MIN_SHIFT_MINUTES := 30
## Au-delà de ce temps de marche vers la rue, on considère qu'il a pris le bus (minutes de jeu).
const MAX_WALK_MINUTES := 20

var definition: JobDefinition
## Vrai pendant les heures de travail, une fois sorti du terrain.
var away := false
## Dernier jour où il est parti travailler (pour ne partir qu'une fois par jour).
var worked_day := 0

var _character: Character
var _leaving: QueuedAction
var _leave_started := 0.0


func setup(character: Character) -> void:
	_character = character
	GameClock.minute_changed.connect(_on_minute_changed)
	EventBus.action_finished.connect(_on_action_ended)
	EventBus.action_cancelled.connect(_on_action_ended)


## Prend ce métier (il commence au prochain horaire).
func take(job: JobDefinition) -> void:
	definition = job
	worked_day = 0
	EventBus.notice.emit("%s est maintenant %s." % [_character.get_display_name(), job.display_name.to_lower()])
	changed.emit()


## Quitte son métier (et rentre tout de suite s'il était au travail, sans salaire).
func quit() -> void:
	if definition == null:
		return
	var old := definition
	definition = null
	if away:
		_return_home(false)
	EventBus.notice.emit("%s a quitté son poste de %s." % [_character.get_display_name(), old.display_name.to_lower()])
	changed.emit()


func is_leaving() -> bool:
	return _leaving != null


## « Commis de cuisine · 10 h – 18 h », « Au travail jusqu'à 18 h », « Sans emploi ».
func status_text() -> String:
	if definition == null:
		return "Sans emploi"
	if away:
		return "Au travail jusqu'à %d h" % definition.end_hour
	if _leaving != null:
		return "Part au travail"
	return "%s · %d h – %d h" % [definition.display_name, definition.start_hour, definition.end_hour]


func _on_minute_changed(day: int, hour: int, minute: int) -> void:
	if definition == null:
		return
	var now := hour * 60 + minute
	var start := definition.start_hour * 60
	var end := definition.end_hour * 60
	if away:
		if now >= end or now < start:
			_return_home(true)
		return
	if _leaving != null and GameClock.total_minutes - _leave_started > MAX_WALK_MINUTES:
		_character.queue.cancel(_leaving)
		return
	if _leaving != null or worked_day == day or not definition.works_on(JobBoard.weekday(day)):
		return
	if now >= start and now <= end - MIN_SHIFT_MINUTES:
		worked_day = day
		_leave()


## Laisse tout tomber et part vers la rue.
func _leave() -> void:
	for action in _character.queue.items.duplicate():
		_character.queue.cancel(action)
	_leaving = QueuedAction.move_to(exit_cell())
	_leave_started = GameClock.total_minutes
	_character.queue.enqueue(_leaving)
	changed.emit()


func _on_action_ended(character: Node, action: RefCounted) -> void:
	if character != _character:
		return
	# Annonces lues sur l'ordinateur jusqu'au bout : on les affiche.
	if action.definition != null and action.definition.id == &"chercher_emploi" \
			and action.state == QueuedAction.State.DONE and action.elapsed_minutes >= action.definition.duration_minutes:
		EventBus.job_board_requested.emit(_character, &"ordinateur")
	if action == _leaving:
		# Arrivé au bord du terrain (ou chemin impossible : il part quand même).
		_leaving = null
		_go_away()


func _go_away() -> void:
	for action in _character.queue.items.duplicate():
		_character.queue.cancel(action)
	away = true
	_character.visible = false
	if _character.is_selected:
		EventBus.notice.emit("%s part au travail." % _character.get_display_name())
	changed.emit()


## Rentre par la rue ; `paid` : la journée est payée et compte pour les besoins.
func _return_home(paid: bool) -> void:
	away = false
	_character.position = _character.world.navigation.cell_to_world(exit_cell())
	_character.visible = true
	if paid and definition != null:
		Wallet.receive(definition.salary)
		for need_id in definition.need_changes:
			if _character.needs.has_need(need_id):
				_character.needs.change(need_id, definition.need_changes[need_id])
		EventBus.salary_paid.emit(_character, definition.salary)
		EventBus.notice.emit("%s rentre du travail : +%s" % [_character.get_display_name(),
				Palette.format_mz(definition.salary)])
	changed.emit()


## Case de la rue par où l'on part et revient : bas du terrain, sous le point d'arrivée.
func exit_cell() -> Vector2i:
	var world := _character.world
	var spawn: Vector2i = world.lot.spawn_cells[0] if not world.lot.spawn_cells.is_empty() else Vector2i.ZERO
	return world.navigation.nearest_walkable(Vector2i(spawn.x, world.lot.size.y - 1))


func to_dict() -> Dictionary:
	return {"id": String(definition.id) if definition != null else "", "away": away, "worked_day": worked_day}


func restore(data: Dictionary) -> void:
	definition = JobBoard.find(StringName(data.get("id", "")))
	worked_day = int(data.get("worked_day", 0))
	away = bool(data.get("away", false)) and definition != null
	_character.visible = not away
	changed.emit()
