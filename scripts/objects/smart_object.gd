class_name SmartObject
extends Node2D
## Un objet posé dans la maison. Il se dessine, annonce ses actions
## et gère qui l'utilise (réservation).

## Les objets traversables (tapis) passent sous les autres.
const FLOOR_OBJECT_Z := -1

var definition: SmartObjectDefinition
## Cases occupées par l'objet.
var footprint: Rect2i
var _pixel_size: Vector2
var _users: Array[Node] = []


func setup(p_definition: SmartObjectDefinition, cell: Vector2i, cell_size: int) -> void:
	definition = p_definition
	footprint = Rect2i(cell, definition.size)
	name = definition.display_name
	position = Vector2(cell) * cell_size
	_pixel_size = Vector2(definition.size) * cell_size
	if not definition.blocks_movement:
		z_index = FLOOR_OBJECT_Z
	queue_redraw()


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
	if definition == null:
		return
	if definition.sprite != null:
		draw_texture_rect(definition.sprite, Rect2(Vector2.ZERO, _pixel_size), false)
		return
	# Graphisme provisoire si aucune image n'est fournie.
	var area := Rect2(Vector2.ONE * 3, _pixel_size - Vector2.ONE * 6)
	draw_rect(area, definition.color)
	draw_rect(area, Palette.CONTOUR, false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(0, _pixel_size.y / 2 + 4), definition.display_name,
			HORIZONTAL_ALIGNMENT_CENTER, _pixel_size.x, 11, Palette.ENCRE)
