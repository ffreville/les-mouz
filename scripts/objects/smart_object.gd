class_name SmartObject
extends Node2D
## Un objet posé dans la maison. Il se dessine (dans sa collection, « en marche » ou non),
## annonce ses actions et gère qui l'utilise (réservation).

## Les objets traversables (tapis) passent sous les autres.
const FLOOR_OBJECT_Z := -1

## L'objet tel qu'il est posé sur le terrain (définition, case, rotation, style, prix payé).
var placed: PlacedObject
var definition: SmartObjectDefinition
## Cases occupées par l'objet.
var footprint: Rect2i
var _cell_size: float
var _users: Array[Node] = []
## Place occupée par chaque utilisateur (0, 1, 2…) : chacun garde la sienne jusqu'à ce qu'il parte.
var _seats: Dictionary[Node, int] = {}
## Personnages qui font fonctionner l'objet à distance (la télé pour le canapé).
var _powered_by: Array[Node] = []


func setup(p_placed: PlacedObject, cell_size: int) -> void:
	placed = p_placed
	definition = placed.definition
	footprint = placed.footprint()
	_cell_size = cell_size
	name = definition.display_name
	# Le nœud est posé au bas de l'emprise : c'est ce point qui fixe l'ordre d'affichage.
	position = Vector2(footprint.position.x, footprint.end.y) * cell_size
	z_index = FLOOR_OBJECT_Z if not definition.blocks_movement else 0
	queue_redraw()


## Dessine un objet tourné de `rotation` quarts de tour, emprise posée à `origin` (coin haut-gauche).
## En vue trois quarts, l'image monte au-dessus de l'emprise : son bas est le bas de l'emprise.
## Sans vues trois quarts, on dessine à plat l'image vue de dessus, tournée.
## Partagé avec l'aperçu de placement de l'éditeur.
static func draw_definition(canvas: CanvasItem, p_definition: SmartObjectDefinition, rotation: int,
		origin: Vector2, cell_size: float, modulate := Color.WHITE, collection: StringName = &"",
		active := false) -> void:
	var view := p_definition.get_view(collection, rotation, active)
	if not view.is_empty():
		var rect := view_rect(p_definition, rotation, origin, cell_size, view[0])
		if view[1]:
			# Vue `droite` = vue `gauche` retournée.
			canvas.draw_set_transform(Vector2(rect.position.x * 2 + rect.size.x, 0), 0.0, Vector2(-1, 1))
		canvas.draw_texture_rect(view[0], rect, false, modulate)
		canvas.draw_set_transform_matrix(Transform2D.IDENTITY)
		return
	var native := Vector2(p_definition.size) * cell_size
	var turned := Vector2(native.y, native.x) if rotation % 2 == 1 else native
	canvas.draw_set_transform(origin + turned / 2, rotation * PI / 2)
	var area := Rect2(-native / 2, native)
	var sprite := p_definition.get_sprite(collection, active)
	if sprite != null:
		canvas.draw_texture_rect(sprite, area, false, modulate)
	else:
		# Graphisme provisoire si aucune image n'est fournie.
		canvas.draw_rect(area.grow(-3), p_definition.color * modulate)
		canvas.draw_rect(area.grow(-3), Palette.CONTOUR * modulate, false, 2.0)
	canvas.draw_set_transform_matrix(Transform2D.IDENTITY)


## Rectangle de l'image trois quarts : même largeur que l'emprise, posée sur son bas.
static func view_rect(p_definition: SmartObjectDefinition, rotation: int, origin: Vector2,
		cell_size: float, texture: Texture2D) -> Rect2:
	var cells := Vector2(p_definition.size)
	var turned := Vector2(cells.y, cells.x) if rotation % 2 == 1 else cells
	var width := turned.x * cell_size
	var height := texture.get_height() * width / texture.get_width()
	return Rect2(origin.x, origin.y + turned.y * cell_size - height, width, height)


func get_display_name() -> String:
	return definition.display_name


## Actions de l'objet ; en panne, « Réparer » passe en premier.
func get_actions() -> Array[ActionDefinition]:
	if placed != null and placed.is_broken():
		var actions: Array[ActionDefinition] = [Upkeep.REPAIR_ACTION]
		actions.append_array(definition.actions)
		return actions
	return definition.actions


func has_actions() -> bool:
	return not get_actions().is_empty()


func occupies(cell: Vector2i) -> bool:
	return footprint.has_point(cell)


## Coin haut-gauche de l'emprise, dans le repère du nœud.
func _origin() -> Vector2:
	return Vector2(0, -footprint.size.y * _cell_size)


## Zone visible de l'objet à l'écran (monde), hauteur comprise.
func screen_rect() -> Rect2:
	var view := definition.get_view(placed.get_collection(), placed.rotation, is_active())
	var rect := Rect2(_origin(), Vector2(footprint.size) * _cell_size)
	if not view.is_empty():
		rect = view_rect(definition, placed.rotation, _origin(), _cell_size, view[0])
	return Rect2(rect.position + position, rect.size)


## Rectangle du sprite trois quarts dans le repère du nœud (vide sans vue trois quarts).
func sprite_rect_local() -> Rect2:
	var view := definition.get_view(placed.get_collection(), placed.rotation, is_active())
	if view.is_empty():
		return Rect2()
	return view_rect(definition, placed.rotation, _origin(), _cell_size, view[0])


