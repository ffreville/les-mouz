class_name InputController
extends Node2D
## Traduit les clics dans le monde en ordres pour le personnage sélectionné.
## Les clics sur l'interface sont absorbés avant d'arriver ici.
##  - clic sur le personnage sélectionné : son téléphone (petites annonces, démission) ;
##  - clic sur un autre personnage : menu (actions sociales, prendre le contrôle) ;
##  - clic sur un objet : menu de ses actions ;
##  - clic sur le sol : « Aller ici ».

@onready var world: World = get_parent()


func _unhandled_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	if not GameMode.is_live():
		return
	get_viewport().set_input_as_handled()
	var position_in_world := get_global_mouse_position()
	var selected := world.selection.selected

	var character := world.get_character_at(position_in_world)
	if character != null:
		if selected == null:
			world.selection.select(character)
		elif character == selected:
			_open_phone_menu(character, click.position)
		else:
			_open_character_menu(selected, character, click.position)
		return
	if selected == null:
		return
	if selected.is_busy_with_job():
		EventBus.notice.emit("%s : %s" % [selected.get_display_name(), selected.job.status_text().to_lower()])
		return

	var cell := world.navigation.world_to_cell(position_in_world)
	var smart_object := world.get_object_at_point(position_in_world)
	if smart_object != null:
		if smart_object.has_actions():
			_open_object_menu(selected, smart_object, click.position)
	elif world.navigation.is_walkable(cell):
		selected.queue.enqueue(QueuedAction.move_to(cell))


func _open_object_menu(actor: Character, smart_object: SmartObject, screen_position: Vector2) -> void:
	var options: Array = []
	for action in smart_object.get_actions():
		var problem := smart_object.action_problem(action, world)
		# Allumer / Éteindre : on ne montre que celui qui a un sens.
		if action.switch != ActionDefinition.Switch.NONE and problem != "":
			continue
		var label := action.display_name
		if problem != "":
			label += " (%s)" % problem
		elif action.cost > 0:
			label += " · −%s" % Palette.format_mz(action.cost)
		elif action.earns():
			label += " · %s" % Palette.format_mz(action.earning_for(actor.skills.level(action.skill)))
		options.append({
			"label": label,
			"icon": action.icon,
			"disabled": problem != "",
			"callback": func() -> void:
				actor.queue.enqueue(QueuedAction.use_object(action, smart_object)),
		})
	EventBus.context_menu_requested.emit(smart_object.get_display_name(), options, screen_position)


## Le téléphone du Mouz : petites annonces, et démission s'il a un métier.
func _open_phone_menu(actor: Character, screen_position: Vector2) -> void:
	if actor.is_busy_with_job():
		EventBus.notice.emit("%s : %s" % [actor.get_display_name(), actor.job.status_text().to_lower()])
		return
	var options: Array = [{
		"label": "Petites annonces (téléphone)",
		"icon": load("res://assets/icons/ink/surfer.svg"),
		"callback": func() -> void: EventBus.job_board_requested.emit(actor, &"telephone"),
	}]
	if actor.job.definition != null:
		options.append({
			"label": "Démissionner (%s)" % actor.job.definition.display_name,
			"icon": load("res://assets/icons/ink/quitter.svg"),
			"callback": actor.job.quit,
		})
	EventBus.context_menu_requested.emit(actor.get_display_name(), options, screen_position)


func _open_character_menu(actor: Character, other: Character, screen_position: Vector2) -> void:
	var options: Array = []
	for action in world.social_actions:
		options.append({
			"label": action.display_name,
			"icon": action.icon,
			"callback": func() -> void:
				actor.queue.enqueue(QueuedAction.with_character(action, other)),
		})
	options.append({
		"label": "Contrôler %s" % other.get_display_name(),
		"callback": world.selection.select.bind(other),
	})
	EventBus.context_menu_requested.emit(other.get_display_name(), options, screen_position)
