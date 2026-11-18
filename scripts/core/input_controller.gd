class_name InputController
extends Node2D
## Traduit les clics dans le monde en ordres pour le personnage sélectionné.
## Les clics sur l'interface sont absorbés avant d'arriver ici.
##  - clic sur un autre personnage : menu (actions sociales, prendre le contrôle) ;
##  - clic sur un objet : menu de ses actions ;
##  - clic sur le sol : « Aller ici ».

@onready var world: World = get_parent()


func _unhandled_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	get_viewport().set_input_as_handled()
	var position_in_world := get_global_mouse_position()
	var selected := world.selection.selected

	var character := world.get_character_at(position_in_world)
	if character != null:
		if selected == null or character == selected:
			world.selection.select(character)
		else:
			_open_character_menu(selected, character, click.position)
		return
	if selected == null:
		return

	var cell := world.navigation.world_to_cell(position_in_world)
	var smart_object := world.get_object_at_cell(cell)
	if smart_object != null:
		_open_object_menu(selected, smart_object, click.position)
	elif world.navigation.is_walkable(cell):
		selected.queue.enqueue(QueuedAction.move_to(cell))


func _open_object_menu(actor: Character, smart_object: SmartObject, screen_position: Vector2) -> void:
	var options: Array = []
	for action in smart_object.get_actions():
		options.append({
			"label": action.display_name,
			"callback": func() -> void:
				actor.queue.enqueue(QueuedAction.use_object(action, smart_object)),
		})
	EventBus.context_menu_requested.emit(smart_object.get_display_name(), options, screen_position)


func _open_character_menu(actor: Character, other: Character, screen_position: Vector2) -> void:
	var options: Array = []
	for action in world.social_actions:
		options.append({
			"label": action.display_name,
			"callback": func() -> void:
				actor.queue.enqueue(QueuedAction.with_character(action, other)),
		})
	options.append({
		"label": "Contrôler %s" % other.get_display_name(),
		"callback": world.selection.select.bind(other),
	})
	EventBus.context_menu_requested.emit(other.get_display_name(), options, screen_position)
