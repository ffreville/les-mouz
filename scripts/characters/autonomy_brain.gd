class_name AutonomyBrain
extends Node
## Autonomie : quand la file est vide, choisit seul l'action la plus utile.
## Score = Σ (gain utile sur le besoin × urgence du besoin) − distance × pénalité.

signal enabled_changed(enabled: bool)

@export var settings: AutonomySettings

var enabled: bool = true:
	set(value):
		enabled = value
		enabled_changed.emit(enabled)

var _character: Character
var _cooldown_minutes: float = 0.0


func setup(character: Character, start_enabled: bool) -> void:
	_character = character
	enabled = start_enabled
	GameClock.ticked.connect(_on_ticked)


func _on_ticked(game_minutes: float) -> void:
	if not enabled or not _character.queue.is_empty():
		return
	_cooldown_minutes -= game_minutes
	if _cooldown_minutes > 0.0:
		return
	_cooldown_minutes = settings.think_interval_minutes
	var choice := choose_action()
	if choice != null:
		choice.is_autonomous = true
		_character.queue.enqueue(choice)


## Meilleure action possible maintenant, ou null si rien ne vaut le coup.
func choose_action() -> QueuedAction:
	var best: QueuedAction = null
	var best_score: float = settings.min_score
	for candidate in _list_candidates():
		var score: float = score_gains(candidate.definition) \
				- candidate.distance * settings.distance_penalty_per_cell
		if score > best_score:
			best_score = score
			best = candidate.action
	return best


## Partie « besoins » du score : on ne compte que ce qui manque vraiment.
func score_gains(definition: ActionDefinition) -> float:
	var needs := _character.needs
	var score := 0.0
	for need_id in definition.need_gains:
		if not needs.has_need(need_id):
			continue
		var useful_gain := minf(definition.need_gains[need_id], NeedsComponent.MAX_VALUE - needs.get_value(need_id))
		score += useful_gain * pow(needs.get_urgency(need_id), settings.urgency_exponent)
	return score


## Toutes les actions envisageables, avec la distance pour les faire.
## Chaque entrée : { "action": QueuedAction, "definition": ActionDefinition, "distance": float }.
func _list_candidates() -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	var navigation := _character.world.navigation
	var here := _character.get_cell()
	for smart_object in _character.world.smart_objects:
		if smart_object.get_actions().is_empty() or smart_object.is_used_by_other(_character):
			continue
		var spot := navigation.closest_reachable(navigation.cells_around(smart_object.footprint), here)
		if spot == GridNavigation.NO_CELL:
			continue
		var distance := navigation.path_length(here, spot)
		for definition in smart_object.get_actions():
			candidates.append({
				"action": QueuedAction.use_object(definition, smart_object),
				"definition": definition,
				"distance": distance,
			})
	return candidates
