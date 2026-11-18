class_name SmartObject
extends Node2D
## Un objet posé dans la maison. Il se dessine, annonce ses actions
## et gère qui l'utilise (réservation).

## Les objets traversables (tapis) passent sous les autres.
const FLOOR_OBJECT_Z := -1

## L'objet tel qu'il est posé sur le terrain (définition, case, rotation, prix payé).
var placed: PlacedObject
var definition: SmartObjectDefinition
## Cases occupées par l'objet.
var footprint: Rect2i
var _cell_size: float
var _users: Array[Node] = []


func setup(p_placed: PlacedObject, cell_size: int) -> void:
	placed = p_placed
	definition = placed.definition
	footprint = placed.footprint()
	_cell_size = cell_size
	name = definition.display_name
	position = Vector2(footprint.position) * cell_size
	if not definition.blocks_movement:
		z_index = FLOOR_OBJECT_Z
	queue_redraw()


## Dessine l'objet tourné de `rotation` quarts de tour, emprise posée à `origin`.
## Partagé avec l'aperçu de placement de l'éditeur.
static func draw_definition(canvas: CanvasItem, p_definition: SmartObjectDefinition, rotation: int,
		origin: Vector2, cell_size: float, modulate := Color.WHITE) -> void:
	var native := Vector2(p_definition.size) * cell_size
	var turned := Vector2(native.y, native.x) if rotation % 2 == 1 else native
	canvas.draw_set_transform(origin + turned / 2, rotation * PI / 2)
	var area := Rect2(-native / 2, native)
	if p_definition.sprite != null:
		canvas.draw_texture_rect(p_definition.sprite, area, false, modulate)
	else:
		# Graphisme provisoire si aucune image n'est fournie.
		canvas.draw_rect(area.grow(-3), p_definition.color * modulate)
		canvas.draw_rect(area.grow(-3), Palette.CONTOUR * modulate, false, 2.0)
	canvas.draw_set_transform_matrix(Transform2D.IDENTITY)


func get_display_name() -> String:
	return definition.display_name


func get_actions() -> Array[ActionDefinition]:
	return definition.actions


func has_actions() -> bool:
	return not definition.actions.is_empty()


func occupies(cell: Vector2i) -> bool:
	return footprint.has_point(cell)


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
	return true


func release(user: Node) -> void:
	_users.erase(user)


func _draw() -> void:
	if placed != null:
		draw_definition(self, definition, placed.rotation, Vector2.ZERO, _cell_size)
