class_name NeedsComponent
extends Node
## Valeurs des besoins d'un personnage : baisse avec le temps, gains, humeur.

## Un besoin de ce personnage a changé.
signal need_changed(need_id: StringName, value: float)
## L'humeur de ce personnage a changé.
signal mood_changed(mood: float)

const MIN_VALUE := 0.0
const MAX_VALUE := 100.0
## Vitesse de baisse des besoins pendant qu'un Mouz est au travail.
const AWAY_DECAY := 0.5

var definitions: Array[NeedDefinition] = []
var _values: Dictionary[StringName, float] = {}
var _character: Node


func setup(character: Node, need_definitions: Array[NeedDefinition]) -> void:
	_character = character
	definitions = need_definitions
	for definition in definitions:
		_values[definition.id] = definition.start_value
	GameClock.ticked.connect(_on_ticked)


## Remet des valeurs enregistrées (chargement d'une partie), sans signal de besoin critique.
func restore(values: Dictionary) -> void:
	for need_id in values:
		if _values.has(StringName(need_id)):
			_values[StringName(need_id)] = clampf(float(values[need_id]), MIN_VALUE, MAX_VALUE)
			need_changed.emit(StringName(need_id), _values[StringName(need_id)])
	_notify_mood()


## Valeurs actuelles de tous les besoins (pour la sauvegarde).
func snapshot() -> Dictionary:
	var values := {}
	for need_id in _values:
		values[String(need_id)] = _values[need_id]
	return values


func has_need(need_id: StringName) -> bool:
	return _values.has(need_id)


func get_value(need_id: StringName) -> float:
	return _values.get(need_id, MAX_VALUE)


func get_definition(need_id: StringName) -> NeedDefinition:
	for definition in definitions:
		if definition.id == need_id:
			return definition
	return null


## Urgence entre 0 (comblé) et 1 (vide).
func get_urgency(need_id: StringName) -> float:
	return 1.0 - get_value(need_id) / MAX_VALUE


## Humeur générale : moyenne des besoins pondérée par `mood_weight`.
func get_mood() -> float:
	var total := 0.0
	var weights := 0.0
	for definition in definitions:
		total += _values[definition.id] * definition.mood_weight
		weights += definition.mood_weight
	return total / weights if weights > 0.0 else MAX_VALUE


## Ajoute (ou retire si négatif) des points à un besoin.
func change(need_id: StringName, amount: float, notify_mood := true) -> void:
	if not _values.has(need_id):
		return
	var old_value := _values[need_id]
	var new_value := clampf(old_value + amount, MIN_VALUE, MAX_VALUE)
	if new_value == old_value:
		return
	_values[need_id] = new_value
	need_changed.emit(need_id, new_value)
	EventBus.need_changed.emit(_character, need_id, new_value)

	var threshold := get_definition(need_id).critical_threshold
	if old_value >= threshold and new_value < threshold:
		EventBus.need_critical.emit(_character, need_id, new_value)
	if notify_mood:
		_notify_mood()


func _on_ticked(game_minutes: float) -> void:
	# Au travail, on mange et on se repose sur place : les besoins baissent moitié moins vite
	# (le métier, lui, marque la journée par ses `need_changes` au retour).
	var factor := AWAY_DECAY if _character != null and _character.has_method("is_away") and _character.is_away() else 1.0
	for definition in definitions:
		change(definition.id, -definition.decay_per_hour * factor * game_minutes / 60.0, false)
	_notify_mood()


func _notify_mood() -> void:
	var mood := get_mood()
	mood_changed.emit(mood)
	EventBus.mood_changed.emit(_character, mood)