## Place que prend ce Mouz sur l'objet, {} s'il n'y en a pas.
func place_for(character: Node) -> Dictionary:
	return SeatPlaces.find(definition.id, placed.get_collection(),
			SmartObjectDefinition.VIEWS[posmod(placed.rotation, 4)], _seats.get(character, -1))


## Vrai si un clic à cette position (monde) touche l'image de l'objet.
func contains_point(world_position: Vector2) -> bool:
	return screen_rect().has_point(world_position)


## « En marche » : utilisé, alimenté à distance ou allumé.
func is_active() -> bool:
	if Bills.cut and definition.id in Bills.ELECTRIC or placed.is_broken():
		return false
	return not _users.is_empty() or not _powered_by.is_empty() or placed.switched_on


## Cases où se tenir pour s'en servir : autour d'un meuble, dessus pour un tapis.
func get_spots(navigation: GridNavigation) -> Array[Vector2i]:
	if definition.blocks_movement:
		return navigation.cells_around(footprint)
	var cells: Array[Vector2i] = []
	for y in range(footprint.position.y, footprint.end.y):
		for x in range(footprint.position.x, footprint.end.x):
			if navigation.is_walkable(Vector2i(x, y)):
				cells.append(Vector2i(x, y))
	return cells


## Raison pour laquelle l'action n'est pas possible ici ("" si elle l'est).
func action_problem(action: ActionDefinition, world: World) -> String:
	if action == Upkeep.REPAIR_ACTION:
		return "réparateur appelé" if placed.repair_at > 0.0 else ""
	if placed.is_broken():
		return "en panne"
	var power := world.bills.problem_for(definition.id)
	if power == "" and action.nearby_object_id != &"":
		power = world.bills.problem_for(action.nearby_object_id)
	if power != "":
		return power
	if action.cost > 0 and not Wallet.can_afford(action.cost):
		return "pas assez d'argent"
	match action.switch:
		ActionDefinition.Switch.TURN_ON:
			if placed.switched_on:
				return "déjà allumé"
		ActionDefinition.Switch.TURN_OFF:
			if not placed.switched_on:
				return "déjà éteint"
	if action.nearby_object_id != &"" and find_nearby(action, world) == null:
		var needed := Catalog.find(Catalog.OBJECTS, action.nearby_object_id)
		return "pas de %s à côté" % (needed.display_name if needed != null else String(action.nearby_object_id))
	return ""


## L'objet voisin requis par l'action (la télé la plus proche du canapé), ou null.
func find_nearby(action: ActionDefinition, world: World) -> SmartObject:
	var best: SmartObject = null
	var best_distance := action.nearby_radius + 1
	var center := footprint.get_center()
	for other in world.smart_objects:
		if other == self or other.definition.id != action.nearby_object_id:
			continue
		var d := other.footprint.get_center() - center
		var distance := maxi(absi(d.x), absi(d.y))
		if distance < best_distance:
			best_distance = distance
			best = other
	return best


## Autres personnages en train d'utiliser l'objet.
func other_users(user: Node) -> Array[Node]:
	return _users.filter(func(other: Node) -> bool: return other != user)


## Vrai si `user` peut utiliser l'objet maintenant.
func can_use(user: Node) -> bool:
	return user in _users or _users.size() < definition.capacity


func is_used_by_other(user: Node) -> bool:
	return not can_use(user)


## Réserve l'objet pour `user`. Renvoie false s'il est déjà plein.
func reserve(user: Node) -> bool:
	if not can_use(user):
		return false
	if user not in _users:
		_users.append(user)
		var seat := 0
		while seat in _seats.values():
			seat += 1
		_seats[user] = seat
		queue_redraw()
	return true


func release(user: Node) -> void:
	_users.erase(user)
	_seats.erase(user)
	queue_redraw()


## L'objet fonctionne pour `user` qui s'en sert à distance (canapé → télé).
func power_on(user: Node) -> void:
	if user not in _powered_by:
		_powered_by.append(user)
		queue_redraw()


func power_off(user: Node) -> void:
	_powered_by.erase(user)
	queue_redraw()


func _draw() -> void:
	if placed != null:
		draw_definition(self, definition, placed.rotation, _origin(), _cell_size, Color.WHITE,
				placed.get_collection(), is_active())
		if placed.is_broken():
			_draw_broken_mark()


## Signe « en panne » au-dessus de l'objet : un panneau rouge avec un point d'exclamation.
func _draw_broken_mark() -> void:
	var rect := sprite_rect_local()
	if rect.size == Vector2.ZERO:
		rect = Rect2(_origin(), Vector2(footprint.size) * _cell_size)
	var center := Vector2(rect.get_center().x, rect.position.y - 6)
	draw_circle(center, 8.0, Palette.CRITIQUE)
	draw_circle(center, 8.0, Palette.PAPIER, false, 2.0, true)
	draw_rect(Rect2(center.x - 1.2, center.y - 5, 2.4, 6), Palette.PAPIER)
	draw_circle(center + Vector2(0, 3.5), 1.4, Palette.PAPIER)
