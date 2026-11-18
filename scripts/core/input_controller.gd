class_name InputController
extends Node2D
## Traduit les clics dans le monde en ordres pour le personnage sélectionné.
## Les clics sur l'interface sont absorbés avant d'arriver ici.

@onready var world: World = get_parent()


func _unhandled_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	get_viewport().set_input_as_handled()
	var position_in_world := get_global_mouse_position()

	var character := world.get_character_at(position_in_world)
	if character != null:
		world.selection.select(character)
		return

	var cell := world.navigation.world_to_cell(position_in_world)
	var selected := world.selection.selected
	if selected != null and world.navigation.is_walkable(cell):
		selected.mover.move_to_cell(cell)
