class_name Relationships
extends Node
## Relations d'un personnage avec les autres, de -100 (ennemis) à 100 (meilleurs amis).
## Les relations sont symétriques : modifier A→B modifie aussi B→A.

## La relation avec `other` a changé.
signal changed(other: Node, value: float)

const MIN_VALUE := -100.0
const MAX_VALUE := 100.0

var _values: Dictionary[Node, float] = {}
var _character: Node


func setup(character: Node) -> void:
	_character = character


func get_value(other: Node) -> float:
	return _values.get(other, 0.0)


## Ajoute `amount` à la relation entre ce personnage et `other` (des deux côtés).
func change_with(other: Character, amount: float) -> void:
	var old_value := get_value(other)
	var new_value := clampf(old_value + amount, MIN_VALUE, MAX_VALUE)
	if new_value == old_value:
		return
	_store(other, new_value)
	other.relationships._store(_character, new_value)
	EventBus.relationship_changed.emit(_character, other, new_value, new_value - old_value)


func _store(other: Node, value: float) -> void:
	_values[other] = value
	changed.emit(other, value)
