class_name SelectionManager
extends Node
## Retient le personnage contrôlé par le joueur et prévient le reste du jeu quand il change.

var selected: Character


func select(character: Character) -> void:
	if character == selected:
		return
	if selected != null:
		selected.is_selected = false
	selected = character
	selected.is_selected = true
	EventBus.character_selected.emit(selected)
